import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/feature_flags.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/certifications/data/models/certification_model.dart';
import 'package:orbit_app/features/certifications/data/models/certification_settings_model.dart';
import 'package:orbit_app/features/certifications/data/repositories/certifications_repository.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';

/// Wave 9 advanced certifications list screen.
///
/// Backed by `POST /certifications/list` with filter options from
/// `GET /certifications/filter-options`. Supports multi-select +
/// bulk delete via `POST /certifications/delete`.
class CertificationsListScreen extends ConsumerStatefulWidget {
  const CertificationsListScreen({super.key});

  @override
  ConsumerState<CertificationsListScreen> createState() =>
      _CertificationsListScreenState();
}

class _CertificationsListScreenState
    extends ConsumerState<CertificationsListScreen> {
  bool _loading = true;
  String? _error;
  List<CertificationModel> _items = const [];
  CertificationFilterOptionsModel? _filterOptions;

  String? _statusFilter;
  String? _platformFilter;
  String _search = '';

  final Set<int> _selected = <int>{};
  bool _multiSelect = false;
  bool _deleting = false;

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
      final repo = ref.read(certificationsRepositoryProvider);
      final listing = await repo.listAdvanced(
        search: _search.isEmpty ? null : _search,
        status: _statusFilter,
        platform: _platformFilter,
      );
      CertificationFilterOptionsModel? filterOptions = _filterOptions;
      filterOptions ??= await repo.getFilterOptions();
      if (!mounted) return;
      setState(() {
        _items = listing.data;
        _filterOptions = filterOptions;
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

  Future<void> _bulkDelete() async {
    if (_selected.isEmpty) return;
    setState(() => _deleting = true);
    try {
      final repo = ref.read(certificationsRepositoryProvider);
      await repo.deleteCertifications(_selected.toList());
      if (!mounted) return;
      setState(() {
        _items = _items.where((c) => !_selected.contains(c.id)).toList();
        _selected.clear();
        _multiSelect = false;
        _deleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('certificationsDeleted'),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
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
        title: Text(
          _multiSelect
              ? '${_selected.length}'
              : t.translate('certificationsListTitle'),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (_multiSelect)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: t.translate('certificationsDelete'),
              onPressed: _deleting || _selected.isEmpty ? null : _bulkDelete,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.upload_file_outlined),
              tooltip: t.translate('certificationsUploadPdf'),
              onPressed: () => context.push('/certifications/upload-pdf'),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: t.translate('certificationsSettings'),
              onPressed: () => context.push('/certifications/settings'),
            ),
          ],
        ],
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
        icon: Icons.workspace_premium_outlined,
        title: t.translate('certificationsEmpty'),
      );
    }

    final dateFormat = intl.DateFormat('yyyy/MM/dd');
    return Column(
      children: [
        if (_filterOptions != null && _filterOptions!.statuses.isNotEmpty)
          _buildFilterChips(t),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = _items[i];
                final selected = _selected.contains(c.id);
                return Material(
                  color: selected ? AppColors.primarySurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onLongPress: () => setState(() {
                      _multiSelect = true;
                      _selected.add(c.id);
                    }),
                    onTap: () {
                      if (_multiSelect) {
                        setState(() {
                          if (selected) {
                            _selected.remove(c.id);
                            if (_selected.isEmpty) _multiSelect = false;
                          } else {
                            _selected.add(c.id);
                          }
                        });
                      }
                    },
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
                            child: Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.workspace_premium_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.recipientName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${c.recipientPhone} · ${dateFormat.format(c.createdAt)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: c.isSent
                                  ? AppColors.successSurface
                                  : AppColors.warningSurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              c.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: c.isSent
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (kCertificationsLinkEnabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AppButton.primary(
              text: t.translate('certificationsLinkSend'),
              icon: Icons.link_rounded,
              onPressed: () => context.push('/certifications-link/send'),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChips(AppLocalizations t) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filterOptions!.statuses.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            final selected = _statusFilter == null;
            return ChoiceChip(
              label: Text(t.translate('all')),
              selected: selected,
              onSelected: (_) {
                setState(() => _statusFilter = null);
                _load();
              },
            );
          }
          final status = _filterOptions!.statuses[i - 1];
          final selected = _statusFilter == status;
          return ChoiceChip(
            label: Text(status),
            selected: selected,
            onSelected: (_) {
              setState(() => _statusFilter = selected ? null : status);
              _load();
            },
          );
        },
      ),
    );
  }
}
