import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/utils/formatters.dart';
import 'package:orbit_app/features/settings/data/models/invoice_model.dart';
import 'package:orbit_app/features/settings/presentation/controllers/settings_controller.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';

import 'package:orbit_app/core/localization/app_localizations.dart';
/// Screen for viewing invoices with filtering and PDF download.
class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  String? _selectedStatus;

  List<Map<String, String>> _getStatusFilters(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return [
      {'value': '', 'label': t.translate('all')},
      {'value': 'paid', 'label': t.translate('invoice_status_paid')},
      {'value': 'unpaid', 'label': t.translate('invoice_status_unpaid')},
      {'value': 'pending', 'label': t.translate('invoice_status_pending')},
      {'value': 'overdue', 'label': t.translate('invoice_status_overdue')},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('invoices')),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Status filter chips
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _getStatusFilters(context).length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _getStatusFilters(context)[index];
                final isSelected = _selectedStatus == filter['value'] ||
                    (_selectedStatus == null && filter['value']!.isEmpty);

                return FilterChip(
                  label: Text(filter['label']!),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedStatus = filter['value']!.isEmpty
                          ? null
                          : filter['value'];
                    });
                    ref.read(invoicesProvider.notifier).filter(
                          status: _selectedStatus,
                        );
                  },
                  selectedColor: AppColors.primarySurface,
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.borderLight,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              },
            ),
          ),

          // Invoice list
          Expanded(
            child: invoicesAsync.when(
              data: (paginated) {
                if (paginated.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: AppLocalizations.of(context)!.translate('invoices_no_invoices'),
                    description: AppLocalizations.of(context)!.translate('invoices_no_match'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(invoicesProvider.notifier).refresh(),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: paginated.data.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final invoice = paginated.data[index];
                      return _InvoiceCard(
                        invoice: invoice,
                        onTap: () => _showInvoiceDetail(context, invoice),
                        onDownload: () => _downloadPdf(invoice.id),
                      );
                    },
                  ),
                );
              },
              loading: () => AppLoading.listShimmer(),
              error: (error, _) => AppErrorWidget(
                message: error.toString(),
                onRetry: () =>
                    ref.read(invoicesProvider.notifier).refresh(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInvoiceDetail(BuildContext context, InvoiceModel invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _InvoiceDetailSheet(invoice: invoice),
    );
  }

  Future<void> _downloadPdf(int id) async {
    try {
      final url = await ref.read(invoicesProvider.notifier).downloadPdf(id);
      if (url.isNotEmpty) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.translate('invoices_download_error')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.translate('error_prefix')}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ── Invoice Card ─────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoice,
    required this.onTap,
    required this.onDownload,
  });

  final InvoiceModel invoice;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  Color get _statusColor {
    return switch (invoice.status?.toLowerCase()) {
      'paid' => AppColors.success,
      'unpaid' => AppColors.error,
      'pending' => AppColors.warning,
      'overdue' => AppColors.error,
      _ => AppColors.textSecondary,
    };
  }

  Color get _statusBgColor {
    return switch (invoice.status?.toLowerCase()) {
      'paid' => AppColors.successSurface,
      'unpaid' => AppColors.errorSurface,
      'pending' => AppColors.warningSurface,
      'overdue' => AppColors.errorSurface,
      _ => AppColors.surfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.translate('invoices_invoice_prefix')} #${invoice.number ?? invoice.id}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          invoice.date ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.translate(invoice.statusLabelKey),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.formatCurrency(invoice.totalAmount ?? 0),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: onDownload,
                    icon: const Icon(
                      Icons.download_rounded,
                      color: AppColors.primary,
                    ),
                    tooltip: AppLocalizations.of(context)!.translate('invoices_download_pdf'),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    padding: EdgeInsets.zero,
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

// ── Invoice Detail Sheet ─────────────────────────────────────────────────

class _InvoiceDetailSheet extends StatelessWidget {
  const _InvoiceDetailSheet({required this.invoice});

  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '${AppLocalizations.of(context)!.translate('invoices_invoice_prefix')} #${invoice.number ?? invoice.id}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          Flexible(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shrinkWrap: true,
              children: [
                _detailRow(AppLocalizations.of(context)!.translate('invoices_invoice_number'), invoice.number ?? '-'),
                _detailRow(AppLocalizations.of(context)!.translate('invoices_invoice_date'), invoice.date ?? '-'),
                _detailRow(AppLocalizations.of(context)!.translate('invoices_invoice_status'), AppLocalizations.of(context)!.translate(invoice.statusLabelKey)),
                _detailRow(
                  AppLocalizations.of(context)!.translate('invoices_invoice_amount'),
                  Formatters.formatCurrency(invoice.amount ?? 0),
                ),
                _detailRow(
                  AppLocalizations.of(context)!.translate('invoices_invoice_tax'),
                  Formatters.formatCurrency(invoice.tax ?? 0),
                ),
                _detailRow(
                  AppLocalizations.of(context)!.translate('invoices_invoice_total'),
                  Formatters.formatCurrency(invoice.totalAmount ?? 0),
                ),
                if (invoice.paymentMethod != null)
                  _detailRow(AppLocalizations.of(context)!.translate('invoices_payment_method'), invoice.paymentMethod!),
                if (invoice.notes != null)
                  _detailRow(AppLocalizations.of(context)!.translate('invoices_notes'), invoice.notes!),

                if (invoice.items.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.translate('invoices_items'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...invoice.items.map(
                    (item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.description ?? '-',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(item.total ?? 0),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
