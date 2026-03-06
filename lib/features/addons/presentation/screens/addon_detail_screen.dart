import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/network/api_exceptions.dart';
import 'package:orbit_app/features/addons/data/models/addon_model.dart';
import 'package:orbit_app/features/addons/data/models/subscription_plan_model.dart';
import 'package:orbit_app/features/addons/data/repositories/addons_repository.dart';
import 'package:orbit_app/shared/widgets/app_button.dart';
import 'package:orbit_app/shared/widgets/app_error_widget.dart';
import 'package:orbit_app/shared/widgets/app_loading.dart';

/// Detail screen for a single addon/service.
///
/// Shows the banner image, full description, subscription plans,
/// and action buttons to activate a trial or purchase.
class AddonDetailScreen extends ConsumerStatefulWidget {
  const AddonDetailScreen({required this.addonId, super.key});

  final int addonId;

  @override
  ConsumerState<AddonDetailScreen> createState() => _AddonDetailScreenState();
}

class _AddonDetailScreenState extends ConsumerState<AddonDetailScreen> {
  AddonModel? _addon;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isActivating = false;
  int? _selectedPlanId;

  @override
  void initState() {
    super.initState();
    _loadAddon();
  }

  Future<void> _loadAddon() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(addonsRepositoryProvider);
      final addon = await repository.getAddon(widget.addonId);

      if (mounted) {
        setState(() {
          _addon = addon;
          _isLoading = false;
          if (addon.subscriptionPlans.isNotEmpty) {
            _selectedPlanId = addon.subscriptionPlans.first.id;
          }
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

  Future<void> _activateTrial() async {
    setState(() => _isActivating = true);

    try {
      final repository = ref.read(addonsRepositoryProvider);
      await repository.activateTrial(widget.addonId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '\u062A\u0645 \u062A\u0641\u0639\u064A\u0644 \u0627\u0644\u0641\u062A\u0631\u0629 \u0627\u0644\u062A\u062C\u0631\u064A\u0628\u064A\u0629 \u0628\u0646\u062C\u0627\u062D', // تم تفعيل الفترة التجريبية بنجاح
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _loadAddon();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActivating = false);
      }
    }
  }

  Future<void> _initiatePayment() async {
    if (_selectedPlanId == null) return;

    setState(() => _isActivating = true);

    try {
      final repository = ref.read(addonsRepositoryProvider);
      final result = await repository.initiatePayment(
        addonId: widget.addonId,
        planId: _selectedPlanId!,
      );

      if (mounted) {
        final paymentUrl = result['payment_url'] as String?;
        if (paymentUrl != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '\u062C\u0627\u0631\u064A \u0627\u0644\u062A\u0648\u062C\u064A\u0647 \u0644\u0635\u0641\u062D\u0629 \u0627\u0644\u062F\u0641\u0639', // جاري التوجيه لصفحة الدفع
              ),
              backgroundColor: AppColors.info,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '\u062A\u0645 \u0627\u0644\u0627\u0634\u062A\u0631\u0627\u0643 \u0628\u0646\u062C\u0627\u062D', // تم الاشتراك بنجاح
              ),
              backgroundColor: AppColors.success,
            ),
          );
          _loadAddon();
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActivating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_addon?.name ?? '\u062A\u0641\u0627\u0635\u064A\u0644 \u0627\u0644\u062E\u062F\u0645\u0629'), // تفاصيل الخدمة
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return AppLoading.circular();
    }

    if (_errorMessage != null) {
      return AppErrorWidget(
        message: _errorMessage!,
        onRetry: _loadAddon,
      );
    }

    final addon = _addon!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Banner ──────────────────────────────────────
          if (addon.bannerUrl != null)
            Image.network(
              addon.bannerUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primary],
                  ),
                ),
                child: const Icon(
                  Icons.extension_outlined,
                  size: 64,
                  color: Colors.white38,
                ),
              ),
            )
          else
            Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryLight, AppColors.primary],
                ),
              ),
              child: const Icon(
                Icons.extension_outlined,
                size: 64,
                color: Colors.white38,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title and status ────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        addon.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (addon.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.successSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '\u0645\u0641\u0639\u0644', // مفعل
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Description ─────────────────────────────
                Text(
                  addon.description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Subscription Plans ──────────────────────
                if (addon.subscriptionPlans.isNotEmpty && !addon.isActive) ...[
                  const Text(
                    '\u062E\u0637\u0637 \u0627\u0644\u0627\u0634\u062A\u0631\u0627\u0643', // خطط الاشتراك
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...addon.subscriptionPlans.map(
                    (plan) => _PlanTile(
                      plan: plan,
                      isSelected: _selectedPlanId == plan.id,
                      onTap: () =>
                          setState(() => _selectedPlanId = plan.id),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Action buttons ──────────────────────────
                if (!addon.isActive && !addon.isComingSoon) ...[
                  if (addon.subscriptionPlans.any((p) => p.hasTrial))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppButton.secondary(
                        text: '\u062A\u0641\u0639\u064A\u0644 \u0627\u0644\u0641\u062A\u0631\u0629 \u0627\u0644\u062A\u062C\u0631\u064A\u0628\u064A\u0629', // تفعيل الفترة التجريبية
                        onPressed: _activateTrial,
                        isLoading: _isActivating,
                        icon: Icons.play_circle_outline_rounded,
                      ),
                    ),
                  if (!addon.isFree)
                    AppButton.primary(
                      text: '\u0627\u0634\u062A\u0631\u0643 \u0627\u0644\u0622\u0646', // اشترك الآن
                      onPressed: _selectedPlanId != null
                          ? _initiatePayment
                          : null,
                      isLoading: _isActivating,
                      icon: Icons.shopping_cart_outlined,
                    ),
                ],

                if (addon.isComingSoon)
                  AppButton.secondary(
                    text: '\u0642\u0631\u064A\u0628\u0627\u064B', // قريباً
                    onPressed: null,
                    isDisabled: true,
                    icon: Icons.schedule_rounded,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  final SubscriptionPlanModel plan;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primarySurface : AppColors.surface,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.durationLabel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (plan.hasTrial)
                        Text(
                          '${plan.trialDays} \u064A\u0648\u0645 \u062A\u062C\u0631\u064A\u0628\u064A', // يوم تجريبي
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${plan.price.toStringAsFixed(0)} \u0631.\u0633', // ر.س
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
