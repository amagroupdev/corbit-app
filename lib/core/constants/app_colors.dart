import 'package:flutter/material.dart';

/// All application colors extracted from the ORBIT SMS V3 portal design.
///
/// Usage:
/// ```dart
/// Container(color: AppColors.primary)
/// ```
abstract final class AppColors {
  // ──────────────────────────────────────────────
  // Brand / Primary
  // ──────────────────────────────────────────────
  static const Color primary = Color(0xFFDF6235);
  static const Color primaryDark = Color(0xFFC54E20);
  static const Color primaryLight = Color(0xFFF5845C);
  static const Color primarySurface = Color(0xFFFEF3EE);
  static const Color primaryBorder = Color(0xFFFDD8C8);

  // ──────────────────────────────────────────────
  // Secondary (Dark sidebar / navigation)
  // ──────────────────────────────────────────────
  static const Color secondary = Color(0xFF1E1E2D);
  static const Color secondaryDark = Color(0xFF151521);
  static const Color secondaryLight = Color(0xFF2D2D3F);
  static const Color secondarySurface = Color(0xFF3F4254);

  // ──────────────────────────────────────────────
  // Background & Surface
  // ──────────────────────────────────────────────
  static const Color background = Color(0xFFF9F9FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F8);
  static const Color scaffoldBackground = Color(0xFFF9F9FB);

  // ──────────────────────────────────────────────
  // Semantic / Status
  // ──────────────────────────────────────────────
  static const Color error = Color(0xFFE53935);
  static const Color errorDark = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color errorSurface = Color(0xFFFDECEC);
  static const Color errorBorder = Color(0xFFF5C6C6);

  static const Color success = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF388E3C);
  static const Color successLight = Color(0xFF66BB6A);
  static const Color successSurface = Color(0xFFEDF7ED);
  static const Color successBorder = Color(0xFFC8E6C9);

  static const Color warning = Color(0xFFFF9800);
  static const Color warningDark = Color(0xFFE65100);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningSurface = Color(0xFFFFF4E5);
  static const Color warningBorder = Color(0xFFFFE0B2);

  static const Color info = Color(0xFF2196F3);
  static const Color infoDark = Color(0xFF1565C0);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoSurface = Color(0xFFE8F4FD);
  static const Color infoBorder = Color(0xFFBBDEFB);

  // ──────────────────────────────────────────────
  // Text
  // ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1E1E2D);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  static const Color textOnSurface = Color(0xFF1E1E2D);
  static const Color textLink = Color(0xFFDF6235);

  // ──────────────────────────────────────────────
  // Border & Divider
  // ──────────────────────────────────────────────
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color borderDark = Color(0xFFD1D5DB);
  static const Color borderFocused = Color(0xFFDF6235);
  static const Color divider = Color(0xFFF3F4F6);

  // ──────────────────────────────────────────────
  // Shadows
  // ──────────────────────────────────────────────
  static const Color cardShadow = Color(0x0D000000);
  static const Color dropShadow = Color(0x1A000000);
  static const Color dialogShadow = Color(0x33000000);

  // ──────────────────────────────────────────────
  // Message Status Colors
  // ──────────────────────────────────────────────
  static const Color messageSent = Color(0xFF2196F3);
  static const Color messageDelivered = Color(0xFF4CAF50);
  static const Color messageFailed = Color(0xFFE53935);
  static const Color messagePending = Color(0xFFFF9800);
  static const Color messageRejected = Color(0xFF9E9E9E);
  static const Color messageScheduled = Color(0xFF7C4DFF);
  static const Color messageExpired = Color(0xFF795548);

  // ──────────────────────────────────────────────
  // Balance Card Gradient Colors
  // ──────────────────────────────────────────────
  // Teal card (SMS balance)
  static const Color balanceTealStart = Color(0xFF009688);
  static const Color balanceTealEnd = Color(0xFF00796B);

  // Green card (available balance)
  static const Color balanceGreenStart = Color(0xFF4CAF50);
  static const Color balanceGreenEnd = Color(0xFF388E3C);

  // Blue card (sent messages)
  static const Color balanceBlueStart = Color(0xFF2196F3);
  static const Color balanceBlueEnd = Color(0xFF1565C0);

  // Orange card (primary branded)
  static const Color balanceOrangeStart = Color(0xFFDF6235);
  static const Color balanceOrangeEnd = Color(0xFFC54E20);

  // Purple card (addons)
  static const Color balancePurpleStart = Color(0xFF7C4DFF);
  static const Color balancePurpleEnd = Color(0xFF651FFF);

  // ──────────────────────────────────────────────
  // Sidebar / Navigation
  // ──────────────────────────────────────────────
  static const Color sidebarBackground = Color(0xFF1E1E2D);
  static const Color sidebarItemActive = Color(0xFFDF6235);
  static const Color sidebarItemHover = Color(0xFF2D2D3F);
  static const Color sidebarText = Color(0xFF9899AC);
  static const Color sidebarTextActive = Color(0xFFFFFFFF);
  static const Color sidebarDivider = Color(0xFF2D2D3F);

  // ──────────────────────────────────────────────
  // Bottom Navigation
  // ──────────────────────────────────────────────
  static const Color bottomNavBackground = Color(0xFFFFFFFF);
  static const Color bottomNavActive = Color(0xFFDF6235);
  static const Color bottomNavInactive = Color(0xFF9CA3AF);

  // ──────────────────────────────────────────────
  // Charts & Analytics
  // ──────────────────────────────────────────────
  static const Color chartBlue = Color(0xFF2196F3);
  static const Color chartGreen = Color(0xFF4CAF50);
  static const Color chartOrange = Color(0xFFFF9800);
  static const Color chartRed = Color(0xFFE53935);
  static const Color chartPurple = Color(0xFF9C27B0);
  static const Color chartTeal = Color(0xFF009688);
  static const Color chartPink = Color(0xFFE91E63);
  static const Color chartIndigo = Color(0xFF3F51B5);

  // ──────────────────────────────────────────────
  // Shimmer / Loading
  // ──────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // ──────────────────────────────────────────────
  // Overlay / Scrim
  // ──────────────────────────────────────────────
  static const Color overlay = Color(0x80000000);
  static const Color scrim = Color(0x52000000);
  static const Color barrierColor = Color(0x80000000);

  // ──────────────────────────────────────────────
  // Input Fields
  // ──────────────────────────────────────────────
  static const Color inputFill = Color(0xFFF9F9FB);
  static const Color inputBorder = Color(0xFFE5E7EB);
  static const Color inputBorderFocused = Color(0xFFDF6235);
  static const Color inputBorderError = Color(0xFFE53935);
  static const Color inputBorderDisabled = Color(0xFFE0E0E0);
  static const Color inputLabel = Color(0xFF6B7280);
  static const Color inputHint = Color(0xFF9CA3AF);

  // ──────────────────────────────────────────────
  // Tags / Badges
  // ──────────────────────────────────────────────
  static const Color badgePrimary = Color(0xFFDF6235);
  static const Color badgeSuccess = Color(0xFF4CAF50);
  static const Color badgeWarning = Color(0xFFFF9800);
  static const Color badgeError = Color(0xFFE53935);
  static const Color badgeInfo = Color(0xFF2196F3);
  static const Color badgeNeutral = Color(0xFF9E9E9E);

  // ──────────────────────────────────────────────
  // Dark Theme Colors
  // ──────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E2D);
  static const Color darkSurfaceVariant = Color(0xFF2D2D3F);
  static const Color darkBorder = Color(0xFF3F4254);
  static const Color darkDivider = Color(0xFF2D2D3F);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);
  static const Color darkTextHint = Color(0xFF757575);
  static const Color darkCardShadow = Color(0x33000000);
  static const Color darkInputFill = Color(0xFF2D2D3F);
  static const Color darkInputBorder = Color(0xFF3F4254);

  // ──────────────────────────────────────────────
  // Utility: MaterialColor swatch for primary
  // ──────────────────────────────────────────────
  static const MaterialColor primarySwatch = MaterialColor(
    0xFFDF6235,
    <int, Color>{
      50: Color(0xFFFBE9E2),
      100: Color(0xFFF5C8B6),
      200: Color(0xFFEFA487),
      300: Color(0xFFE97F57),
      400: Color(0xFFE46333),
      500: Color(0xFFDF6235),
      600: Color(0xFFD35A2F),
      700: Color(0xFFC54E20),
      800: Color(0xFFB74418),
      900: Color(0xFF9C3308),
    },
  );

  /// Returns the appropriate color for a given message status string.
  static Color messageStatusColor(String status) {
    return switch (status.toLowerCase()) {
      'sent' => messageSent,
      'delivered' => messageDelivered,
      'failed' => messageFailed,
      'pending' => messagePending,
      'rejected' => messageRejected,
      'scheduled' => messageScheduled,
      'expired' => messageExpired,
      _ => textSecondary,
    };
  }

  /// Returns the appropriate surface color for a given message status string.
  static Color messageStatusSurfaceColor(String status) {
    return switch (status.toLowerCase()) {
      'sent' => infoSurface,
      'delivered' => successSurface,
      'failed' => errorSurface,
      'pending' => warningSurface,
      'rejected' => Color(0xFFF5F5F5),
      'scheduled' => Color(0xFFF3EEFF),
      'expired' => Color(0xFFEFEBE9),
      _ => surfaceVariant,
    };
  }

  /// Returns a gradient for balance cards by type key.
  static LinearGradient balanceGradient(String type) {
    return switch (type) {
      'teal' => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [balanceTealStart, balanceTealEnd],
        ),
      'green' => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [balanceGreenStart, balanceGreenEnd],
        ),
      'blue' => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [balanceBlueStart, balanceBlueEnd],
        ),
      'orange' => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [balanceOrangeStart, balanceOrangeEnd],
        ),
      'purple' => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [balancePurpleStart, balancePurpleEnd],
        ),
      _ => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [balanceOrangeStart, balanceOrangeEnd],
        ),
    };
  }
}
