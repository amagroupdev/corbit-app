/// All API endpoint constants for ORBIT SMS V3.
///
/// Endpoints are organized by feature module. All paths are relative
/// to [baseUrl]. Use [ApiConstants.url] helper to build full URLs.
///
/// Usage:
/// ```dart
/// final url = ApiConstants.url(ApiConstants.login);
/// // => "https://api.orbitsms.com/api/v1/auth/login"
/// ```
abstract final class ApiConstants {
  // ──────────────────────────────────────────────
  // Base Configuration
  // ──────────────────────────────────────────────
  static const String stagingBaseUrl = 'https://staging.mobile.net.sa';
  static const String productionBaseUrl = 'https://app.mobile.net.sa';

  /// Toggle between staging and production.
  /// In a real app this would come from an environment config / flavor.
  static const bool isProduction = true;

  static String get baseUrl => '${isProduction ? productionBaseUrl : stagingBaseUrl}/api/v3';

  /// Builds a full URL from a relative [path].
  static String url(String path) => '$baseUrl$path';

  // ──────────────────────────────────────────────
  // Timeouts (milliseconds)
  // ──────────────────────────────────────────────
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  // ──────────────────────────────────────────────
  // Headers
  // ──────────────────────────────────────────────
  static const String headerAccept = 'application/json';
  static const String headerContentType = 'application/json';
  static const String headerAcceptLanguageAr = 'ar';
  static const String headerAcceptLanguageEn = 'en';
  static const String headerAuthorization = 'Authorization';
  static const String headerBearerPrefix = 'Bearer ';

  // ══════════════════════════════════════════════
  //  AUTH
  // ══════════════════════════════════════════════
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verify2fa = '/auth/verify-2fa';
  static const String verifyPhone = '/auth/verify-phone';
  static const String resendOtp = '/auth/resend-otp';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // ══════════════════════════════════════════════
  //  COMMON / LOOKUP
  // ══════════════════════════════════════════════
  static const String organizationTypes = '/common/organization-types';
  static const String regions = '/common/regions';
  static const String cities = '/common/cities';
  static const String checkEmail = '/common/check-email';
  static const String checkUsername = '/common/check-username';
  static const String checkPhone = '/common/check-phone';

  // ══════════════════════════════════════════════
  //  DASHBOARD
  // ══════════════════════════════════════════════
  static const String dashboard = '/dashboard';
  static const String dashboardBanners = '/dashboard/banners';
  static const String profile = '/settings/profile';

  // ══════════════════════════════════════════════
  //  MESSAGES
  // ══════════════════════════════════════════════
  static const String messagesSend = '/messages/send';
  static const String messagesPreview = '/messages/preview';
  static const String messagesCalculateSmsCount = '/messages/calculate-sms-count';
  static const String messagesValidateBlockedLinks = '/messages/validate-blocked-links';
  static const String messagesCheckDuplicate = '/messages/check-duplicate';

  // ══════════════════════════════════════════════
  //  TEMPLATES
  // ══════════════════════════════════════════════
  static const String templates = '/templates';

  /// GET /templates/{id}
  static String templateShow(dynamic id) => '/templates/$id';

  /// PUT /templates/{id}
  static String templateUpdate(dynamic id) => '/templates/$id';

  /// DELETE /templates/{id}
  static String templateDelete(dynamic id) => '/templates/$id';

  // ══════════════════════════════════════════════
  //  SENDERS
  // ══════════════════════════════════════════════
  static const String senders = '/senders';
  static const String sendersValidate = '/senders/validate';

  // ══════════════════════════════════════════════
  //  GROUPS (Contact Groups)
  // ══════════════════════════════════════════════
  static const String groups = '/groups';

  static String groupShow(dynamic id) => '/groups/$id';
  static String groupUpdate(dynamic id) => '/groups/$id';
  static String groupDelete(dynamic id) => '/groups/$id';
  static String groupRestore(dynamic id) => '/groups/$id/restore';
  static String groupNumbers(dynamic id) => '/groups/$id/numbers';
  static String groupNumbersCount(dynamic id) => '/groups/$id/numbers-count';
  static String groupImportExcel(dynamic id) => '/groups/$id/import-excel';
  static String groupImportCustomExcel(dynamic id) => '/groups/$id/import-custom-excel';
  static String groupImportFailedNumbers(dynamic id) => '/groups/$id/import-failed-numbers';
  static String groupExport(dynamic id) => '/groups/$id/export';
  static String groupExportDownload(dynamic id) => '/groups/$id/export-download';

  // ══════════════════════════════════════════════
  //  NUMBERS (within groups)
  // ══════════════════════════════════════════════
  static const String numbersValidate = '/numbers/validate';
  static const String numbers = '/numbers';

  static String numberUpdate(dynamic id) => '/numbers/$id';
  static String numberDelete(dynamic id) => '/numbers/$id';

  // ══════════════════════════════════════════════
  //  ARCHIVE (Message History)
  // ══════════════════════════════════════════════
  static const String archive = '/archive';
  static const String archiveCount = '/archive/count';
  static const String archiveDelete = '/archive/delete';
  static const String archiveExport = '/archive/export';
  static const String archivePrint = '/archive/print';
  static const String archiveCancelPending = '/archive/cancel-pending';
  static const String archiveAdd = '/archive/add';
  static const String archiveRestore = '/archive/restore';

  // ══════════════════════════════════════════════
  //  BALANCE
  // ══════════════════════════════════════════════
  static const String balanceCurrent = '/balance/current';
  static const String balanceSummary = '/balance/summary';
  static const String balancePrices = '/balance/prices';
  static const String balanceBanks = '/balance/banks';
  static const String balanceOffers = '/balance/offers';
  static const String balanceTransactions = '/balance/transactions';
  static const String balanceTransactionsExport = '/balance/transactions/export';
  static const String balanceUpgrades = '/balance/upgrades';
  static const String balancePurchaseCalculate = '/balance/purchase/calculate';
  static const String balancePurchase = '/balance/purchase';
  static const String balancePurchaseVerifyOtp = '/balance/purchase/verify-otp';
  static const String balancePurchaseDelete = '/balance/purchase/delete';
  static const String balanceCheck = '/balance/check';

  // ══════════════════════════════════════════════
  //  TRANSFER
  // ══════════════════════════════════════════════
  static const String transferHistory = '/transfer/history';
  static const String transfer = '/transfer';
  static const String transferSubaccountsHistory = '/transfer/subaccounts/history';
  static const String transferSubaccounts = '/transfer/subaccounts';
  static const String transferSubaccountsReport = '/transfer/subaccounts/report';
  static const String transferSubaccountsExport = '/transfer/subaccounts/export';

  // ══════════════════════════════════════════════
  //  SETTINGS - PROFILE
  // ══════════════════════════════════════════════
  static const String settingsProfile = '/settings/profile';
  static const String settingsProfilePhoto = '/settings/profile/photo';
  static const String settingsPassword = '/settings/password';
  static const String settingsBalanceReminder = '/settings/balance-reminder';
  static const String settingsHelp = '/settings/help';

  // ══════════════════════════════════════════════
  //  SETTINGS - SUB ACCOUNTS
  // ══════════════════════════════════════════════
  static const String settingsSubAccounts = '/settings/sub-accounts';

  static String settingsSubAccountShow(dynamic id) => '/settings/sub-accounts/$id';
  static String settingsSubAccountUpdate(dynamic id) => '/settings/sub-accounts/$id';
  static String settingsSubAccountDelete(dynamic id) => '/settings/sub-accounts/$id';

  // ══════════════════════════════════════════════
  //  SETTINGS - ROLES
  // ══════════════════════════════════════════════
  static const String settingsRoles = '/settings/roles';

  static String settingsRoleShow(dynamic id) => '/settings/roles/$id';
  static String settingsRoleUpdate(dynamic id) => '/settings/roles/$id';
  static String settingsRoleDelete(dynamic id) => '/settings/roles/$id';

  // ══════════════════════════════════════════════
  //  SETTINGS - SUB ACCOUNT CATEGORIES
  // ══════════════════════════════════════════════
  static const String settingsSubAccountCategories = '/settings/sub-account-categories';

  static String settingsSubAccountCategoryShow(dynamic id) =>
      '/settings/sub-account-categories/$id';
  static String settingsSubAccountCategoryUpdate(dynamic id) =>
      '/settings/sub-account-categories/$id';
  static String settingsSubAccountCategoryDelete(dynamic id) =>
      '/settings/sub-account-categories/$id';

  // ══════════════════════════════════════════════
  //  SETTINGS - INVOICES
  // ══════════════════════════════════════════════
  static const String settingsInvoices = '/settings/invoices';

  static String settingsInvoiceShow(dynamic id) => '/settings/invoices/$id';
  static String settingsInvoiceDownload(dynamic id) => '/settings/invoices/$id/download';

  // ══════════════════════════════════════════════
  //  SETTINGS - API KEYS
  // ══════════════════════════════════════════════
  static const String settingsApiKeys = '/settings/api-keys';

  static String settingsApiKeyShow(dynamic id) => '/settings/api-keys/$id';
  static String settingsApiKeyUpdate(dynamic id) => '/settings/api-keys/$id';
  static String settingsApiKeyDelete(dynamic id) => '/settings/api-keys/$id';
  static String settingsApiKeyRegenerate(dynamic id) => '/settings/api-keys/$id/regenerate';

  // ══════════════════════════════════════════════
  //  SETTINGS - SENDERS
  // ══════════════════════════════════════════════
  static const String settingsSenders = '/settings/senders';

  static String settingsSenderShow(dynamic id) => '/settings/senders/$id';
  static String settingsSenderUpdate(dynamic id) => '/settings/senders/$id';
  static String settingsSenderDelete(dynamic id) => '/settings/senders/$id';

  // ══════════════════════════════════════════════
  //  SETTINGS - CONTRACTS
  // ══════════════════════════════════════════════
  static const String settingsContracts = '/settings/contracts';

  static String settingsContractShow(dynamic id) => '/settings/contracts/$id';
  static String settingsContractDownload(dynamic id) => '/settings/contracts/$id/download';

  // ══════════════════════════════════════════════
  //  STATISTICS
  // ══════════════════════════════════════════════
  static const String statistics = '/statistics';
  static const String statisticsExport = '/statistics/export';
  static const String statisticsExportDownload = '/statistics/export-download';

  // ══════════════════════════════════════════════
  //  ADDONS
  // ══════════════════════════════════════════════
  static const String addons = '/addons';

  static String addonShow(dynamic id) => '/addons/$id';
  static String addonActivateTrial(dynamic id) => '/addons/$id/activate-trial';
  static String addonInitiatePayment(dynamic id) => '/addons/$id/initiate-payment';

  // ══════════════════════════════════════════════
  //  SHORT LINKS
  // ══════════════════════════════════════════════
  static const String shortLinks = '/short-links';

  static String shortLinkShow(dynamic id) => '/short-links/$id';
  static String shortLinkUpdate(dynamic id) => '/short-links/$id';
  static String shortLinkDelete(dynamic id) => '/short-links/$id';
  static const String shortLinkStatistics = '/short-links/statistics';

  // ══════════════════════════════════════════════
  //  NOTIFICATIONS
  // ══════════════════════════════════════════════
  static const String notifications = '/notifications';
  static const String notificationsMarkAllRead = '/notifications/mark-all-read';

  static String notificationMarkRead(dynamic id) => '/notifications/$id/mark-read';
  static String notificationDelete(dynamic id) => '/notifications/$id';

  static const String notificationsUnreadCount = '/notifications/unread-count';

  // ══════════════════════════════════════════════
  //  QUESTIONNAIRES
  // ══════════════════════════════════════════════
  static const String questionnaires = '/questionnaires';

  static String questionnaireShow(dynamic id) => '/questionnaires/$id';
  static String questionnaireUpdate(dynamic id) => '/questionnaires/$id';
  static String questionnaireDelete(dynamic id) => '/questionnaires/$id';
  static String questionnaireResults(dynamic id) => '/questionnaires/$id/results';
  static String questionnaireExport(dynamic id) => '/questionnaires/$id/export';

  // ══════════════════════════════════════════════
  //  STATEMENTS
  // ══════════════════════════════════════════════
  static const String statements = '/statements';
  static const String statementsExport = '/statements/export';
  static const String statementsDelete = '/statements/delete';

  static String statementShow(dynamic id) => '/statements/$id';
  static String statementUpdate(dynamic id) => '/statements/$id';
  static String statementDelete(dynamic id) => '/statements/$id';

  // ══════════════════════════════════════════════
  //  OCCASION CARDS
  // ══════════════════════════════════════════════
  static const String occasionCards = '/occasion-cards';

  static String occasionCardShow(dynamic id) => '/occasion-cards/$id';
  static String occasionCardUpdate(dynamic id) => '/occasion-cards/$id';
  static String occasionCardDelete(dynamic id) => '/occasion-cards/$id';
  static const String occasionCardCategories = '/occasion-cards/categories';
  static const String occasionCardTemplates = '/occasion-cards/templates';

  // ══════════════════════════════════════════════
  //  CONTACT ME
  // ══════════════════════════════════════════════
  static const String contactMe = '/contact-me';

  static String contactMeShow(dynamic id) => '/contact-me/$id';
  static String contactMeUpdate(dynamic id) => '/contact-me/$id';
  static String contactMeDelete(dynamic id) => '/contact-me/$id';

  // ══════════════════════════════════════════════
  //  INTERACTION
  // ══════════════════════════════════════════════
  static const String interactions = '/interactions';

  static String interactionShow(dynamic id) => '/interactions/$id';
  static String interactionUpdate(dynamic id) => '/interactions/$id';
  static String interactionDelete(dynamic id) => '/interactions/$id';
  static String interactionResults(dynamic id) => '/interactions/$id/results';
  static String interactionExport(dynamic id) => '/interactions/$id/export';

  // ══════════════════════════════════════════════
  //  FILES
  // ══════════════════════════════════════════════
  static const String files = '/files';

  static String fileShow(dynamic id) => '/files/$id';
  static String fileUpdate(dynamic id) => '/files/$id';
  static String fileDelete(dynamic id) => '/files/$id';
  static String fileDownload(dynamic id) => '/files/$id/download';

  // ══════════════════════════════════════════════
  //  CERTIFICATIONS
  // ══════════════════════════════════════════════
  static const String certifications = '/certifications';

  static String certificationShow(dynamic id) => '/certifications/$id';
  static String certificationDownload(dynamic id) => '/certifications/$id/download';

  // ══════════════════════════════════════════════
  //  ABSENCE & TARDINESS MESSAGES
  // ══════════════════════════════════════════════
  static const String absenceMessages = '/absence-messages';

  static String absenceMessageShow(dynamic id) => '/absence-messages/$id';
  static String absenceMessageReport(dynamic id) => '/absence-messages/$id/report';

  // ══════════════════════════════════════════════
  //  UTILS
  // ══════════════════════════════════════════════
  static const String hijriDate = '/utils/hijri-date';

  // ══════════════════════════════════════════════
  //  PAGINATION DEFAULTS
  // ══════════════════════════════════════════════
  static const int defaultPage = 1;
  static const int defaultPerPage = 15;
  static const int maxPerPage = 100;

  // ══════════════════════════════════════════════
  //  QUERY PARAMETER KEYS
  // ══════════════════════════════════════════════
  static const String paramPage = 'page';
  static const String paramPerPage = 'per_page';
  static const String paramSearch = 'search';
  static const String paramSortBy = 'sort_by';
  static const String paramSortOrder = 'sort_order';
  static const String paramDateFrom = 'date_from';
  static const String paramDateTo = 'date_to';
  static const String paramStatus = 'status';
  static const String paramSenderId = 'sender_id';
  static const String paramGroupId = 'group_id';
  static const String paramType = 'type';
  static const String paramLocale = 'locale';
}
