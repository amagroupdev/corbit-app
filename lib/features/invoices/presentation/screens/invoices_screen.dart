import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/invoices/data/models/invoice_model.dart';
import 'package:orbit_app/features/invoices/data/repositories/invoices_repository.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';

/// Wave 9 Invoices list screen — backed by the V3 endpoint
/// `POST /settings/invoices/list`.
class InvoicesV3Screen extends ConsumerStatefulWidget {
  const InvoicesV3Screen({super.key});

  @override
  ConsumerState<InvoicesV3Screen> createState() => _InvoicesV3ScreenState();
}

class _InvoicesV3ScreenState extends ConsumerState<InvoicesV3Screen> {
  bool _loading = true;
  String? _error;
  List<InvoiceModel> _items = const [];

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
      final result = await repo.list();
      if (!mounted) return;
      setState(() {
        _items = result.data;
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(t.translate('invoicesTitle')),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _buildBody(t),
    );
  }

  Widget _buildBody(AppLocalizations t) {
    if (_loading) return AppLoading.listShimmer();
    if (_error != null) {
      return AppErrorWidget(message: _error!, onRetry: _load);
    }
    if (_items.isEmpty) {
      return AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: t.translate('invoicesEmpty'),
      );
    }

    final dateFormat = intl.DateFormat('yyyy/MM/dd');
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final invoice = _items[i];
          return Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/invoices/${invoice.id}'),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.receipt_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.number ?? '#${invoice.id}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _formatDate(invoice.date, dateFormat),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      invoice.totalAmount?.toStringAsFixed(2) ?? '—',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String? raw, intl.DateFormat formatter) {
    if (raw == null) return '';
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    return formatter.format(d);
  }
}
