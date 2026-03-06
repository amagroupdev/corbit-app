import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/contact_me/data/models/contact_me_model.dart';
import 'package:orbit_app/features/contact_me/data/repositories/contact_me_repository.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';

/// Screen for managing the Contact Me feature.
///
/// Includes settings toggle, root URL configuration, reasons CRUD,
/// and received messages list.
class ContactMeScreen extends ConsumerStatefulWidget {
  const ContactMeScreen({super.key});

  @override
  ConsumerState<ContactMeScreen> createState() => _ContactMeScreenState();
}

class _ContactMeScreenState extends ConsumerState<ContactMeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Settings state
  ContactMeSettings? _settings;
  bool _settingsLoading = true;
  String? _settingsError;
  bool _isSavingSettings = false;
  final _rootUrlController = TextEditingController();

  // Reasons state
  List<ContactMeReason> _reasons = [];
  bool _reasonsLoading = true;
  String? _reasonsError;

  // Messages state
  List<ContactMeMessage> _messages = [];
  bool _messagesLoading = true;
  String? _messagesError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettings();
    _loadReasons();
    _loadMessages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rootUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _settingsLoading = true;
      _settingsError = null;
    });

    try {
      final repo = ref.read(contactMeRepositoryProvider);
      final settings = await repo.getSettings();
      if (mounted) {
        setState(() {
          _settings = settings;
          _rootUrlController.text = settings.rootUrl;
          _settingsLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _settingsError = e.message;
          _settingsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _settingsError = e.toString();
          _settingsLoading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSavingSettings = true);
    try {
      final repo = ref.read(contactMeRepositoryProvider);
      final updated = await repo.updateSettings(
        isEnabled: _settings?.isEnabled ?? false,
        rootUrl: _rootUrlController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _settings = updated;
          _isSavingSettings = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('\u062A\u0645 \u062D\u0641\u0638 \u0627\u0644\u0625\u0639\u062F\u0627\u062F\u0627\u062A'), // تم حفظ الإعدادات
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isSavingSettings = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _loadReasons() async {
    setState(() {
      _reasonsLoading = true;
      _reasonsError = null;
    });

    try {
      final repo = ref.read(contactMeRepositoryProvider);
      final reasons = await repo.getReasons();
      if (mounted) {
        setState(() {
          _reasons = reasons;
          _reasonsLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _reasonsError = e.message;
          _reasonsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reasonsError = e.toString();
          _reasonsLoading = false;
        });
      }
    }
  }

  Future<void> _addReason() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('\u0625\u0636\u0627\u0641\u0629 \u0633\u0628\u0628', style: TextStyle(fontWeight: FontWeight.w600)), // إضافة سبب
        content: AppTextField(
          hint: '\u0639\u0646\u0648\u0627\u0646 \u0627\u0644\u0633\u0628\u0628', // عنوان السبب
          controller: controller,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('\u0625\u0644\u063A\u0627\u0621'), // إلغاء
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('\u0625\u0636\u0627\u0641\u0629'), // إضافة
          ),
        ],
      ),
    );

    controller.dispose();

    if (title != null && title.isNotEmpty) {
      try {
        final repo = ref.read(contactMeRepositoryProvider);
        await repo.createReason(title);
        _loadReasons();
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _deleteReason(ContactMeReason reason) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('\u062D\u0630\u0641 \u0627\u0644\u0633\u0628\u0628', style: TextStyle(fontWeight: FontWeight.w600)), // حذف السبب
        content: Text('\u0647\u0644 \u0623\u0646\u062A \u0645\u062A\u0623\u0643\u062F \u0645\u0646 \u062D\u0630\u0641 "${reason.title}"\u061F'), // هل أنت متأكد من حذف "..."؟
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('\u0625\u0644\u063A\u0627\u0621')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('\u062D\u0630\u0641'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(contactMeRepositoryProvider);
        await repo.deleteReason(reason.id);
        _loadReasons();
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _messagesLoading = true;
      _messagesError = null;
    });

    try {
      final repo = ref.read(contactMeRepositoryProvider);
      final result = await repo.getMessages();
      if (mounted) {
        setState(() {
          _messages = result.data;
          _messagesLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _messagesError = e.message;
          _messagesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messagesError = e.toString();
          _messagesLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('\u062A\u0648\u0627\u0635\u0644 \u0645\u0639\u064A'), // تواصل معي
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: '\u0627\u0644\u0625\u0639\u062F\u0627\u062F\u0627\u062A'), // الإعدادات
            Tab(text: '\u0627\u0644\u0623\u0633\u0628\u0627\u0628'), // الأسباب
            Tab(text: '\u0627\u0644\u0631\u0633\u0627\u0626\u0644'), // الرسائل
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSettingsTab(),
          _buildReasonsTab(),
          _buildMessagesTab(),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    if (_settingsLoading) return AppLoading.circular();
    if (_settingsError != null) {
      return AppErrorWidget(message: _settingsError!, onRetry: _loadSettings);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '\u062A\u0641\u0639\u064A\u0644 \u062E\u062F\u0645\u0629 \u062A\u0648\u0627\u0635\u0644 \u0645\u0639\u064A', // تفعيل خدمة تواصل معي
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                Switch(
                  value: _settings?.isEnabled ?? false,
                  onChanged: (val) {
                    setState(() {
                      _settings = ContactMeSettings(
                        isEnabled: val,
                        rootUrl: _settings?.rootUrl ?? '',
                      );
                    });
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: '\u0631\u0627\u0628\u0637 \u0627\u0644\u0635\u0641\u062D\u0629', // رابط الصفحة
            hint: 'my-company',
            controller: _rootUrlController,
          ),
          const SizedBox(height: 24),
          AppButton.primary(
            text: '\u062D\u0641\u0638 \u0627\u0644\u0625\u0639\u062F\u0627\u062F\u0627\u062A', // حفظ الإعدادات
            onPressed: _saveSettings,
            isLoading: _isSavingSettings,
            icon: Icons.save_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildReasonsTab() {
    if (_reasonsLoading) return AppLoading.listShimmer();
    if (_reasonsError != null) {
      return AppErrorWidget(message: _reasonsError!, onRetry: _loadReasons);
    }

    return Column(
      children: [
        Expanded(
          child: _reasons.isEmpty
              ? AppEmptyState(
                  icon: Icons.list_alt_outlined,
                  title: '\u0644\u0627 \u062A\u0648\u062C\u062F \u0623\u0633\u0628\u0627\u0628', // لا توجد أسباب
                  actionText: '\u0625\u0636\u0627\u0641\u0629 \u0633\u0628\u0628', // إضافة سبب
                  onAction: _addReason,
                )
              : RefreshIndicator(
                  onRefresh: _loadReasons,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reasons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final reason = _reasons[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 4, offset: Offset(0, 1))],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.label_outline, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(reason.title, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                              onPressed: () => _deleteReason(reason),
                              splashRadius: 20,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton.primary(
            text: '\u0625\u0636\u0627\u0641\u0629 \u0633\u0628\u0628', // إضافة سبب
            onPressed: _addReason,
            icon: Icons.add_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesTab() {
    if (_messagesLoading) return AppLoading.listShimmer();
    if (_messagesError != null) {
      return AppErrorWidget(message: _messagesError!, onRetry: _loadMessages);
    }
    if (_messages.isEmpty) {
      return const AppEmptyState(
        icon: Icons.message_outlined,
        title: '\u0644\u0627 \u062A\u0648\u062C\u062F \u0631\u0633\u0627\u0626\u0644', // لا توجد رسائل
        description: '\u0633\u062A\u0638\u0647\u0631 \u0647\u0646\u0627 \u0627\u0644\u0631\u0633\u0627\u0626\u0644 \u0627\u0644\u0648\u0627\u0631\u062F\u0629', // ستظهر هنا الرسائل الواردة
      );
    }

    final dateFormat = intl.DateFormat('yyyy/MM/dd HH:mm', 'ar');

    return RefreshIndicator(
      onRefresh: _loadMessages,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final msg = _messages[index];
          return Container(
            padding: const EdgeInsets.all(16),
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
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(msg.senderName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          Text(msg.senderPhone, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                        ],
                      ),
                    ),
                    Text(dateFormat.format(msg.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(4)),
                  child: Text(msg.reasonTitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.primary)),
                ),
                const SizedBox(height: 8),
                Text(msg.message, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          );
        },
      ),
    );
  }
}
