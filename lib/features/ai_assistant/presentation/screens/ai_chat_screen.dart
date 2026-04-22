import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/app_theme.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';

class AiChatScreen extends ConsumerWidget {
  const AiChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final isArabic = t?.isRtl ?? true;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primarySurface,
              child: const Icon(
                Icons.smart_toy_outlined,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              isArabic ? 'مساعد Corbit الذكي' : 'Corbit Smart Assistant',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppTheme.spacingXl),
            _Hero(isArabic: isArabic),
            const SizedBox(height: AppTheme.spacingXl),
            _DescriptionCard(isArabic: isArabic),
            const SizedBox(height: AppTheme.spacingLg),
            _FeaturesCard(isArabic: isArabic),
            const SizedBox(height: AppTheme.spacingXl),
            _NotifyButton(isArabic: isArabic),
            const SizedBox(height: AppTheme.spacingLg),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.isArabic});
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 56,
          ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.primaryBorder),
          ),
          child: Text(
            isArabic ? 'قريباً' : 'Coming Soon',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          isArabic ? 'مساعد Corbit الذكي' : 'Corbit Smart Assistant',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          isArabic
              ? 'مساعدك الذكي داخل التطبيق — يفهمك، يساعدك، ويختصر وقتك'
              : 'Your in-app smart assistant — understands you, helps you, saves your time',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.isArabic});
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                isArabic ? 'وش يسوي لك؟' : 'What can it do?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            isArabic
                ? 'مساعد ذكي مدمج في تطبيق Corbit يساعدك تدير حملاتك بشكل أسرع وأذكى. يفهم طلباتك بالعربي والإنجليزي، ويقدر يجاوب على أسئلتك عن الرصيد والإحصائيات والقوالب، ويرشدك لأي صفحة في التطبيق بضغطة، ويساعدك تكتب رسائل احترافية بدقائق.'
                : 'A smart assistant embedded in the Corbit app to help you manage your campaigns faster and smarter. It understands Arabic and English, answers your questions about balance, statistics, and templates, navigates you to any screen in the app, and helps you craft professional messages in minutes.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.7,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesCard extends StatelessWidget {
  const _FeaturesCard({required this.isArabic});
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final features = isArabic
        ? const [
            _Feature(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'محادثة طبيعية',
              subtitle: 'اسأل بلغتك الطبيعية واحصل على إجابات فورية',
            ),
            _Feature(
              icon: Icons.edit_note_rounded,
              title: 'كتابة رسائل احترافية',
              subtitle: 'اكتب لك قوالب SMS جاهزة مخصصة لجمهورك',
            ),
            _Feature(
              icon: Icons.insights_rounded,
              title: 'تحليل الإحصائيات',
              subtitle: 'يلخّص لك أداء حملاتك ويقترح تحسينات',
            ),
            _Feature(
              icon: Icons.explore_outlined,
              title: 'تنقل ذكي',
              subtitle: 'يوديك لأي صفحة بالتطبيق بدون ما تدور',
            ),
            _Feature(
              icon: Icons.account_balance_wallet_outlined,
              title: 'إدارة الرصيد',
              subtitle: 'يخبرك بحالة رصيدك ويذكّرك قبل النفاد',
            ),
            _Feature(
              icon: Icons.shield_outlined,
              title: 'خصوصية تامة',
              subtitle: 'بياناتك محمية ومشفّرة، ما تطلع من جهازك',
            ),
          ]
        : const [
            _Feature(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Natural Conversation',
              subtitle: 'Ask in your own words and get instant answers',
            ),
            _Feature(
              icon: Icons.edit_note_rounded,
              title: 'Professional Drafting',
              subtitle: 'Generates SMS templates tailored to your audience',
            ),
            _Feature(
              icon: Icons.insights_rounded,
              title: 'Statistics Insights',
              subtitle: 'Summarizes campaign performance and suggests fixes',
            ),
            _Feature(
              icon: Icons.explore_outlined,
              title: 'Smart Navigation',
              subtitle: 'Jumps you to any screen without searching',
            ),
            _Feature(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Balance Management',
              subtitle: 'Reports your balance and warns before it runs out',
            ),
            _Feature(
              icon: Icons.shield_outlined,
              title: 'Full Privacy',
              subtitle: 'Your data stays encrypted and never leaves your device',
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star_outline_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                isArabic ? 'المميزات' : 'Features',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
              child: _FeatureTile(feature: f),
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature {
  const _Feature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature});
  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(feature.icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feature.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                feature.subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotifyButton extends StatelessWidget {
  const _NotifyButton({required this.isArabic});
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              content: Text(
                isArabic
                    ? 'بنخبرك أول ما يصير جاهز!'
                    : "We'll let you know once it's ready!",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
        icon: const Icon(Icons.notifications_active_outlined, size: 20),
        label: Text(
          isArabic ? 'نبّهني عند الإطلاق' : 'Notify me on launch',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
