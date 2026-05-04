import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/features/banners/data/models/banner_model.dart';

/// Compact dismissible banner ad rendered at the top of a scrollable feed
/// (e.g. the dashboard). Displays a single banner; rotation through the
/// list is the caller's responsibility.
class BannerAdCard extends StatelessWidget {
  const BannerAdCard({
    super.key,
    required this.banner,
    this.onDismiss,
    this.height = 88,
  });

  final BannerModel banner;
  final VoidCallback? onDismiss;
  final double height;

  Future<void> _openLink() async {
    if (!banner.hasLink) return;
    final uri = Uri.tryParse(banner.linkUrl!.trim());
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: AppColors.surface,
        elevation: 0,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: banner.hasLink ? _openLink : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                    right: Radius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: banner.imageUrl,
                    width: height,
                    height: height,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: height,
                      height: height,
                      color: AppColors.surfaceVariant,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: height,
                      height: height,
                      color: AppColors.surfaceVariant,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner.title.isNotEmpty ? banner.title : ' ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (banner.hasLink) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 12,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                banner.linkUrl!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                    onPressed: onDismiss,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
