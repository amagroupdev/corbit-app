import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:orbit_app/core/constants/app_colors.dart';

/// A collection of loading indicator widgets used throughout the ORBIT app.
///
/// Usage:
/// ```dart
/// AppLoading.circular()
/// AppLoading.fullScreen()
/// AppLoading.shimmer()
/// AppLoading.listShimmer()
/// ```
class AppLoading extends StatelessWidget {
  const AppLoading._({
    required this.variant,
    this.message,
    this.itemCount = 5,
    this.shimmerHeight = 80,
    this.shimmerWidth,
    super.key,
  });

  /// A centered circular progress indicator in the primary color.
  factory AppLoading.circular({String? message, Key? key}) {
    return AppLoading._(
      variant: _LoadingVariant.circular,
      message: message,
      key: key,
    );
  }

  /// A full-screen overlay with a semi-transparent backdrop and spinner.
  factory AppLoading.fullScreen({String? message, Key? key}) {
    return AppLoading._(
      variant: _LoadingVariant.fullScreen,
      message: message,
      key: key,
    );
  }

  /// A single shimmer placeholder block.
  factory AppLoading.shimmer({
    double height = 80,
    double? width,
    Key? key,
  }) {
    return AppLoading._(
      variant: _LoadingVariant.shimmer,
      shimmerHeight: height,
      shimmerWidth: width,
      key: key,
    );
  }

  /// Multiple shimmer card placeholders, ideal for list-loading states.
  factory AppLoading.listShimmer({
    int itemCount = 5,
    double itemHeight = 80,
    Key? key,
  }) {
    return AppLoading._(
      variant: _LoadingVariant.listShimmer,
      itemCount: itemCount,
      shimmerHeight: itemHeight,
      key: key,
    );
  }

  final _LoadingVariant variant;
  final String? message;
  final int itemCount;
  final double shimmerHeight;
  final double? shimmerWidth;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      _LoadingVariant.circular => _buildCircular(),
      _LoadingVariant.fullScreen => _buildFullScreen(),
      _LoadingVariant.shimmer => _buildShimmer(),
      _LoadingVariant.listShimmer => _buildListShimmer(),
    };
  }

  // ─── Circular ─────────────────────────────────────────────────

  Widget _buildCircular() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // ─── Full Screen ──────────────────────────────────────────────

  Widget _buildFullScreen() {
    return Container(
      color: AppColors.overlay,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: AppColors.dialogShadow,
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 20),
                Text(
                  message!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Shimmer ──────────────────────────────────────────────────

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        height: shimmerHeight,
        width: shimmerWidth ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ─── List Shimmer ─────────────────────────────────────────────

  Widget _buildListShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => _ShimmerCard(height: shimmerHeight),
      ),
    );
  }
}

// ─── Internal shimmer card ──────────────────────────────────────

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Text lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _LoadingVariant { circular, fullScreen, shimmer, listShimmer }
