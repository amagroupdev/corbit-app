import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/absence/data/models/absence_message_model.dart';
import 'package:orbit_app/features/absence/data/repositories/absence_repository.dart';
import 'package:orbit_app/features/absence/presentation/widgets/absence_message_card.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_search_bar.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';

/// Screen for managing absence & tardiness messages (رسائل الغياب والتأخر).
///
/// Features:
/// - Send absence message button
/// - Filter section with dropdowns and date pickers
/// - Status filter tabs (All, Sent, Failed, Pending)
/// - Searchable message list with cards
class AbsenceMessagesScreen extends ConsumerStatefulWidget {
  const AbsenceMessagesScreen({super.key});

  @override
  ConsumerState<AbsenceMessagesScreen> createState() =>
      _AbsenceMessagesScreenState();
}

class _AbsenceMessagesScreenState extends ConsumerState<AbsenceMessagesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchQuery = '';
  bool _showFilters = false;

  // Filter state
  String? _selectedSenderName;
  String? _selectedMessageType;
  String? _selectedClassification;
  bool _useHijriDate = false;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  // Tab status mapping
  static const _tabStatuses = [null, 'sent', 'failed', 'pending'];

  // Data state
  List<AbsenceMessageModel> _messages = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadMessages();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadMessages();
    }
  }

  Future<void> _loadMessages({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(absenceRepositoryProvider);
      final statusFilter = _tabStatuses[_tabController.index];
      final result = await repo.getMessages(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: statusFilter,
        messageType: _selectedMessageType,
        senderName: _selectedSenderName,
        classification: _selectedClassification,
        dateFrom: _dateFrom?.toIso8601String().split('T').first,
        dateTo: _dateTo?.toIso8601String().split('T').first,
      );
      if (mounted) {
        setState(() {
          _messages = result.data;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _loadMessages();
  }

  void _applyFilters() {
    _loadMessages();
  }

  void _resetFilters() {
    setState(() {
      _selectedSenderName = null;
      _selectedMessageType = null;
      _selectedClassification = null;
      _useHijriDate = false;
      _dateFrom = null;
      _dateTo = null;
    });
    _loadMessages();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('absenceMessages'),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters
                  ? Icons.filter_list_off
                  : Icons.filter_list,
              color: AppColors.primary,
            ),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
            tooltip: AppLocalizations.of(context)!.translate('filter'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          isScrollable: true,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.translate('allMessages')),
            Tab(text: AppLocalizations.of(context)!.translate('sentMessages')),
            Tab(text: AppLocalizations.of(context)!.translate('failedMessages_')),
            Tab(text: AppLocalizations.of(context)!.translate('pendingMessages_')),
          ],
        ),
      ),
      body: Column(
        children: [
          // Send absence message button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to send absence message flow
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  AppLocalizations.of(context)!.translate('sendAbsenceMessage'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),

          // Description text
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              AppLocalizations.of(context)!.translate('absenceManageDesc'),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Filter section
          if (_showFilters) _buildFilterSection(),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchBar(
              hint: AppLocalizations.of(context)!.translate('searchAbsenceMessages'),
              onChanged: _onSearchChanged,
            ),
          ),

          // Message list
          Expanded(child: _buildMessageList()),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sender Name dropdown
          _buildFilterDropdown(
            label: AppLocalizations.of(context)!.translate('senderNameFilter'),
            value: _selectedSenderName,
            items: const [], // Populated from API
            hint: AppLocalizations.of(context)!.translate('selectSender'),
            onChanged: (value) => setState(() => _selectedSenderName = value),
          ),
          const SizedBox(height: 12),

          // Message Type dropdown
          _buildFilterDropdown(
            label: AppLocalizations.of(context)!.translate('messageTypeFilter'),
            value: _selectedMessageType,
            items: [
              DropdownMenuItem(
                value: 'absence',
                child: Text(AppLocalizations.of(context)!.translate('absenceType')),
              ),
              DropdownMenuItem(
                value: 'tardiness',
                child: Text(AppLocalizations.of(context)!.translate('tardinessType')),
              ),
            ],
            hint: AppLocalizations.of(context)!.translate('selectType'),
            onChanged: (value) => setState(() => _selectedMessageType = value),
          ),
          const SizedBox(height: 12),

          // Message Classification dropdown
          _buildFilterDropdown(
            label: AppLocalizations.of(context)!.translate('messageClassification'),
            value: _selectedClassification,
            items: const [], // Populated from API
            hint: AppLocalizations.of(context)!.translate('selectClassification'),
            onChanged: (value) =>
                setState(() => _selectedClassification = value),
          ),
          const SizedBox(height: 12),

          // Hijri date checkbox
          Row(
            children: [
              Checkbox(
                value: _useHijriDate,
                onChanged: (value) =>
                    setState(() => _useHijriDate = value ?? false),
                activeColor: AppColors.primary,
              ),
              Text(
                AppLocalizations.of(context)!.translate('hijriDate'),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date pickers row
          Row(
            children: [
              Expanded(
                child: _buildDatePickerButton(
                  label: AppLocalizations.of(context)!.translate('fromDate'),
                  date: _dateFrom,
                  onTap: () => _pickDate(isFrom: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePickerButton(
                  label: AppLocalizations.of(context)!.translate('toDate'),
                  date: _dateTo,
                  onTap: () => _pickDate(isFrom: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Apply / Reset buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.translate('apply'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetFilters,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.translate('resetFilter'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textHint,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
        ),
      ],
    );
  }

  Widget _buildDatePickerButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.textHint,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null
                    ? '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}'
                    : label,
                style: TextStyle(
                  fontSize: 13,
                  color: date != null
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_loading) return AppLoading.listShimmer();
    if (_error != null) {
      return AppErrorWidget(
        message: _error!,
        onRetry: () => _loadMessages(refresh: true),
      );
    }
    if (_messages.isEmpty) {
      return AppEmptyState(
        icon: Icons.person_off_outlined,
        title: AppLocalizations.of(context)!.translate('noAbsenceMessages'),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadMessages(refresh: true),
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _messages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final msg = _messages[index];
          return AbsenceMessageCard(
            message: msg,
            onView: () {
              // TODO: Navigate to message detail
            },
            onReport: () {
              // TODO: Navigate to delivery report
            },
          );
        },
      ),
    );
  }
}
