import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/features/messages/data/models/dlr_report_model.dart';
import 'package:orbit_app/features/messages/data/repositories/messages_repository.dart';

/// Lookup screen for `POST /messages/dlr-by-number`.
///
/// User types a phone number, the screen calls the gateway and lists
/// every message ever sent to that number along with the DLR transitions
/// for each one. Tapping a row opens the receipt-report screen for that
/// message UUID.
class DlrByNumberScreen extends ConsumerStatefulWidget {
  const DlrByNumberScreen({super.key});

  @override
  ConsumerState<DlrByNumberScreen> createState() => _DlrByNumberScreenState();
}

class _DlrByNumberScreenState extends ConsumerState<DlrByNumberScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  List<DlrReportEntry>? _results;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalize(String number) {
    var n = number.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (n.startsWith('00')) n = '+${n.substring(2)}';
    if (n.startsWith('05')) n = '+966${n.substring(1)}';
    if (n.startsWith('5') && n.length == 9) n = '+966$n';
    if (n.startsWith('966') && !n.startsWith('+')) n = '+$n';
    if (!n.startsWith('+') && n.isNotEmpty) n = '+$n';
    return n;
  }

  Future<void> _search() async {
    final t = AppLocalizations.of(context)!;
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = t.translate('dlrByNumberInvalid'));
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _results = null;
    });

    try {
      final repo = ref.read(messagesRepositoryProvider);
      final entries = await repo.dlrByNumber(_normalize(raw));
      if (!mounted) return;
      setState(() {
        _loading = false;
        _results = entries;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
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
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.translate('dlrByNumberTitle')),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Search input ─────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        hintText: t.translate('dlrByNumberSearch'),
                        prefixIcon: const Icon(Icons.phone_outlined,
                            size: 20),
                        filled: true,
                        fillColor: AppColors.inputFill,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.inputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.inputBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.inputBorderFocused,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _loading ? null : _search,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.search, size: 20),
                  ),
                ],
              ),
            ),

            // ─── Body ────────────────────────────────────
            Expanded(child: _buildBody(t)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations t) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final results = _results;
    if (results == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            t.translate('dlrByNumberSearch'),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            t.translate('dlrByNumberEmpty'),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = results[index];
        final color = _statusColor(entry.dlrStatus);
        return InkWell(
          onTap: entry.messageUuid.isEmpty
              ? null
              : () => context.push('/messages/receipt/${entry.messageUuid}'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
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
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.dlrStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const Spacer(),
                    if (entry.sentAt != null)
                      Text(
                        '${entry.sentAt!.year}-${entry.sentAt!.month.toString().padLeft(2, '0')}-${entry.sentAt!.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                  ],
                ),
                if (entry.messageBody != null &&
                    entry.messageBody!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    entry.messageBody!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (entry.dlrHistory.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: entry.dlrHistory.map((h) {
                      final hColor = _statusColor(h.status);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: hColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          h.status,
                          style: TextStyle(
                            fontSize: 11,
                            color: hColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
