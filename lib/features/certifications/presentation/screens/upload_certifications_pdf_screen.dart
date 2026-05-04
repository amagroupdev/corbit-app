import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/certifications/data/repositories/certifications_repository.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';

/// Wave 9 Upload Certifications PDF screen.
///
/// Backed by `POST /certifications/upload-pdf-file` (multipart).
class UploadCertificationsPdfScreen extends ConsumerStatefulWidget {
  const UploadCertificationsPdfScreen({super.key});

  @override
  ConsumerState<UploadCertificationsPdfScreen> createState() =>
      _UploadCertificationsPdfScreenState();
}

class _UploadCertificationsPdfScreenState
    extends ConsumerState<UploadCertificationsPdfScreen> {
  PlatformFile? _file;
  bool _uploading = false;
  double _progress = 0;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _file = result.files.first);
  }

  Future<void> _upload() async {
    final file = _file;
    if (file == null) return;
    final t = AppLocalizations.of(context)!;
    setState(() {
      _uploading = true;
      _progress = 0;
    });
    try {
      final repo = ref.read(certificationsRepositoryProvider);
      final path = file.path;
      MultipartFile mf;
      if (path != null) {
        mf = await MultipartFile.fromFile(path, filename: file.name);
      } else if (file.bytes != null) {
        mf = MultipartFile.fromBytes(file.bytes!, filename: file.name);
      } else {
        throw const ServerException(message: 'Unable to read file.');
      }
      await repo.uploadPdfFile(
        file: mf,
        onSendProgress: (sent, total) {
          if (total > 0) {
            setState(() => _progress = sent / total);
          }
        },
      );
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _progress = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.translate('certificationsUploaded')),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).maybePop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
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
        title: Text(t.translate('certificationsUploadPdf')),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _file?.name ?? t.translate('certificationsUploadPdf'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_uploading) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: _progress),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppButton.secondary(
              text: t.translate('select'),
              icon: Icons.attach_file_rounded,
              onPressed: _uploading ? null : _pick,
            ),
            const SizedBox(height: 12),
            AppButton.primary(
              text: t.translate('certificationsUploadPdf'),
              icon: Icons.cloud_upload_outlined,
              isLoading: _uploading,
              onPressed: _file == null || _uploading ? null : _upload,
            ),
          ],
        ),
      ),
    );
  }
}
