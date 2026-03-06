import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/noor_import/data/models/noor_import_model.dart';
import 'package:orbit_app/features/noor_import/data/repositories/noor_import_repository.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Screen for importing and sending messages via the Noor educational system.
///
/// Provides Noor login, student group selection, message composition,
/// and an archive list of previously sent Noor import messages.
class NoorImportScreen extends ConsumerStatefulWidget {
  const NoorImportScreen({super.key});

  @override
  ConsumerState<NoorImportScreen> createState() => _NoorImportScreenState();
}

class _NoorImportScreenState extends ConsumerState<NoorImportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Noor login state
  bool _isLoggedIn = false;
  bool _isLoggingIn = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Student groups state
  List<NoorStudentGroup> _studentGroups = [];
  final Set<int> _selectedGroupIds = {};
  bool _groupsLoading = false;

  // Send form
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  bool _isSending = false;

  // Archive state
  List<NoorImportModel> _archive = [];
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
    _usernameController.dispose();
    _passwordController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _noorLogin() async {
    if (_usernameController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('\u064A\u0631\u062C\u0649 \u0625\u062F\u062E\u0627\u0644 \u0628\u064A\u0627\u0646\u0627\u062A \u0627\u0644\u062F\u062E\u0648\u0644'), // يرجى إدخال بيانات الدخول
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      final repo = ref.read(noorImportRepositoryProvider);
      await repo.noorLogin(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _isLoggingIn = false;
        });
        _loadStudentGroups();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoggingIn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _loadStudentGroups() async {
    setState(() => _groupsLoading = true);

    try {
      final repo = ref.read(noorImportRepositoryProvider);
      final groups = await repo.getNoorStudentGroups();
      if (mounted) {
        setState(() {
          _studentGroups = groups;
          _groupsLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _groupsLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGroupIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('\u064A\u0631\u062C\u0649 \u0627\u062E\u062A\u064A\u0627\u0631 \u0645\u062C\u0645\u0648\u0639\u0629 \u0648\u0627\u062D\u062F\u0629 \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644'), // يرجى اختيار مجموعة واحدة على الأقل
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final repo = ref.read(noorImportRepositoryProvider);
      await repo.sendNoorImport(
        senderId: 0,
        messageBody: _messageController.text.trim(),
        groupIds: _selectedGroupIds.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('\u062A\u0645 \u0625\u0631\u0633\u0627\u0644 \u0631\u0633\u0627\u0626\u0644 \u0646\u0648\u0631 \u0628\u0646\u062C\u0627\u062D'), // تم إرسال رسائل نور بنجاح
            backgroundColor: AppColors.success,
          ),
        );
        _messageController.clear();
        _selectedGroupIds.clear();
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

  Future<void> _loadArchive() async {
    setState(() {
      _archiveLoading = true;
      _archiveError = null;
    });

    try {
      final repo = ref.read(noorImportRepositoryProvider);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('\u0631\u0633\u0627\u0626\u0644 \u0646\u0648\u0631'), // رسائل نور
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: '\u0625\u0631\u0633\u0627\u0644'), // إرسال
            Tab(text: '\u0627\u0644\u0623\u0631\u0634\u064A\u0641'), // الأرشيف
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
    if (!_isLoggedIn) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.chartIndigo, AppColors.chartBlue],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.school_rounded, size: 32, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062F\u062E\u0648\u0644 \u0644\u0646\u0638\u0627\u0645 \u0646\u0648\u0631', // تسجيل الدخول لنظام نور
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '\u0633\u062C\u0644 \u0627\u0644\u062F\u062E\u0648\u0644 \u0644\u0627\u0633\u062A\u064A\u0631\u0627\u062F \u0628\u064A\u0627\u0646\u0627\u062A \u0627\u0644\u0637\u0644\u0627\u0628', // سجل الدخول لاستيراد بيانات الطلاب
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: '\u0627\u0633\u0645 \u0627\u0644\u0645\u0633\u062A\u062E\u062F\u0645', // اسم المستخدم
                    hint: '\u0623\u062F\u062E\u0644 \u0627\u0633\u0645 \u0627\u0644\u0645\u0633\u062A\u062E\u062F\u0645 \u0641\u064A \u0646\u0648\u0631', // أدخل اسم المستخدم في نور
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631', // كلمة المرور
                    hint: '\u0623\u062F\u062E\u0644 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631', // أدخل كلمة المرور
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 20),
                  AppButton.primary(
                    text: '\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062F\u062E\u0648\u0644', // تسجيل الدخول
                    onPressed: _noorLogin,
                    isLoading: _isLoggingIn,
                    icon: Icons.login_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_groupsLoading) return AppLoading.circular();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connected status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.successBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '\u062A\u0645 \u0627\u0644\u0627\u062A\u0635\u0627\u0644 \u0628\u0646\u0638\u0627\u0645 \u0646\u0648\u0631', // تم الاتصال بنظام نور
                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Student groups selection
            const Text(
              '\u0627\u062E\u062A\u0631 \u0645\u062C\u0645\u0648\u0639\u0627\u062A \u0627\u0644\u0637\u0644\u0627\u0628', // اختر مجموعات الطلاب
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            if (_studentGroups.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    '\u0644\u0627 \u062A\u0648\u062C\u062F \u0645\u062C\u0645\u0648\u0639\u0627\u062A \u0645\u062A\u0627\u062D\u0629', // لا توجد مجموعات متاحة
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ..._studentGroups.map(
                (group) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (_selectedGroupIds.contains(group.id)) {
                            _selectedGroupIds.remove(group.id);
                          } else {
                            _selectedGroupIds.add(group.id);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _selectedGroupIds.contains(group.id)
                              ? AppColors.primarySurface
                              : AppColors.surface,
                          border: Border.all(
                            color: _selectedGroupIds.contains(group.id)
                                ? AppColors.primary
                                : AppColors.border,
                            width: _selectedGroupIds.contains(group.id) ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedGroupIds.contains(group.id)
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: _selectedGroupIds.contains(group.id)
                                  ? AppColors.primary
                                  : AppColors.textHint,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.name,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                  Text(
                                    '${group.studentCount} \u0637\u0627\u0644\u0628', // طالب
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (group.grade != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.infoSurface,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  group.grade!,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.info),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            AppTextField(
              label: '\u0646\u0635 \u0627\u0644\u0631\u0633\u0627\u0644\u0629', // نص الرسالة
              hint: '\u0623\u062F\u062E\u0644 \u0646\u0635 \u0627\u0644\u0631\u0633\u0627\u0644\u0629 \u0627\u0644\u0645\u0631\u0627\u062F \u0625\u0631\u0633\u0627\u0644\u0647\u0627', // أدخل نص الرسالة المراد إرسالها
              controller: _messageController,
              maxLines: 4,
              validator: (v) => v == null || v.trim().isEmpty
                  ? '\u064A\u0631\u062C\u0649 \u0625\u062F\u062E\u0627\u0644 \u0646\u0635 \u0627\u0644\u0631\u0633\u0627\u0644\u0629' // يرجى إدخال نص الرسالة
                  : null,
            ),
            const SizedBox(height: 24),

            AppButton.primary(
              text: '\u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0631\u0633\u0627\u0626\u0644', // إرسال الرسائل
              onPressed: _selectedGroupIds.isNotEmpty ? _send : null,
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
      return const AppEmptyState(
        icon: Icons.school_outlined,
        title: '\u0644\u0627 \u062A\u0648\u062C\u062F \u0631\u0633\u0627\u0626\u0644 \u0646\u0648\u0631', // لا توجد رسائل نور
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
                    gradient: const LinearGradient(colors: [AppColors.chartIndigo, AppColors.chartBlue]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.recipientName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      Text(
                        '${record.recipientPhone} \u2022 ${dateFormat.format(record.createdAt)}',
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
                    color: record.isSent ? AppColors.successSurface : AppColors.warningSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    record.isSent
                        ? '\u0645\u0631\u0633\u0644' // مرسل
                        : '\u0642\u064A\u062F \u0627\u0644\u0627\u0646\u062A\u0638\u0627\u0631', // قيد الانتظار
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: record.isSent ? AppColors.success : AppColors.warning,
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
}
