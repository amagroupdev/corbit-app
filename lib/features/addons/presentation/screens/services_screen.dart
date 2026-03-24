import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/addons/data/models/addon_model.dart';
import 'package:orbit_app/features/addons/data/repositories/addons_repository.dart';
import 'package:orbit_app/features/addons/presentation/widgets/addon_card.dart';
import 'package:orbit_app/routing/route_names.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_search_bar.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';

/// Screen displaying all available addons/services in a grid layout.
///
/// Supports search filtering and toggling between all addons and
/// active-only view.
class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  String _searchQuery = '';
  bool _showActiveOnly = false;
  List<AddonModel> _addons = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAddons();
  }

  Future<void> _loadAddons({bool refresh = false}) async {
    if (!refresh && !_isLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final repository = ref.read(addonsRepositoryProvider);
      final result = await repository.getAddons(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (mounted) {
        setState(() {
          _addons = result.data;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    }
  }

  List<AddonModel> get _filteredAddons {
    if (_showActiveOnly) {
      return _addons.where((a) => a.isActive).toList();
    }
    return _addons;
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _loadAddons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('servicesTitle'),
        ),
      ),
      body: Column(
        children: [
          // ── Search & Filter ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AppSearchBar(
              hint: AppLocalizations.of(context)!.translate('searchServices'),
              onChanged: _onSearchChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: AppLocalizations.of(context)!.translate('all'),
                  isSelected: !_showActiveOnly,
                  onTap: () => setState(() => _showActiveOnly = false),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: AppLocalizations.of(context)!.translate('activeFilter'),
                  isSelected: _showActiveOnly,
                  onTap: () => setState(() => _showActiveOnly = true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Content ──────────────────────────────────────
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return AppLoading.listShimmer();
    }

    if (_errorMessage != null) {
      return AppErrorWidget(
        message: _errorMessage!,
        onRetry: () => _loadAddons(refresh: true),
      );
    }

    final filtered = _filteredAddons;

    if (filtered.isEmpty) {
      return AppEmptyState(
        icon: Icons.extension_outlined,
        title: _showActiveOnly
            ? AppLocalizations.of(context)!.translate('noActiveServices')
            : AppLocalizations.of(context)!.translate('noServices'),
        description: AppLocalizations.of(context)!.translate('exploreServices'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadAddons(refresh: true),
      color: AppColors.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final addon = filtered[index];
          return AddonCard(
            addon: addon,
            onTap: () => context.pushNamed(
              RouteNames.addonDetail,
              pathParameters: {'id': addon.id.toString()},
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
