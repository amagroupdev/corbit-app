import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/interaction/data/models/interaction_model.dart';
import 'package:orbit_app/features/interaction/data/repositories/interaction_repository.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Screen for managing interaction (two-way SMS) with replies list
/// and send form.
class InteractionScreen extends ConsumerStatefulWidget {
  const InteractionScreen({super.key});

  @override
  ConsumerState<InteractionScreen> createState() => _InteractionScreenState();
}

class _InteractionScreenState extends ConsumerState<InteractionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Send form state
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _numbersController = TextEditingController();
  bool _isSending = false;

  // Replies state
  List<InteractionReply> _replies = [];
  bool _repliesLoading = true;
  String? _repliesError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReplies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _numbersController.dispose();
    super.dispose();
  }

  Future<void> _loadReplies() async {
    setState(() {
      _repliesLoading = true;
      _repliesError = null;
    });

    try {
      final repo = ref.read(interactionRepositoryProvider);
      final result = await repo.getReplies();
      if (mounted) {
        setState(() {
          _replies = result.data;
          _repliesLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _repliesError = e.message;
          _repliesLoading = false;
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

      final repo = ref.read(interactionRepositoryProvider);
      await repo.send(
        message: _messageController.text.trim(),
        senderId: 0,
        groupIds: [],
        numbers: numbers,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('\u062A\u0645 \u0627\u0644\u0625\u0631\u0633\u0627\u0644 \u0628\u0646\u062C\u0627\u062D'), // تم الإرسال بنجاح
            backgroundColor: AppColors.success,
          ),
        );
        _messageController.clear();
        _numbersController.clear();
        _loadReplies();
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
        title: const Text('\u0627\u0644\u062A\u0641\u0627\u0639\u0644'), // التفاعل
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: '\u0625\u0631\u0633\u0627\u0644'), // إرسال
            Tab(text: '\u0627\u0644\u0631\u062F\u0648\u062F'), // الردود
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendTab(),
          _buildRepliesTab(),
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
            AppTextField(
              label: '\u0623\u0631\u0642\u0627\u0645 \u0627\u0644\u0645\u0633\u062A\u0644\u0645\u064A\u0646', // أرقام المستلمين
              hint: '\u0623\u062F\u062E\u0644 \u0627\u0644\u0623\u0631\u0642\u0627\u0645 \u0645\u0641\u0635\u0648\u0644\u0629 \u0628\u0641\u0627\u0635\u0644\u0629', // أدخل الأرقام مفصولة بفاصلة
              controller: _numbersController,
              maxLines: 3,
              minLines: 2,
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.trim().isEmpty
                  ? '\u064A\u0631\u062C\u0649 \u0625\u062F\u062E\u0627\u0644 \u0631\u0642\u0645 \u0648\u0627\u062D\u062F \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644' // يرجى إدخال رقم واحد على الأقل
                  : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: '\u0646\u0635 \u0627\u0644\u0631\u0633\u0627\u0644\u0629', // نص الرسالة
              hint: '\u0623\u062F\u062E\u0644 \u0646\u0635 \u0631\u0633\u0627\u0644\u0629 \u0627\u0644\u062A\u0641\u0627\u0639\u0644', // أدخل نص رسالة التفاعل
              controller: _messageController,
              maxLines: 5,
              minLines: 3,
              validator: (v) => v == null || v.trim().isEmpty
                  ? '\u064A\u0631\u062C\u0649 \u0625\u062F\u062E\u0627\u0644 \u0646\u0635 \u0627\u0644\u0631\u0633\u0627\u0644\u0629' // يرجى إدخال نص الرسالة
                  : null,
            ),
            const SizedBox(height: 24),
            AppButton.primary(
              text: '\u0625\u0631\u0633\u0627\u0644', // إرسال
              onPressed: _send,
              isLoading: _isSending,
              icon: Icons.send_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepliesTab() {
    if (_repliesLoading) return AppLoading.listShimmer();
    if (_repliesError != null) {
      return AppErrorWidget(message: _repliesError!, onRetry: _loadReplies);
    }
    if (_replies.isEmpty) {
      return const AppEmptyState(
        icon: Icons.chat_bubble_outline,
        title: '\u0644\u0627 \u062A\u0648\u062C\u062F \u0631\u062F\u0648\u062F', // لا توجد ردود
        description: '\u0633\u062A\u0638\u0647\u0631 \u0647\u0646\u0627 \u0631\u062F\u0648\u062F \u0627\u0644\u0645\u0633\u062A\u0644\u0645\u064A\u0646', // ستظهر هنا ردود المستلمين
      );
    }

    final dateFormat = intl.DateFormat('yyyy/MM/dd HH:mm', 'ar');

    return RefreshIndicator(
      onRefresh: _loadReplies,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _replies.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final reply = _replies[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(reply.senderPhone, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const Spacer(),
                    Text(dateFormat.format(reply.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(reply.message, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          );
        },
      ),
    );
  }
}
