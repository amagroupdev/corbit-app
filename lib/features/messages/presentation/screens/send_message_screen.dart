import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/groups/data/models/group_model.dart';
import 'package:orbit_app/features/groups/data/models/number_model.dart';
import 'package:orbit_app/features/messages/data/models/message_model.dart';
import 'package:orbit_app/features/messages/presentation/controllers/messages_controller.dart';
import 'package:orbit_app/features/messages/presentation/widgets/message_composer.dart';
import 'package:orbit_app/features/messages/presentation/widgets/recipient_input.dart';
import 'package:orbit_app/features/messages/presentation/widgets/schedule_picker.dart';
import 'package:orbit_app/features/messages/presentation/widgets/template_picker_sheet.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';

/// Screen for composing and sending an SMS message.
///
/// Supports sending to manual phone numbers or to groups (whole groups
/// or specific numbers picked from groups).
class SendMessageScreen extends ConsumerStatefulWidget {
  const SendMessageScreen({
    required this.messageType,
    super.key,
  });

  final String messageType;

  @override
  ConsumerState<SendMessageScreen> createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends ConsumerState<SendMessageScreen> {
  late final MessageType _type;

  /// 0 = numbers, 1 = groups
  int _recipientMode = 0;

  @override
  void initState() {
    super.initState();
    _type = MessageType.fromValue(widget.messageType);

    // Pre-select groups tab if navigated via "from_groups".
    if (_type == MessageType.fromGroups) {
      _recipientMode = 1;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messageFormProvider.notifier).setMessageType(_type);
    });
  }

  Future<void> _showPreview() async {
    final formState = ref.read(messageFormProvider);
    final validationError = formState.validate();
    if (validationError != null) {
      _showSnackBar(validationError, isError: true);
      return;
    }

    final controller = ref.read(sendMessageControllerProvider.notifier);
    final preview = await controller.preview();

    if (preview == null || !mounted) return;

    showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PreviewSheet(
        preview: preview,
        formState: formState,
        onConfirmSend: () {
          Navigator.pop(context, true);
        },
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _sendMessage();
      }
    });
  }

  Future<void> _sendMessage() async {
    // Ensure messageType matches recipient mode.
    final form = ref.read(messageFormProvider);
    if (form.groupIds.isNotEmpty && form.numbers.isEmpty) {
      ref.read(messageFormProvider.notifier).setMessageType(MessageType.fromGroups);
    } else {
      ref.read(messageFormProvider.notifier).setMessageType(MessageType.fromNumbers);
    }

    final controller = ref.read(sendMessageControllerProvider.notifier);
    final success = await controller.send();

    if (!mounted) return;

    if (success) {
      final sendData = controller.lastSendData;
      final totalNumbers = sendData?['total_numbers'] ?? form.numbers.length + form.groupIds.length;
      final totalSms = sendData?['total_sms'] ?? '-';
      await _showResultDialog(
        isSuccess: true,
        title: '\u062A\u0645 \u0627\u0644\u0625\u0631\u0633\u0627\u0644 \u0628\u0646\u062C\u0627\u062D',
        message: '\u0639\u062F\u062F \u0627\u0644\u0623\u0631\u0642\u0627\u0645: $totalNumbers\n\u0639\u062F\u062F \u0627\u0644\u0631\u0633\u0627\u0626\u0644: $totalSms',
      );
      if (!mounted) return;
      ref.read(messageFormProvider.notifier).resetKeepType();
      context.pop();
    } else {
      final state = ref.read(sendMessageControllerProvider);
      final errorMessage = state.hasError
          ? state.error.toString()
          : '\u0641\u0634\u0644 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0631\u0633\u0627\u0644\u0629';
      await _showResultDialog(
        isSuccess: false,
        title: '\u0641\u0634\u0644 \u0627\u0644\u0625\u0631\u0633\u0627\u0644',
        message: errorMessage,
      );
    }
  }

  Future<void> _showResultDialog({
    required bool isSuccess,
    required String title,
    required String message,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSuccess
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                color: isSuccess ? AppColors.success : AppColors.error,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSuccess ? AppColors.success : AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  isSuccess ? '\u062A\u0645' : '\u062D\u0633\u0646\u0627\u064B',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _openTemplatePicker() async {
    final template = await TemplatePickerSheet.show(context);
    if (template != null) {
      ref.read(messageFormProvider.notifier).insertTemplate(template);
    }
  }

  void _onRecipientModeChanged(int mode) {
    setState(() => _recipientMode = mode);
    // Clear the other mode's data when switching.
    if (mode == 0) {
      ref.read(messageFormProvider.notifier).setGroupIds([]);
    } else {
      ref.read(messageFormProvider.notifier).clearNumbers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sendState = ref.watch(sendMessageControllerProvider);
    final isSending = sendState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_type.arabicLabel),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () {
            ref.read(messageFormProvider.notifier).resetKeepType();
            context.pop();
          },
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Sender Name Dropdown ───────────────────────────
              _buildSenderDropdown(),

              const SizedBox(height: 24),

              // ─── Recipient Mode Toggle ──────────────────────────
              _buildRecipientModeToggle(),

              const SizedBox(height: 16),

              // ─── Recipients Section ─────────────────────────────
              if (_recipientMode == 0)
                const RecipientInput()
              else
                _buildGroupsSection(),

              const SizedBox(height: 24),

              // ─── Message Body Composer ──────────────────────────
              MessageComposer(
                onInsertTemplate: _openTemplatePicker,
              ),

              const SizedBox(height: 24),

              // ─── Schedule Picker ────────────────────────────────
              const SchedulePicker(),

              const SizedBox(height: 32),

              // ─── Action Buttons ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      text: '\u0645\u0639\u0627\u064A\u0646\u0629',
                      icon: Icons.visibility_outlined,
                      onPressed: isSending ? null : _showPreview,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton.primary(
                      text: '\u0625\u0631\u0633\u0627\u0644',
                      icon: Icons.send_rounded,
                      onPressed: isSending ? null : _sendMessage,
                      isLoading: isSending,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Recipient Mode Toggle ─────────────────────────────────────────

  Widget _buildRecipientModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildToggleTab(
            label: '\u0623\u0631\u0642\u0627\u0645',
            icon: Icons.dialpad_rounded,
            isSelected: _recipientMode == 0,
            onTap: () => _onRecipientModeChanged(0),
          ),
          const SizedBox(width: 4),
          _buildToggleTab(
            label: '\u0645\u062C\u0645\u0648\u0639\u0627\u062A',
            icon: Icons.people_rounded,
            isSelected: _recipientMode == 1,
            onTap: () => _onRecipientModeChanged(1),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Groups Section ─────────────────────────────────────────────────

  Widget _buildGroupsSection() {
    final groupsAsync = ref.watch(groupsForSendProvider);
    final formState = ref.watch(messageFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '\u0627\u0644\u0645\u062C\u0645\u0648\u0639\u0627\u062A',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (formState.groupIds.isNotEmpty || formState.numbers.isNotEmpty)
              Text(
                formState.groupIds.isNotEmpty
                    ? '${formState.groupIds.length} \u0645\u062C\u0645\u0648\u0639\u0629'
                    : '${formState.numbers.length} \u0631\u0642\u0645',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        groupsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.errorSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.errorBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '\u0641\u0634\u0644 \u062A\u062D\u0645\u064A\u0644 \u0627\u0644\u0645\u062C\u0645\u0648\u0639\u0627\u062A',
                    style: TextStyle(fontSize: 13, color: AppColors.error),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(groupsForSendProvider),
                  child: const Text('\u0625\u0639\u0627\u062F\u0629', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          data: (groups) {
            if (groups.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warningSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warningBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '\u0644\u0627 \u062A\u0648\u062C\u062F \u0645\u062C\u0645\u0648\u0639\u0627\u062A',
                      style: TextStyle(fontSize: 13, color: AppColors.warning),
                    ),
                  ],
                ),
              );
            }

            return _GroupsList(
              groups: groups,
              selectedGroupIds: formState.groupIds,
              selectedNumbers: formState.numbers,
              onToggleGroup: (groupId) {
                ref.read(messageFormProvider.notifier).toggleGroupId(groupId);
              },
              onAddNumber: (number) {
                ref.read(messageFormProvider.notifier).addNumber(number);
              },
              onRemoveNumber: (number) {
                ref.read(messageFormProvider.notifier).removeNumber(number);
              },
            );
          },
        ),

        // Show selected group chips.
        if (formState.groupIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: formState.groupIds.map((id) {
              final groupsData = ref.read(groupsForSendProvider).valueOrNull ?? [];
              final group = groupsData.where((g) => g.id == id).firstOrNull;
              return Chip(
                label: Text(
                  group?.name ?? '#$id',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  ref.read(messageFormProvider.notifier).toggleGroupId(id);
                },
                backgroundColor: AppColors.primarySurface,
                side: const BorderSide(color: AppColors.primaryBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],

        // Show selected individual numbers from groups.
        if (formState.numbers.isNotEmpty && _recipientMode == 1) ...[
          const SizedBox(height: 12),
          const Text(
            '\u0623\u0631\u0642\u0627\u0645 \u0645\u062D\u062F\u062F\u0629:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: formState.numbers.map((number) {
              return Chip(
                label: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                  textDirection: TextDirection.ltr,
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  ref.read(messageFormProvider.notifier).removeNumber(number);
                },
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ─── Sender Dropdown ───────────────────────────────────────────────

  Widget _buildSenderDropdown() {
    final sendersAsync = ref.watch(sendersProvider);
    final formState = ref.watch(messageFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '\u0627\u0633\u0645 \u0627\u0644\u0645\u0631\u0633\u0644',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        sendersAsync.when(
          loading: () => Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          error: (error, _) => Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.errorSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.errorBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '\u0641\u0634\u0644 \u062A\u062D\u0645\u064A\u0644 \u0623\u0633\u0645\u0627\u0621 \u0627\u0644\u0645\u0631\u0633\u0644\u064A\u0646',
                    style: TextStyle(fontSize: 13, color: AppColors.error),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(sendersProvider),
                  child: const Text(
                    '\u0625\u0639\u0627\u062F\u0629',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          data: (senders) {
            if (senders.isEmpty) {
              return Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.warningSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warningBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '\u0644\u0627 \u062A\u0648\u062C\u062F \u0623\u0633\u0645\u0627\u0621 \u0645\u0631\u0633\u0644\u064A\u0646 \u0645\u062A\u0627\u062D\u0629',
                      style: TextStyle(fontSize: 13, color: AppColors.warning),
                    ),
                  ],
                ),
              );
            }

            return DropdownButtonFormField<int>(
              value: formState.senderId,
              hint: const Text(
                '\u0627\u062E\u062A\u0631 \u0627\u0633\u0645 \u0627\u0644\u0645\u0631\u0633\u0644',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 14,
                ),
              ),
              items: senders.map((sender) {
                return DropdownMenuItem<int>(
                  value: sender.id,
                  child: Text(
                    sender.name,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(messageFormProvider.notifier).setSenderId(value);
                }
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.inputFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.inputBorderFocused,
                    width: 1.5,
                  ),
                ),
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ),
              dropdownColor: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            );
          },
        ),
      ],
    );
  }
}

// ─── Groups List Widget ───────────────────────────────────────────────────────

/// Shows a list of groups, each expandable to show its numbers.
/// User can select whole groups or pick individual numbers.
class _GroupsList extends ConsumerStatefulWidget {
  const _GroupsList({
    required this.groups,
    required this.selectedGroupIds,
    required this.selectedNumbers,
    required this.onToggleGroup,
    required this.onAddNumber,
    required this.onRemoveNumber,
  });

  final List<GroupModel> groups;
  final List<int> selectedGroupIds;
  final List<String> selectedNumbers;
  final void Function(int groupId) onToggleGroup;
  final void Function(String number) onAddNumber;
  final void Function(String number) onRemoveNumber;

  @override
  ConsumerState<_GroupsList> createState() => _GroupsListState();
}

class _GroupsListState extends ConsumerState<_GroupsList> {
  /// Tracks which groups are currently expanded.
  final Set<int> _expandedGroups = {};

  void _toggleExpand(int groupId) {
    setState(() {
      if (_expandedGroups.contains(groupId)) {
        _expandedGroups.remove(groupId);
      } else {
        _expandedGroups.add(groupId);
      }
    });
  }

  /// Normalize a number from API format (+966XXXXXXXXX) to local (5XXXXXXXX).
  String _toLocal(String number) {
    var n = number.trim();
    if (n.startsWith('+966')) n = n.substring(4);
    if (n.startsWith('966')) n = n.substring(3);
    if (n.startsWith('0')) n = n.substring(1);
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.groups.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _buildGroupTile(widget.groups[i]),
            if (_expandedGroups.contains(widget.groups[i].id))
              _buildGroupNumbers(widget.groups[i].id),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupTile(GroupModel group) {
    final isSelected = widget.selectedGroupIds.contains(group.id);
    final isExpanded = _expandedGroups.contains(group.id);

    return InkWell(
      onTap: () => widget.onToggleGroup(group.id),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Checkbox for whole group.
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => widget.onToggleGroup(group.id),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            // Group info.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${group.numbersCount} \u0631\u0642\u0645',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Expand button to show individual numbers.
            if (group.numbersCount > 0)
              IconButton(
                icon: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                onPressed: () => _toggleExpand(group.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: isExpanded
                    ? '\u0625\u062E\u0641\u0627\u0621 \u0627\u0644\u0623\u0631\u0642\u0627\u0645'
                    : '\u0639\u0631\u0636 \u0627\u0644\u0623\u0631\u0642\u0627\u0645',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupNumbers(int groupId) {
    final numbersAsync = ref.watch(groupNumbersProvider(groupId));

    return Container(
      color: AppColors.surfaceVariant,
      padding: const EdgeInsets.only(right: 36, left: 12, bottom: 8, top: 4),
      child: numbersAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(12),
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            '\u0641\u0634\u0644 \u062A\u062D\u0645\u064A\u0644 \u0627\u0644\u0623\u0631\u0642\u0627\u0645',
            style: TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ),
        data: (numbers) {
          if (numbers.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '\u0644\u0627 \u062A\u0648\u062C\u062F \u0623\u0631\u0642\u0627\u0645',
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: numbers.map((numberModel) {
              final localNumber = _toLocal(numberModel.number);
              final isSelected = widget.selectedNumbers.contains(localNumber);

              return InkWell(
                onTap: () {
                  if (isSelected) {
                    widget.onRemoveNumber(localNumber);
                  } else {
                    widget.onAddNumber(localNumber);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (_) {
                            if (isSelected) {
                              widget.onRemoveNumber(localNumber);
                            } else {
                              widget.onAddNumber(localNumber);
                            }
                          },
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (numberModel.name.isNotEmpty) ...[
                        Text(
                          numberModel.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        localNumber,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// ─── Preview Sheet ───────────────────────────────────────────────────────────

class _PreviewSheet extends StatelessWidget {
  const _PreviewSheet({
    required this.preview,
    required this.formState,
    required this.onConfirmSend,
  });

  final MessagePreview preview;
  final MessageFormState formState;
  final VoidCallback onConfirmSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.preview, color: AppColors.primary, size: 22),
                SizedBox(width: 8),
                Text(
                  '\u0645\u0639\u0627\u064A\u0646\u0629 \u0627\u0644\u0631\u0633\u0627\u0644\u0629',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _PreviewRow(
                    icon: Icons.people_outline,
                    label: '\u0639\u062F\u062F \u0627\u0644\u0645\u0633\u062A\u0642\u0628\u0644\u064A\u0646',
                    value: '${preview.recipientCount}',
                  ),
                  const Divider(height: 20),
                  _PreviewRow(
                    icon: Icons.sms_outlined,
                    label: '\u0639\u062F\u062F \u0627\u0644\u0631\u0633\u0627\u0626\u0644',
                    value: '${preview.messageCount}',
                  ),
                  const Divider(height: 20),
                  _PreviewRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: '\u0627\u0644\u062A\u0643\u0644\u0641\u0629 \u0627\u0644\u0645\u0642\u062F\u0631\u0629',
                    value: '${preview.costEstimate.toStringAsFixed(1)} \u0631\u0633\u0627\u0644\u0629',
                    valueColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '\u0646\u0635 \u0627\u0644\u0631\u0633\u0627\u0644\u0629:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formState.messageBody,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                    textDirection: TextDirection.rtl,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('\u0625\u0644\u063A\u0627\u0621', style: TextStyle(fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onConfirmSend,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text(
                      '\u062A\u0623\u0643\u064A\u062F \u0627\u0644\u0625\u0631\u0633\u0627\u0644',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
