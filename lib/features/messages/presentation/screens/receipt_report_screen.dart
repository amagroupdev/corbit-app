import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/messages/data/models/dlr_report_model.dart';
import 'package:orbit_app/features/messages/data/models/receipt_report_model.dart';
import 'package:orbit_app/features/messages/presentation/controllers/messages_controller.dart';

/// Full-screen view for `GET /messages/{uuid}/receipt-report`.
///
/// Shows the original message, a sending summary (recipients/sms/cost)
/// and a per-status DLR breakdown with a recipient list at the bottom.
class ReceiptReportScreen extends ConsumerWidget {
  const ReceiptReportScreen({required this.uuid, super.key});

  final String uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final asyncReport = ref.watch(receiptReportProvider(uuid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.translate('receiptReportTitle')),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: asyncReport.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 40),
                const SizedBox(height: 12),
                Text(
                  t.translate('receiptReportLoadFailed'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(receiptReportProvider(uuid)),
                  child: Text(t.translate('msg_reload')),
                ),
              ],
            ),
          ),
        ),
        data: (report) => _ReportBody(report: report),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

  final ReceiptReportModel report;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Original message ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      report.message.senderName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  report.message.body,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Sending summary ───────────────────────────────
          Text(
            t.translate('receiptReportSummary'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  icon: Icons.people_outline,
                  label: t.translate('msg_preview_recipients'),
                  value: '${report.sendingSummary.totalRecipients}',
                ),
                const Divider(height: 18),
                _SummaryRow(
                  icon: Icons.sms_outlined,
                  label: t.translate('msg_preview_sms_count'),
                  value: '${report.sendingSummary.totalSms}',
                ),
                const Divider(height: 18),
                _SummaryRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: t.translate('msg_preview_cost'),
                  value: report.sendingSummary.cost.toStringAsFixed(1),
                  highlight: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── DLR summary chips ────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                label: t.translate('msg_status_delivered'),
                value: report.dlrSummary.delivered,
                color: AppColors.success,
              ),
              _StatusChip(
                label: t.translate('msg_status_failed'),
                value: report.dlrSummary.failed,
                color: AppColors.error,
              ),
              _StatusChip(
                label: t.translate('msg_status_pending'),
                value: report.dlrSummary.pending,
                color: AppColors.warning,
              ),
              _StatusChip(
                label: t.translate('msg_status_sent'),
                value: report.dlrSummary.sent,
                color: AppColors.info,
              ),
              if (report.dlrSummary.expired > 0)
                _StatusChip(
                  label: t.translate('msg_status_expired'),
                  value: report.dlrSummary.expired,
                  color: AppColors.textSecondary,
                ),
              if (report.dlrSummary.rejected > 0)
                _StatusChip(
                  label: t.translate('msg_status_rejected'),
                  value: report.dlrSummary.rejected,
                  color: AppColors.error,
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Per-recipient list ───────────────────────────
          Text(
            t.translate('receiptReportNumbers'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (report.numbers.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                t.translate('dlrByNumberEmpty'),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < report.numbers.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _RecipientRow(entry: report.numbers[i]),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

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
            fontWeight: FontWeight.w700,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipientRow extends StatelessWidget {
  const _RecipientRow({required this.entry});

  final DlrReportEntry entry;

  Color _statusColor(BuildContext context) {
    switch (entry.dlrStatus.toLowerCase()) {
      case 'delivered':
        return AppColors.success;
      case 'failed':
      case 'rejected':
        return AppColors.error;
      case 'expired':
        return AppColors.textSecondary;
      case 'pending':
      case 'sent':
        return AppColors.info;
      default:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.number,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textDirection: TextDirection.ltr,
            ),
          ),
          Text(
            entry.dlrStatus,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
