import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_app/features/auth/presentation/screens/login_screen.dart';
import 'package:orbit_app/features/auth/presentation/screens/register_screen.dart';
import 'package:orbit_app/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:orbit_app/features/auth/presentation/screens/two_factor_screen.dart';
import 'package:orbit_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:orbit_app/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:orbit_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:orbit_app/features/messages/presentation/screens/message_center_screen.dart';
import 'package:orbit_app/features/messages/presentation/screens/send_message_screen.dart';
import 'package:orbit_app/features/groups/presentation/screens/groups_screen.dart';
import 'package:orbit_app/features/groups/presentation/screens/group_detail_screen.dart';
import 'package:orbit_app/features/groups/presentation/screens/create_group_screen.dart';
import 'package:orbit_app/features/groups/presentation/screens/import_numbers_screen.dart';
import 'package:orbit_app/features/balance/presentation/screens/balance_screen.dart';
import 'package:orbit_app/features/balance/presentation/screens/buy_balance_screen.dart';
import 'package:orbit_app/features/balance/presentation/screens/transfer_balance_screen.dart';
import 'package:orbit_app/features/balance/presentation/screens/transactions_screen.dart';
import 'package:orbit_app/features/archive/presentation/screens/archive_screen.dart';
import 'package:orbit_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:orbit_app/features/settings/presentation/screens/profile_screen.dart';
import 'package:orbit_app/features/settings/presentation/screens/change_password_screen.dart';
import 'package:orbit_app/features/settings/presentation/screens/sub_accounts_screen.dart';
import 'package:orbit_app/features/settings/presentation/screens/roles_screen.dart';
import 'package:orbit_app/features/settings/presentation/screens/invoices_screen.dart';
import 'package:orbit_app/features/settings/presentation/screens/api_keys_screen.dart';
import 'package:orbit_app/features/settings/presentation/screens/sender_names_screen.dart';
import 'package:orbit_app/features/settings/presentation/screens/contracts_screen.dart';
import 'package:orbit_app/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:orbit_app/features/addons/presentation/screens/services_screen.dart';
import 'package:orbit_app/features/addons/presentation/screens/addon_detail_screen.dart';
import 'package:orbit_app/features/templates/presentation/screens/templates_screen.dart';
import 'package:orbit_app/features/short_links/presentation/screens/short_links_screen.dart';
import 'package:orbit_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:orbit_app/features/notifications/presentation/screens/send_notification_screen.dart';
import 'package:orbit_app/features/questionnaires/presentation/screens/questionnaires_screen.dart';
import 'package:orbit_app/features/occasion_cards/presentation/screens/occasion_cards_screen.dart';
import 'package:orbit_app/features/contact_me/presentation/screens/contact_me_screen.dart';
import 'package:orbit_app/features/interaction/presentation/screens/interaction_screen.dart';
import 'package:orbit_app/features/files/presentation/screens/files_screen.dart';
import 'package:orbit_app/features/certifications/presentation/screens/certifications_screen.dart';
import 'package:orbit_app/features/vip_cards/presentation/screens/vip_cards_screen.dart';
import 'package:orbit_app/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:orbit_app/features/noor_import/presentation/screens/noor_import_screen.dart';
import 'package:orbit_app/features/absence/presentation/screens/absence_messages_screen.dart';
import 'package:orbit_app/features/statements/presentation/screens/statements_screen.dart';
import 'package:orbit_app/shared/widgets/main_shell.dart';
import 'package:orbit_app/shared/widgets/payment_webview_screen.dart';
import 'package:orbit_app/shared/widgets/pdf_viewer_screen.dart';
import 'package:orbit_app/features/dashboard/presentation/screens/more_screen.dart';
import 'package:orbit_app/routing/route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Builds a [CustomTransitionPage] that slides in the given [direction].
CustomTransitionPage<void> _buildShellPage(
  GoRouterState state,
  Widget child,
  double direction,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (direction == 0.0) return child;
      final begin = Offset(direction, 0.0);
      final tween = Tween(begin: begin, end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeInOut));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      // Auth routes
      GoRoute(
        name: RouteNames.login,
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: RouteNames.register,
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        name: RouteNames.verifyOtp,
        path: '/verify-otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return VerifyOtpScreen(
            userId: extra['user_id'] as int? ?? 0,
          );
        },
      ),
      GoRoute(
        name: RouteNames.twoFactor,
        path: '/two-factor',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return TwoFactorScreen(
            verificationUuid: extra['verification_uuid'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        name: RouteNames.forgotPassword,
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        name: RouteNames.resetPassword,
        path: '/reset-password',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ResetPasswordScreen(
            token: extra['token'] as String? ?? '',
          );
        },
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            name: RouteNames.dashboard,
            path: '/',
            pageBuilder: (context, state) => _buildShellPage(
              state,
              const DashboardScreen(),
              ref.read(navSlideDirectionProvider),
            ),
          ),
          GoRoute(
            name: RouteNames.messageCenter,
            path: '/messages',
            pageBuilder: (context, state) => _buildShellPage(
              state,
              const MessageCenterScreen(),
              ref.read(navSlideDirectionProvider),
            ),
          ),
          GoRoute(
            name: RouteNames.groups,
            path: '/groups',
            pageBuilder: (context, state) => _buildShellPage(
              state,
              const GroupsScreen(),
              ref.read(navSlideDirectionProvider),
            ),
          ),
          GoRoute(
            name: RouteNames.balance,
            path: '/balance',
            pageBuilder: (context, state) => _buildShellPage(
              state,
              const BalanceScreen(),
              ref.read(navSlideDirectionProvider),
            ),
          ),
          GoRoute(
            name: RouteNames.more,
            path: '/more',
            pageBuilder: (context, state) => _buildShellPage(
              state,
              const MoreScreen(),
              ref.read(navSlideDirectionProvider),
            ),
          ),
        ],
      ),

      // Full-screen routes (outside shell)
      GoRoute(
        name: RouteNames.sendMessage,
        path: '/send-message',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SendMessageScreen(
            messageType: extra['message_type'] as String? ?? 'from_numbers',
          );
        },
      ),
      GoRoute(
        name: RouteNames.groupDetail,
        path: '/groups/:id',
        builder: (context, state) => GroupDetailScreen(
          groupId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        name: RouteNames.createGroup,
        path: '/create-group',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        name: RouteNames.importNumbers,
        path: '/import-numbers',
        builder: (context, state) => const ImportNumbersScreen(),
      ),
      GoRoute(
        name: RouteNames.buyBalance,
        path: '/buy-balance',
        builder: (context, state) => const BuyBalanceScreen(),
      ),
      GoRoute(
        name: RouteNames.transferBalance,
        path: '/transfer-balance',
        builder: (context, state) => const TransferBalanceScreen(),
      ),
      GoRoute(
        name: RouteNames.transactions,
        path: '/transactions',
        builder: (context, state) => const TransactionsScreen(),
      ),
      GoRoute(
        name: RouteNames.paymentWebView,
        path: '/payment-webview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PaymentWebViewScreen(
            url: extra['url'] as String? ?? '',
            title: extra['title'] as String? ?? '\u0627\u0644\u062F\u0641\u0639',
          );
        },
      ),
      GoRoute(
        name: RouteNames.termsPdf,
        path: '/terms-pdf',
        builder: (context, state) => const PdfViewerScreen(
          assetPath: 'assets/pdf/terms_of_use_corbit.pdf',
          title: '\u0633\u064A\u0627\u0633\u0629 \u0627\u0644\u0627\u0633\u062A\u062E\u062F\u0627\u0645', // سياسة الاستخدام
        ),
      ),
      GoRoute(
        name: RouteNames.archive,
        path: '/archive',
        builder: (context, state) => const ArchiveScreen(),
      ),
      GoRoute(
        name: RouteNames.settings,
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        name: RouteNames.profile,
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        name: RouteNames.changePassword,
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        name: RouteNames.subAccounts,
        path: '/sub-accounts',
        builder: (context, state) => const SubAccountsScreen(),
      ),
      GoRoute(
        name: RouteNames.roles,
        path: '/roles',
        builder: (context, state) => const RolesScreen(),
      ),
      GoRoute(
        name: RouteNames.invoices,
        path: '/invoices',
        builder: (context, state) => const InvoicesScreen(),
      ),
      GoRoute(
        name: RouteNames.apiKeys,
        path: '/api-keys',
        builder: (context, state) => const ApiKeysScreen(),
      ),
      GoRoute(
        name: RouteNames.senderNames,
        path: '/sender-names',
        builder: (context, state) => const SenderNamesScreen(),
      ),
      GoRoute(
        name: RouteNames.contracts,
        path: '/contracts',
        builder: (context, state) => const ContractsScreen(),
      ),
      GoRoute(
        name: RouteNames.statistics,
        path: '/statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        name: RouteNames.services,
        path: '/services',
        builder: (context, state) => const ServicesScreen(),
      ),
      GoRoute(
        name: RouteNames.addonDetail,
        path: '/addons/:id',
        builder: (context, state) => AddonDetailScreen(
          addonId: int.parse(state.pathParameters['id'] ?? '0'),
        ),
      ),
      GoRoute(
        name: RouteNames.templates,
        path: '/templates',
        builder: (context, state) => const TemplatesScreen(),
      ),
      GoRoute(
        name: RouteNames.shortLinks,
        path: '/short-links',
        builder: (context, state) => const ShortLinksScreen(),
      ),
      GoRoute(
        name: RouteNames.notifications,
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        name: RouteNames.sendNotification,
        path: '/send-notification',
        builder: (context, state) => const SendNotificationScreen(),
      ),
      GoRoute(
        name: RouteNames.questionnaires,
        path: '/questionnaires',
        builder: (context, state) => const QuestionnairesScreen(),
      ),
      GoRoute(
        name: RouteNames.occasionCards,
        path: '/occasion-cards',
        builder: (context, state) => const OccasionCardsScreen(),
      ),
      GoRoute(
        name: RouteNames.contactMe,
        path: '/contact-me',
        builder: (context, state) => const ContactMeScreen(),
      ),
      GoRoute(
        name: RouteNames.interaction,
        path: '/interaction',
        builder: (context, state) => const InteractionScreen(),
      ),
      GoRoute(
        name: RouteNames.files,
        path: '/files',
        builder: (context, state) => const FilesScreen(),
      ),
      GoRoute(
        name: RouteNames.certifications,
        path: '/certifications',
        builder: (context, state) => const CertificationsScreen(),
      ),
      GoRoute(
        name: RouteNames.vipCards,
        path: '/vip-cards',
        builder: (context, state) => const VipCardsScreen(),
      ),
      GoRoute(
        name: RouteNames.attendance,
        path: '/attendance',
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        name: RouteNames.noorImport,
        path: '/noor-import',
        builder: (context, state) => const NoorImportScreen(),
      ),
      GoRoute(
        name: RouteNames.absenceMessages,
        path: '/absence-messages',
        builder: (context, state) => const AbsenceMessagesScreen(),
      ),
      GoRoute(
        name: RouteNames.statements,
        path: '/statements',
        builder: (context, state) => const StatementsScreen(),
      ),
    ],
  );
});
