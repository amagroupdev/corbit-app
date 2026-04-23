import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:orbit_app/core/constants/app_colors.dart';
import 'package:orbit_app/core/constants/feature_flags.dart';
import 'package:orbit_app/core/localization/app_localizations.dart';
import 'package:orbit_app/core/storage/secure_storage.dart';
import 'package:orbit_app/shared/widgets/collapsible_ai_fab.dart';

/// Tracks the currently selected bottom navigation tab index.
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// Slide direction for the next bottom nav transition.
/// Positive = slide from right, negative = slide from left, 0 = no animation.
final navSlideDirectionProvider = StateProvider<double>((ref) => 0.0);

/// Main application shell that wraps the primary screens with a
/// persistent bottom navigation bar.
///
/// This widget is used inside a [ShellRoute] so that the child is
/// swapped while the bottom bar stays mounted.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _devTapCount = 0;
  DateTime? _lastDevTap;

  // Maps each tab index to its corresponding route path.
  static const List<String> _tabPaths = [
    '/',
    '/messages',
    '/groups',
    '/balance',
    '/more',
  ];

  /// Visible tab indices (filters out the Balance tab when the recharge
  /// feature is disabled). The internal logical indices in [_tabPaths]
  /// stay identical so existing code paths continue to map correctly.
  static final List<int> _visibleTabIndices = [
    0,
    1,
    2,
    if (kRechargeEnabled) 3,
    4,
  ];

  /// Determines the active tab index from the current route location.
  int _indexFromLocation(String location) {
    if (location.startsWith('/more')) return 4;
    if (location.startsWith('/balance')) return 3;
    if (location.startsWith('/groups')) return 2;
    if (location.startsWith('/messages')) return 1;
    return 0;
  }

  Future<void> _showDevToken() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.getToken();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🔧 Dev Token', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: SelectableText(
          token ?? 'No token',
          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
        ),
        actions: [
          if (token != null)
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: token));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Token copied'), duration: Duration(seconds: 2)),
                );
              },
              child: const Text('Copy'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    final currentIndex = ref.read(bottomNavIndexProvider);

    // Dev easter egg: 7 taps on "More" tab within 3 seconds
    if (index == 4 && currentIndex == 4) {
      final now = DateTime.now();
      if (_lastDevTap != null && now.difference(_lastDevTap!).inSeconds > 3) {
        _devTapCount = 0;
      }
      _lastDevTap = now;
      _devTapCount++;
      if (_devTapCount >= 7) {
        _devTapCount = 0;
        _showDevToken();
      }
      return;
    }

    if (index == currentIndex) {
      return;
    }

    // Calculate slide direction based on tab index difference.
    // In RTL layouts tabs are visually reversed, so flip the direction.
    double direction = index > currentIndex ? 1.0 : -1.0;
    if (Directionality.of(context) == TextDirection.rtl) {
      direction = -direction;
    }
    ref.read(navSlideDirectionProvider.notifier).state = direction;
    ref.read(bottomNavIndexProvider.notifier).state = index;
    context.go(_tabPaths[index]);
  }

  @override
  Widget build(BuildContext context) {
    // Derive the active index from the actual URL so deep links and
    // the Android back button stay in sync.
    final location =
        GoRouterState.of(context).uri.toString();
    final activeIndex = _indexFromLocation(location);

    // Keep the provider in sync when navigation is driven externally
    // (e.g. browser back button / deep links).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(bottomNavIndexProvider) != activeIndex) {
        final oldIndex = ref.read(bottomNavIndexProvider);
        double direction = activeIndex > oldIndex ? 1.0 : -1.0;
        if (Directionality.of(context) == TextDirection.rtl) {
          direction = -direction;
        }
        ref.read(navSlideDirectionProvider.notifier).state = direction;
        ref.read(bottomNavIndexProvider.notifier).state = activeIndex;
      }
    });

    return PopScope(
      canPop: activeIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Navigate back to the home tab instead of exiting the app.
          // Going to index 0 is always a lower index, so direction = -1.0 (flipped for RTL).
          double direction = -1.0;
          if (Directionality.of(context) == TextDirection.rtl) {
            direction = -direction;
          }
          ref.read(navSlideDirectionProvider.notifier).state = direction;
          ref.read(bottomNavIndexProvider.notifier).state = 0;
          context.go(_tabPaths[0]);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            widget.child,
            const CollapsibleAiFab(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 64,
              child: Row(
                children: _visibleTabIndices.map((index) {
                  final isActive = activeIndex == index;
                  return Expanded(
                    child: _BottomNavItem(
                      icon: _iconForIndex(index),
                      activeIcon: _activeIconForIndex(index),
                      label: _labelForIndex(index),
                      isActive: isActive,
                      onTap: () => _onTabTapped(index),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Icon helpers ────────────────────────────────────────────────

  IconData _iconForIndex(int index) {
    return switch (index) {
      0 => Icons.dashboard_outlined,
      1 => Icons.mail_outlined,
      2 => Icons.people_outlined,
      3 => Icons.account_balance_wallet_outlined,
      4 => Icons.more_horiz_outlined,
      _ => Icons.circle_outlined,
    };
  }

  IconData _activeIconForIndex(int index) {
    return switch (index) {
      0 => Icons.dashboard,
      1 => Icons.mail,
      2 => Icons.people,
      3 => Icons.account_balance_wallet,
      4 => Icons.more_horiz,
      _ => Icons.circle,
    };
  }

  String _labelForIndex(int index) {
    final t = AppLocalizations.instance;
    return switch (index) {
      0 => t.translate('navHome'),
      1 => t.translate('navMessages'),
      2 => t.translate('navGroups'),
      3 => t.translate('navBalance'),
      4 => t.translate('navMore'),
      _ => '',
    };
  }
}

// ─── Bottom Navigation Item ──────────────────────────────────────

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? AppColors.bottomNavActive : AppColors.bottomNavInactive;

    return InkWell(
      onTap: onTap,
      splashColor: AppColors.primarySurface,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
