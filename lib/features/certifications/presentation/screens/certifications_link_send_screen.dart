import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/certifications/data/repositories/certifications_repository.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Wave 9 Certifications Link → Send screen.
///
/// Endpoints:
/// - `POST /certifications-link/preview`
/// - `POST /certifications-link/send`
class CertificationsLinkSendScreen extends ConsumerStatefulWidget {
  const CertificationsLinkSendScreen({super.key});

  @override
  ConsumerState<CertificationsLinkSendScreen> createState() =>
      _CertificationsLinkSendScreenState();
}

class _CertificationsLinkSendScreenState
    extends ConsumerState<CertificationsLinkSendScreen> {
  final _numbersController = TextEditingController();
  final _senderIdController = TextEditingController();
  final _messageController = TextEditingController();
  String _sendAtOption = 'now';
  String? _replayingService;

  bool _busy = false;
  Map<String, dynamic>? _previewData;

  @override
  void dispose() {
    _numbersController.dispose();
    _senderIdController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  List<String> _parseNumbers() {
    return _numbersController.text
        .split(RegExp(r'[\n,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _preview() async {
    final numbers = _parseNumbers();
    if (numbers.isEmpty || _senderIdController.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(certificationsRepositoryProvider);
      final data = await repo.linkPreview(
        numbers: numbers,
        senderId: _senderIdController.text.trim(),
        message: _messageController.text,
      );
      if (!mounted) return;
      setState(() {
        _previewData = data;
        _busy = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _send() async {
    final numbers = _parseNumbers();
    if (numbers.isEmpty || _senderIdController.text.trim().isEmpty) return;
    final t = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final repo = ref.read(certificationsRepositoryProvider);
      await repo.linkSend(
        numbers: numbers,
        senderId: _senderIdController.text.trim(),
        message: _messageController.text,
        sendAtOption: _sendAtOption,
        replayingService: _replayingService,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.translate('certificationsLinkSent')),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).maybePop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(t.translate('certificationsLinkSend')),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: t.translate('certificationsLinkSend'),
              hint: t.translate('numbers'),
              controller: _numbersController,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: t.translate('senderName'),
              controller: _senderIdController,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: t.translate('messageBody'),
              controller: _messageController,
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            if (_previewData != null) _buildPreviewBox(t),
            const SizedBox(height: 16),
            AppButton.secondary(
              text: t.translate('certificationsLinkPreview'),
              icon: Icons.visibility_outlined,
              isLoading: _busy && _previewData == null,
              onPressed: _busy ? null : _preview,
            ),
            const SizedBox(height: 12),
            AppButton.primary(
              text: t.translate('certificationsLinkSend'),
              icon: Icons.send_rounded,
              isLoading: _busy && _previewData != null,
              onPressed: _busy ? null : _send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewBox(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.translate('certificationsLinkPreview'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.info,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _previewData.toString(),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
