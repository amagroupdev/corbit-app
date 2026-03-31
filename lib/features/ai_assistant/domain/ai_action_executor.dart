import 'dart:async';

import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/features/ai_assistant/data/models/ai_action_model.dart';
import 'package:orbit_app/features/groups/data/repositories/groups_repository.dart';
import 'package:orbit_app/routing/app_router.dart';
import 'package:orbit_app/shared/widgets/ai_completion_overlay.dart';

/// Executes AI actions autonomously (navigation, group creation, etc.)
///
/// Flow: close AI chat → navigate slowly → perform action → show completion.
class AiActionExecutor {
  AiActionExecutor(this._ref);
  final Ref _ref;

  /// Execute an action. Returns a status message for the AI to display.
  Future<String> execute(AiActionModel action) async {
    if (!action.isAllowed) return 'Action not allowed';

    switch (action.type) {
      case 'navigate':
        return _executeNavigate(action);
      case 'create_group':
        return _executeCreateGroup(action);
      case 'create_group_with_contacts':
        return _executeCreateGroupWithContacts(action);
      default:
        return 'Unknown action type';
    }
  }

  void _showCompletion(String message) {
    _ref.read(aiCompletionMessageProvider.notifier).state = message;
  }

  Future<String> _executeNavigate(AiActionModel action) async {
    final route = action.route;
    if (route == null || route.isEmpty) return 'No route specified';

    final router = _ref.read(appRouterProvider);

    // Step 1: Close AI chat → go home
    router.go('/');
    await Future.delayed(const Duration(milliseconds: 600));

    // Step 2: Navigate to target
    router.go(route);
    await Future.delayed(const Duration(milliseconds: 400));

    // Step 3: Show notification
    _showCompletion('وصلنا! الصفحة المطلوبة قدامك الحين');

    return 'Navigated to $route';
  }

  Future<String> _executeCreateGroup(AiActionModel action) async {
    final name = action.name;
    if (name == null || name.isEmpty) return 'No group name specified';

    final router = _ref.read(appRouterProvider);

    try {
      // Step 1: Close AI chat → go home
      router.go('/');
      await Future.delayed(const Duration(milliseconds: 600));

      // Step 2: Go to groups page
      router.go('/groups');
      await Future.delayed(const Duration(milliseconds: 800));

      // Step 3: Create the group
      final repo = _ref.read(groupsRepositoryProvider);
      final group = await repo.createGroup(name: name);
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 4: Navigate to the new group
      router.push('/groups/${group.id}');
      await Future.delayed(const Duration(milliseconds: 400));

      // Step 5: Show completion
      _showCompletion('تم إنشاء مجموعة "$name" بنجاح!');

      return 'Created group "$name"';
    } catch (e) {
      _showCompletion('ما قدرت أسوي المجموعة، حاول مرة ثانية');
      return 'Failed: $e';
    }
  }

  Future<String> _executeCreateGroupWithContacts(AiActionModel action) async {
    final name = action.name;
    if (name == null || name.isEmpty) return 'No group name specified';

    final router = _ref.read(appRouterProvider);

    try {
      // Step 1: Close AI chat → go home
      router.go('/');
      await Future.delayed(const Duration(milliseconds: 600));

      // Step 2: Go to groups
      router.go('/groups');
      await Future.delayed(const Duration(milliseconds: 800));

      // Step 3: Create group
      final repo = _ref.read(groupsRepositoryProvider);
      final group = await repo.createGroup(name: name);
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 4: Navigate to group
      router.push('/groups/${group.id}');
      await Future.delayed(const Duration(milliseconds: 600));

      // Step 5: Add contacts
      if (action.addDeviceContacts) {
        final hasPermission =
            await FlutterContacts.requestPermission(readonly: true);
        if (hasPermission) {
          final contacts =
              await FlutterContacts.getContacts(withProperties: true);
          final saudiRegex = RegExp(r'^(?:\+?966|0)?5[0-9]{8}$');

          int added = 0;
          for (final contact in contacts) {
            for (final phone in contact.phones) {
              final cleaned =
                  phone.number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
              if (saudiRegex.hasMatch(cleaned)) {
                String formatted = cleaned;
                if (formatted.startsWith('05')) {
                  formatted = '966${formatted.substring(1)}';
                } else if (formatted.startsWith('5')) {
                  formatted = '966$formatted';
                } else if (formatted.startsWith('+966')) {
                  formatted = formatted.substring(1);
                }
                try {
                  await repo.createNumber(
                    groupId: group.id,
                    name: contact.displayName,
                    number: formatted,
                  );
                  added++;
                } catch (_) {}
              }
            }
          }

          _showCompletion(
              'تم إنشاء مجموعة "$name" وإضافة $added جهة اتصال!');
        } else {
          _showCompletion(
              'تم إنشاء "$name" لكن ما قدرت أوصل لجهات الاتصال — تحتاج تعطيني الصلاحية');
        }
      }

      return 'Created group with contacts';
    } catch (e) {
      _showCompletion('ما قدرت أكمل العملية، حاول مرة ثانية');
      return 'Failed: $e';
    }
  }
}

final aiActionExecutorProvider = Provider<AiActionExecutor>((ref) {
  return AiActionExecutor(ref);
});
