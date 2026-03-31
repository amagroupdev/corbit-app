import 'dart:async';

import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/features/ai_assistant/data/models/ai_action_model.dart';
import 'package:orbit_app/features/groups/data/repositories/groups_repository.dart';
import 'package:orbit_app/features/templates/data/repositories/templates_repository.dart';
import 'package:orbit_app/routing/app_router.dart';
import 'package:orbit_app/shared/widgets/ai_completion_overlay.dart';
import 'package:orbit_app/shared/widgets/ai_working_overlay.dart';

/// Executes AI actions autonomously (navigation, group creation, etc.)
///
/// Flow: show working overlay → close AI chat → navigate → perform action
/// → hide overlay → show completion popup.
class AiActionExecutor {
  AiActionExecutor(this._ref);
  final Ref _ref;

  /// Execute an action. Returns a status message for the AI to display.
  Future<String> execute(AiActionModel action) async {
    if (!action.isAllowed) return 'Action not allowed';

    // Reset cancel flag
    _ref.read(aiCancelRequestedProvider.notifier).state = false;

    switch (action.type) {
      case 'navigate':
        return _executeNavigate(action);
      case 'create_group':
        return _executeCreateGroup(action);
      case 'create_group_with_contacts':
        return _executeCreateGroupWithContacts(action);
      case 'create_template':
        return _executeCreateTemplate(action);
      default:
        return 'Unknown action type';
    }
  }

  bool get _isCancelled => _ref.read(aiCancelRequestedProvider);

  void _startWorking(String message) {
    _ref.read(aiWorkingMessageProvider.notifier).state = message;
    _ref.read(aiWorkingProvider.notifier).state = true;
  }

  void _updateWorkingMessage(String message) {
    _ref.read(aiWorkingMessageProvider.notifier).state = message;
  }

  void _stopWorking() {
    _ref.read(aiWorkingProvider.notifier).state = false;
    _ref.read(aiWorkingMessageProvider.notifier).state = '';
    _ref.read(aiCancelRequestedProvider.notifier).state = false;
  }

  void _showSuccess(String message) {
    _stopWorking();
    _ref.read(aiCompletionMessageProvider.notifier).state =
        AiCompletionData(message: message, isSuccess: true);
  }

  void _showError(String message) {
    _stopWorking();
    _ref.read(aiCompletionMessageProvider.notifier).state =
        AiCompletionData(message: message, isSuccess: false);
  }

  Future<String> _executeNavigate(AiActionModel action) async {
    final route = action.route;
    if (route == null || route.isEmpty) return 'No route specified';

    _startWorking('جاري التنقل للصفحة المطلوبة...');

    final router = _ref.read(appRouterProvider);

    // Use go('/') first then push the target so back button works
    router.go('/');
    await Future.delayed(const Duration(milliseconds: 600));

    if (_isCancelled) { _stopWorking(); return 'Cancelled'; }

    router.push(route);
    await Future.delayed(const Duration(milliseconds: 400));

    _showSuccess('وصلنا! الصفحة المطلوبة قدامك الحين');

    return 'Navigated to $route';
  }

  Future<String> _executeCreateGroup(AiActionModel action) async {
    final name = action.name;
    if (name == null || name.isEmpty) return 'No group name specified';

    _startWorking('جاري إنشاء مجموعة "$name"...');

    final router = _ref.read(appRouterProvider);

    try {
      router.go('/');
      await Future.delayed(const Duration(milliseconds: 600));

      if (_isCancelled) { _stopWorking(); return 'Cancelled'; }

      _updateWorkingMessage('جاري فتح صفحة المجموعات...');
      router.go('/groups');
      await Future.delayed(const Duration(milliseconds: 800));

      if (_isCancelled) { _stopWorking(); return 'Cancelled'; }

      _updateWorkingMessage('جاري إنشاء المجموعة...');
      final repo = _ref.read(groupsRepositoryProvider);
      final group = await repo.createGroup(name: name);
      await Future.delayed(const Duration(milliseconds: 500));

      router.push('/groups/${group.id}');
      await Future.delayed(const Duration(milliseconds: 400));

      _showSuccess('تم إنشاء مجموعة "$name" بنجاح!');

      return 'Created group "$name"';
    } catch (e) {
      _showError('ما قدرت أسوي المجموعة "$name" — تأكد إنك مسجل دخول وحاول مرة ثانية');
      return 'Failed: $e';
    }
  }

  Future<String> _executeCreateGroupWithContacts(AiActionModel action) async {
    final name = action.name;
    if (name == null || name.isEmpty) return 'No group name specified';

    _startWorking('جاري إنشاء مجموعة "$name" مع جهات الاتصال...');

    final router = _ref.read(appRouterProvider);

    try {
      router.go('/');
      await Future.delayed(const Duration(milliseconds: 600));

      if (_isCancelled) { _stopWorking(); return 'Cancelled'; }

      _updateWorkingMessage('جاري فتح صفحة المجموعات...');
      router.go('/groups');
      await Future.delayed(const Duration(milliseconds: 800));

      if (_isCancelled) { _stopWorking(); return 'Cancelled'; }

      _updateWorkingMessage('جاري إنشاء المجموعة...');
      final repo = _ref.read(groupsRepositoryProvider);
      final group = await repo.createGroup(name: name);
      await Future.delayed(const Duration(milliseconds: 500));

      if (_isCancelled) { _stopWorking(); return 'Cancelled'; }

      router.push('/groups/${group.id}');
      await Future.delayed(const Duration(milliseconds: 600));

      if (action.addDeviceContacts) {
        _updateWorkingMessage('جاري طلب صلاحية جهات الاتصال...');
        final hasPermission =
            await FlutterContacts.requestPermission(readonly: true);
        if (hasPermission) {
          _updateWorkingMessage('جاري قراءة جهات الاتصال...');
          final contacts =
              await FlutterContacts.getContacts(withProperties: true);
          final saudiRegex = RegExp(r'^(?:\+?966|0)?5[0-9]{8}$');

          int added = 0;
          int total = 0;
          // Count total Saudi numbers first
          for (final contact in contacts) {
            for (final phone in contact.phones) {
              final cleaned =
                  phone.number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
              if (saudiRegex.hasMatch(cleaned)) total++;
            }
          }

          for (final contact in contacts) {
            if (_isCancelled) {
              _showSuccess(
                  'تم إيقاف المساعد — أضاف $added جهة اتصال من أصل $total قبل الإيقاف');
              return 'Cancelled after adding $added contacts';
            }

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
                  _updateWorkingMessage(
                      'جاري إضافة جهات الاتصال... ($added/$total)');
                } catch (_) {}
              }
            }
          }

          _showSuccess(
              'تم إنشاء مجموعة "$name" وإضافة $added جهة اتصال!');
        } else {
          _showError(
              'تم إنشاء "$name" لكن ما قدرت أوصل لجهات الاتصال — تحتاج تعطيني الصلاحية');
        }
      }

      return 'Created group with contacts';
    } catch (e) {
      _showError('ما قدرت أكمل العملية — تأكد إنك مسجل دخول وحاول مرة ثانية');
      return 'Failed: $e';
    }
  }

  Future<String> _executeCreateTemplate(AiActionModel action) async {
    final name = action.name;
    final content = action.content;
    if (name == null || name.isEmpty) return 'No template name specified';
    if (content == null || content.isEmpty) return 'No template content specified';

    _startWorking('جاري إنشاء قالب "$name"...');

    final router = _ref.read(appRouterProvider);

    try {
      router.go('/');
      await Future.delayed(const Duration(milliseconds: 600));

      if (_isCancelled) { _stopWorking(); return 'Cancelled'; }

      _updateWorkingMessage('جاري فتح صفحة القوالب...');
      router.push('/templates');
      await Future.delayed(const Duration(milliseconds: 800));

      if (_isCancelled) { _stopWorking(); return 'Cancelled'; }

      _updateWorkingMessage('جاري إنشاء القالب...');
      final repo = _ref.read(templatesRepositoryProvider);
      await repo.createTemplate(name: name, body: content);
      await Future.delayed(const Duration(milliseconds: 500));

      _showSuccess('تم إنشاء قالب "$name" بنجاح!');

      return 'Created template "$name"';
    } catch (e) {
      _showError('ما قدرت أسوي القالب "$name" — تأكد إنك مسجل دخول وحاول مرة ثانية');
      return 'Failed: $e';
    }
  }
}

final aiActionExecutorProvider = Provider<AiActionExecutor>((ref) {
  return AiActionExecutor(ref);
});
