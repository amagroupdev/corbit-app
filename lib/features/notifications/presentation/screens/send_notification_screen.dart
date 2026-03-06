import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/notifications/data/repositories/notifications_repository.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Screen for composing and sending a push notification.
class SendNotificationScreen extends ConsumerStatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  ConsumerState<SendNotificationScreen> createState() =>
      _SendNotificationScreenState();
}

class _SendNotificationScreenState
    extends ConsumerState<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _numbersController = TextEditingController();
  bool _isSending = false;
  bool _isPreviewing = false;
  Map<String, dynamic>? _previewData;

  @override
  void dispose() {
    _messageController.dispose();
    _numbersController.dispose();
    super.dispose();
  }

  List<String> get _numbers {
    final text = _numbersController.text.trim();
    if (text.isEmpty) return [];
    return text
        .split(RegExp(r'[,\n\s]+'))
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();
  }

  Future<void> _preview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPreviewing = true);

    try {
      final repository = ref.read(notificationsRepositoryProvider);
      final data = await repository.preview(
        message: _messageController.text.trim(),
        groupIds: [],
        numbers: _numbers,
      );

      if (mounted) {
        setState(() {
          _previewData = data;
          _isPreviewing = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isPreviewing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final repository = ref.read(notificationsRepositoryProvider);
      await repository.sendNotification(
        message: _messageController.text.trim(),
        groupIds: [],
        numbers: _numbers,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '\u062A\u0645 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0625\u0634\u0639\u0627\u0631 \u0628\u0646\u062C\u0627\u062D', // تم إرسال الإشعار بنجاح
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '\u0625\u0631\u0633\u0627\u0644 \u0625\u0634\u0639\u0627\u0631', // إرسال إشعار
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Numbers field ──────────────────────────────
              AppTextField(
                label: '\u0623\u0631\u0642\u0627\u0645 \u0627\u0644\u0645\u0633\u062A\u0644\u0645\u064A\u0646', // أرقام المستلمين
                hint: '\u0623\u062F\u062E\u0644 \u0627\u0644\u0623\u0631\u0642\u0627\u0645 \u0645\u0641\u0635\u0648\u0644\u0629 \u0628\u0641\u0627\u0635\u0644\u0629', // أدخل الأرقام مفصولة بفاصلة
                controller: _numbersController,
                maxLines: 3,
                minLines: 2,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '\u064A\u0631\u062C\u0649 \u0625\u062F\u062E\u0627\u0644 \u0631\u0642\u0645 \u0648\u0627\u062D\u062F \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644'; // يرجى إدخال رقم واحد على الأقل
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Message field ─────────────────────────────
              AppTextField(
                label: '\u0646\u0635 \u0627\u0644\u0625\u0634\u0639\u0627\u0631', // نص الإشعار
                hint: '\u0623\u062F\u062E\u0644 \u0646\u0635 \u0627\u0644\u0625\u0634\u0639\u0627\u0631', // أدخل نص الإشعار
                controller: _messageController,
                maxLines: 5,
                minLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '\u064A\u0631\u062C\u0649 \u0625\u062F\u062E\u0627\u0644 \u0646\u0635 \u0627\u0644\u0625\u0634\u0639\u0627\u0631'; // يرجى إدخال نص الإشعار
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ── Preview data ──────────────────────────────
              if (_previewData != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.infoSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.infoBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '\u0645\u0639\u0627\u064A\u0646\u0629', // معاينة
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _PreviewRow(
                        label: '\u0639\u062F\u062F \u0627\u0644\u0645\u0633\u062A\u0644\u0645\u064A\u0646', // عدد المستلمين
                        value: '${_previewData!['recipient_count'] ?? 0}',
                      ),
                      _PreviewRow(
                        label: '\u0627\u0644\u062A\u0643\u0644\u0641\u0629 \u0627\u0644\u062A\u0642\u062F\u064A\u0631\u064A\u0629', // التكلفة التقديرية
                        value: '${_previewData!['cost_estimate'] ?? 0}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Action buttons ────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      text: '\u0645\u0639\u0627\u064A\u0646\u0629', // معاينة
                      onPressed: _preview,
                      isLoading: _isPreviewing,
                      icon: Icons.preview_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton.primary(
                      text: '\u0625\u0631\u0633\u0627\u0644', // إرسال
                      onPressed: _send,
                      isLoading: _isSending,
                      icon: Icons.send_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
