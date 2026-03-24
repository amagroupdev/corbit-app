import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/attendance/data/models/attendance_model.dart';
import 'package:orbit_app/features/attendance/data/repositories/attendance_repository.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';

/// Screen for sending and viewing attendance record messages.
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Send form
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _numbersController = TextEditingController();
  bool _isSending = false;

  // Archive state
  List<AttendanceModel> _archive = [];
  bool _archiveLoading = true;
  String? _archiveError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadArchive();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _numbersController.dispose();
    super.dispose();
  }

  Future<void> _loadArchive() async {
    setState(() {
      _archiveLoading = true;
      _archiveError = null;
    });

    try {
      final repo = ref.read(attendanceRepositoryProvider);
      final result = await repo.getArchive();
      if (mounted) {
        setState(() {
          _archive = result.data;
          _archiveLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _archiveError = e.message;
          _archiveLoading = false;
        });
      }
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    try {
      final numbers = _numbersController.text
          .split(RegExp(r'[,\n\s]+'))
          .map((n) => n.trim())
          .where((n) => n.isNotEmpty)
          .toList();

      final repo = ref.read(attendanceRepositoryProvider);
      await repo.sendAttendance(
        senderId: 0,
        messageBody: _messageController.text.trim(),
        groupIds: [],
        numbers: numbers,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('attendanceSent')),
            backgroundColor: AppColors.success,
          ),
        );
        _messageController.clear();
        _numbersController.clear();
        _loadArchive();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('attendanceRecord')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.translate('sendTab')),
            Tab(text: AppLocalizations.of(context)!.translate('archiveTab')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendTab(),
          _buildArchiveTab(),
        ],
      ),
    );
  }

  Widget _buildSendTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.chartGreen, AppColors.chartTeal],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.fact_check_rounded, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.translate('attendanceRecord'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.translate('attendanceNotifications'),
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppTextField(
              label: AppLocalizations.of(context)!.translate('recipientNumbers'),
              hint: AppLocalizations.of(context)!.translate('enterNumbersSeparated'),
              controller: _numbersController,
              maxLines: 3,
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.trim().isEmpty
                  ? AppLocalizations.of(context)!.translate('enterNumbersValidation')
                  : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: AppLocalizations.of(context)!.translate('messageBody'),
              hint: AppLocalizations.of(context)!.translate('attendanceMessageHint'),
              controller: _messageController,
              maxLines: 4,
              validator: (v) => v == null || v.trim().isEmpty
                  ? AppLocalizations.of(context)!.translate('enterMessageBodyValidation')
                  : null,
            ),
            const SizedBox(height: 24),
            AppButton.primary(
              text: AppLocalizations.of(context)!.translate('sendRecords'),
              onPressed: _send,
              isLoading: _isSending,
              icon: Icons.send_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchiveTab() {
    if (_archiveLoading) return AppLoading.listShimmer();
    if (_archiveError != null) {
      return AppErrorWidget(message: _archiveError!, onRetry: _loadArchive);
    }
    if (_archive.isEmpty) {
      return AppEmptyState(
        icon: Icons.fact_check_outlined,
        title: AppLocalizations.of(context)!.translate('noRecords'),
      );
    }

    final dateFormat = intl.DateFormat('yyyy/MM/dd', 'ar');

    return RefreshIndicator(
      onRefresh: _loadArchive,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _archive.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final record = _archive[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _statusColor(record.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _statusIcon(record.status),
                    color: _statusColor(record.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.studentName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      Text(
                        '${record.studentPhone} \u2022 ${dateFormat.format(record.date)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                      ),
                      if (record.className != null)
                        Text(
                          record.className!,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(record.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.translate(record.statusKey),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(record.status),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'present' => AppColors.success,
      'absent' => AppColors.error,
      'late' => AppColors.warning,
      'excused' => AppColors.info,
      _ => AppColors.textSecondary,
    };
  }

  IconData _statusIcon(String status) {
    return switch (status) {
      'present' => Icons.check_circle_outline,
      'absent' => Icons.cancel_outlined,
      'late' => Icons.schedule_outlined,
      'excused' => Icons.info_outline,
      _ => Icons.help_outline,
    };
  }
}
