import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/vip_cards/data/models/vip_card_model.dart';
import 'package:orbit_app/features/vip_cards/data/repositories/vip_cards_repository.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_empty_state.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';
import 'package:orbit_app/shared/widgets/app_text_field.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';

/// Screen for sending and viewing VIP card messages.
class VipCardsScreen extends ConsumerStatefulWidget {
  const VipCardsScreen({super.key});

  @override
  ConsumerState<VipCardsScreen> createState() => _VipCardsScreenState();
}

class _VipCardsScreenState extends ConsumerState<VipCardsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Send form
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _numbersController = TextEditingController();
  bool _isSending = false;

  // Archive state
  List<VipCardModel> _archive = [];
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
      final repo = ref.read(vipCardsRepositoryProvider);
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

      final repo = ref.read(vipCardsRepositoryProvider);
      await repo.sendVipCards(
        senderId: 0,
        messageBody: _messageController.text.trim(),
        groupIds: [],
        numbers: numbers,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('vipCardsSent')),
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
        title: Text(AppLocalizations.of(context)!.translate('vipCards')),
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
                  colors: [AppColors.balancePurpleStart, AppColors.balancePurpleEnd],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.card_membership_rounded, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.translate('vipCards'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.translate('vipCardsDesc'),
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
              hint: AppLocalizations.of(context)!.translate('enterMessageHint'),
              controller: _messageController,
              maxLines: 4,
              validator: (v) => v == null || v.trim().isEmpty
                  ? AppLocalizations.of(context)!.translate('enterMessageBodyValidation')
                  : null,
            ),
            const SizedBox(height: 24),
            AppButton.primary(
              text: AppLocalizations.of(context)!.translate('sendCards'),
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
        icon: Icons.card_membership_outlined,
        title: AppLocalizations.of(context)!.translate('noVipCards'),
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
          final card = _archive[index];
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
                    gradient: const LinearGradient(colors: [AppColors.balancePurpleStart, AppColors.balancePurpleEnd]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.card_membership, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.recipientName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text('${card.recipientPhone} \u2022 ${dateFormat.format(card.createdAt)}', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                    ],
                  ),
                ),
                Text(card.cardNumber, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ],
            ),
          );
        },
      ),
    );
  }
}
