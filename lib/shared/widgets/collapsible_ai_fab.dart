import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_app/core/constants/app_colors.dart';

class CollapsibleAiFab extends StatefulWidget {
  const CollapsibleAiFab({super.key});

  @override
  State<CollapsibleAiFab> createState() => _CollapsibleAiFabState();
}

class _CollapsibleAiFabState extends State<CollapsibleAiFab> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final double rightOffset = _collapsed ? -24.0 : 16.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      right: rightOffset,
      bottom: 24,
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! > 100) {
              setState(() => _collapsed = true);
            } else if (details.primaryVelocity! < -100) {
              setState(() => _collapsed = false);
            }
          }
        },
        onTap: () {
          if (_collapsed) {
            setState(() => _collapsed = false);
          } else {
            context.push('/ai-assistant');
          }
        },
        onLongPress: () {
          setState(() => _collapsed = !_collapsed);
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
