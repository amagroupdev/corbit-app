import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/invoices/data/models/invoice_model.dart';
import 'package:orbit_app/features/invoices/data/repositories/invoices_repository.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';

/// Wave 9 Invoice detail screen.
///
/// Loads `GET /settings/invoices/{id}` and offers a button that
/// fetches the PDF URL via `GET /settings/invoices/{id}/pdf`.
class InvoiceDetailScreen extends ConsumerStatefulWidget {
  const InvoiceDetailScreen({required this.invoiceId, super.key});

  final int invoiceId;

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  bool _loading = true;
  bool _downloading = false;
  String? _error;
  InvoiceModel? _invoice;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(invoicesRepositoryProvider);
      final inv = await repo.show(widget.invoiceId);
      if (!mounted) return;
      setState(() {
        _invoice = inv;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _downloading = true);
    try {
      final repo = ref.read(invoicesRepositoryProvider);
      final url = await repo.pdfUrl(widget.invoiceId);
      if (!mounted) return;
      setState(() => _downloading = false);

      if (url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.translate('invoicePdfUnavailable')),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _downloading = false);
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
        title: Text(t.translate('invoiceNumber')),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _buildBody(t),
    );
  }

  Widget _buildBody(AppLocalizations t) {
    if (_loading) return AppLoading.circular();
    if (_error != null) {
      return AppErrorWidget(message: _error!, onRetry: _load);
    }
    final inv = _invoice;
    if (inv == null) {
      return Center(child: Text(t.translate('invoicesEmpty')));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row(t.translate('invoiceNumber'), inv.number ?? '#${inv.id}'),
          const SizedBox(height: 8),
          _row(t.translate('invoiceDate'), inv.date ?? '—'),
          const SizedBox(height: 8),
          _row(
            t.translate('invoiceTotal'),
            inv.totalAmount?.toStringAsFixed(2) ?? '—',
          ),
          const SizedBox(height: 8),
          _row(t.translate('invoiceStatus'), inv.status ?? '—'),
          const SizedBox(height: 24),
          AppButton.primary(
            text: t.translate('invoiceDownloadPdf'),
            icon: Icons.picture_as_pdf_outlined,
            isLoading: _downloading,
            onPressed: _downloadPdf,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
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
