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
        title: const Text(
          '\u0631\u0633\u0627\u0626\u0644 \u0627\u0644\u063A\u064A\u0627\u0628 \u0648\u0627\u0644\u062A\u0623\u062E\u0631', // رسائل الغياب والتأخر
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
            tooltip: '\u062A\u0635\u0641\u064A\u0629', // تصفية
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          isScrollable: true,
          tabs: const [
            Tab(text: '\u0627\u0644\u0643\u0644'), // الكل
            Tab(text: '\u062A\u0645 \u0627\u0644\u0625\u0631\u0633\u0627\u0644'), // تم الإرسال
            Tab(text: '\u0641\u0634\u0644'), // فشل
            Tab(text: '\u0642\u064A\u062F \u0627\u0644\u0625\u0646\u062A\u0638\u0627\u0631'), // قيد الإنتظار
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
                label: const Text(
                  '\u0625\u0631\u0633\u0627\u0644 \u0631\u0633\u0627\u0644\u0629 \u063A\u064A\u0627\u0628', // إرسال رسالة غياب
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
              '\u0625\u062F\u0627\u0631\u0629 \u0631\u0633\u0627\u0626\u0644 \u0627\u0644\u063A\u064A\u0627\u0628 \u0648\u0627\u0644\u062A\u0623\u062E\u0631 \u0627\u0644\u0645\u0631\u0633\u0644\u0629 \u0644\u0623\u0648\u0644\u064A\u0627\u0621 \u0627\u0644\u0623\u0645\u0648\u0631', // إدارة رسائل الغياب والتأخر المرسلة لأولياء الأمور
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
              hint: '\u0628\u062D\u062B \u0641\u064A \u0631\u0633\u0627\u0626\u0644 \u0627\u0644\u063A\u064A\u0627\u0628 \u0648\u0627\u0644\u062A\u0623\u062E\u0631...', // بحث في رسائل الغياب والتأخر...
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
            label: '\u0625\u0633\u0645 \u0627\u0644\u0645\u0631\u0633\u0644', // إسم المرسل
            value: _selectedSenderName,
            items: const [], // Populated from API
            hint: '\u0627\u062E\u062A\u0631 \u0627\u0644\u0645\u0631\u0633\u0644', // اختر المرسل
            onChanged: (value) => setState(() => _selectedSenderName = value),
          ),
          const SizedBox(height: 12),

          // Message Type dropdown
          _buildFilterDropdown(
            label: '\u0646\u0648\u0639 \u0627\u0644\u0631\u0633\u0627\u0644\u0629', // نوع الرسالة
            value: _selectedMessageType,
            items: const [
              DropdownMenuItem(
                value: 'absence',
                child: Text('\u063A\u064A\u0627\u0628'), // غياب
              ),
              DropdownMenuItem(
                value: 'tardiness',
                child: Text('\u062A\u0623\u062E\u0631'), // تأخر
              ),
            ],
            hint: '\u0627\u062E\u062A\u0631 \u0627\u0644\u0646\u0648\u0639', // اختر النوع
            onChanged: (value) => setState(() => _selectedMessageType = value),
          ),
          const SizedBox(height: 12),

          // Message Classification dropdown
          _buildFilterDropdown(
            label: '\u062A\u0635\u0646\u064A\u0641 \u0627\u0644\u0631\u0633\u0627\u0644\u0629', // تصنيف الرسالة
            value: _selectedClassification,
            items: const [], // Populated from API
            hint: '\u0627\u062E\u062A\u0631 \u0627\u0644\u062A\u0635\u0646\u064A\u0641', // اختر التصنيف
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
              const Text(
                '\u0627\u0644\u062A\u0627\u0631\u064A\u062E \u0627\u0644\u0647\u062C\u0631\u064A', // التاريخ الهجري
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
                  label: '\u0645\u0646 \u062A\u0627\u0631\u064A\u062E', // من تاريخ
                  date: _dateFrom,
                  onTap: () => _pickDate(isFrom: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePickerButton(
                  label: '\u0625\u0644\u0649 \u062A\u0627\u0631\u064A\u062E', // إلى تاريخ
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
                  child: const Text(
                    '\u062A\u0637\u0628\u064A\u0642', // تطبيق
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
                  child: const Text(
                    '\u062A\u0635\u0641\u064A\u0629', // تصفية
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
      return const AppEmptyState(
        icon: Icons.person_off_outlined,
        title: '\u0644\u0627 \u062A\u0648\u062C\u062F \u0631\u0633\u0627\u0626\u0644', // لا توجد رسائل
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
