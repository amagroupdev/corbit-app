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

  // Auth — V3 additions
  /// Alias of [refreshToken] using the V3 naming convention.
  static const String authRefresh = '/auth/refresh';
  static const String authCheckPermission = '/auth/check-permission';
  static const String authCheckAddon = '/auth/check-addon';

  // ══════════════════════════════════════════════
  //  COMMON / LOOKUP
  // ══════════════════════════════════════════════
  static const String organizationTypes = '/common/organization-types';
  static const String regions = '/common/regions';
  static const String cities = '/common/cities';
  static const String checkEmail = '/common/check-email';
  static const String checkUsername = '/common/check-username';
  static const String checkPhone = '/common/check-phone';

  // V3 aliases (preferred new names — used by Wave 2 features)
  static const String commonOrganizationTypes = '/common/organization-types';
  static const String commonRegions = '/common/regions';
  static const String commonCities = '/common/cities';
  static const String commonCheckEmail = '/common/check-email';
  static const String commonCheckUsername = '/common/check-username';
  static const String commonCheckPhone = '/common/check-phone';
  static const String utilsHijriDate = '/utils/hijri-date';

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

  // Messages — V3 enhancements (helpers, AI, DLR, receipts)
  static const String messagesDynamicTexts = '/messages/dynamic-texts';
  static const String messagesAiGenerate = '/messages/ai-generate';
  static const String messagesDlrByNumber = '/messages/dlr-by-number';

  /// GET `/messages/{uuid}/receipt-report`
  static String messageReceiptReport(String uuid) =>
      '/messages/$uuid/receipt-report';

  // ══════════════════════════════════════════════
  //  MESSAGES — DRAFTS
  // ══════════════════════════════════════════════
  static const String messageDrafts = '/messages/drafts';
  static const String messageDraftsStore = '/messages/drafts/store';
  static const String messageDraftsList = '/messages/drafts/list';

  /// GET `/messages/drafts/{id}`
  static String messageDraftShow(dynamic id) => '/messages/drafts/$id';

  /// PUT `/messages/drafts/{id}`
  static String messageDraftUpdate(dynamic id) => '/messages/drafts/$id';

  /// DELETE `/messages/drafts/{id}`
  static String messageDraftDelete(dynamic id) => '/messages/drafts/$id';

  // ══════════════════════════════════════════════
  //  VOICE MESSAGES
  // ══════════════════════════════════════════════
  static const String voicesUpload = '/voices/upload';
  static const String voicesList = '/voices/list';

  /// DELETE `/voices/{id}`
  static String voiceDelete(dynamic id) => '/voices/$id';

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

  // Groups — Bulk operations (V3)
  static const String groupsBulkDelete = '/groups/bulk-delete';
  static const String groupsBulkForceDelete = '/groups/bulk-force-delete';
  static const String groupsImportTemplate = '/groups/import-template';
  static const String groupsImportFailedNumbers = '/groups/import-failed-numbers';
  static const String groupsExportDownload = '/groups/export-download';

  // ══════════════════════════════════════════════
  //  NUMBERS (within groups)
  // ══════════════════════════════════════════════
  static const String numbersValidate = '/numbers/validate';
  static const String numbers = '/numbers';

  static String numberUpdate(dynamic id) => '/numbers/$id';
  static String numberDelete(dynamic id) => '/numbers/$id';

  // Numbers — Bulk & move operations (V3)
  static const String numbersMoveToGroup = '/numbers/move-to-group';
  static const String numbersCopyToGroup = '/numbers/copy-to-group';
  static const String numbersBulkDelete = '/numbers/bulk-delete';

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

  // Archive — Bulk operations (V3)
  static const String archiveResend = '/archive/resend';

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
  static const String balanceUpgradeLevels = '/balance/upgrade-levels';
  static const String balanceUpgradesExport = '/balance/upgrades/export';
  static const String balancePurchaseCalculate = '/balance/purchase/calculate';
  static const String balancePurchase = '/balance/purchase';
  static const String balancePurchaseVerifyOtp = '/balance/purchase/verify-otp';
  static const String balanceCheck = '/balance/check';

  /// DELETE a specific pending purchase by transaction id:
  /// `DELETE /balance/purchase/{transactionId}`
  static String balancePurchaseDelete(dynamic transactionId) =>
      '/balance/purchase/$transactionId';

  // ══════════════════════════════════════════════
  //  TRANSFER
  // ══════════════════════════════════════════════
  static const String transferHistory = '/transfer/history';
  static const String transfer = '/transfer';
  static const String transferExport = '/transfer/export';
  static const String transferSubaccountsHistory = '/transfer/subaccounts/history';
  static const String transferSubaccounts = '/transfer/subaccounts';
  static const String transferSubaccountsReport = '/transfer/subaccounts/report';
  static const String transferSubaccountsExport = '/transfer/subaccounts/export';
  static const String transferExport = '/transfer/export';

  // ══════════════════════════════════════════════
  //  CART (V3 — Android only via feature flag)
  // ══════════════════════════════════════════════
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';

  /// DELETE `/cart/items/{id}`
  static String cartItemDelete(dynamic id) => '/cart/items/$id';

  static const String cartClear = '/cart/clear';
  static const String cartApplyCoupon = '/cart/apply-coupon';
  static const String cartRemoveCoupon = '/cart/remove-coupon';
  static const String cartCheckout = '/cart/checkout';

  // ══════════════════════════════════════════════
  //  CART & CHECKOUT (V3 — Android only)
  // ══════════════════════════════════════════════
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  static const String cartClear = '/cart/clear';
  static const String cartApplyCoupon = '/cart/apply-coupon';
  static const String cartRemoveCoupon = '/cart/remove-coupon';
  static const String cartCheckout = '/cart/checkout';

  /// DELETE /cart/items/{id}
  static String cartItemDelete(dynamic id) => '/cart/items/$id';

  // ══════════════════════════════════════════════
  //  SETTINGS - PROFILE
  // ══════════════════════════════════════════════
  static const String settingsProfile = '/settings/profile';
  static const String settingsProfilePhoto = '/settings/profile/photo';
  static const String settingsPassword = '/settings/password';
  static const String settingsDeleteAccount = '/settings/account/delete';
  static const String settingsBalanceReminder = '/settings/balance-reminder';
  static const String settingsHelp = '/settings/help';

  // ══════════════════════════════════════════════
  //  SETTINGS - SUB ACCOUNTS
  // ══════════════════════════════════════════════
  static const String settingsSubAccounts = '/settings/sub-accounts';

  static String settingsSubAccountShow(dynamic id) => '/settings/sub-accounts/$id';
  static String settingsSubAccountUpdate(dynamic id) => '/settings/sub-accounts/$id';
  static String settingsSubAccountDelete(dynamic id) => '/settings/sub-accounts/$id';

  // Settings - Sub-accounts — V3 advanced endpoints
  static const String settingsSubAccountsConsumption =
      '/settings/sub-accounts/consumption';

  /// `POST /settings/sub-accounts/{id}/annual-balance`
  static String settingsSubAccountAnnualBalance(dynamic id) =>
      '/settings/sub-accounts/$id/annual-balance';

  /// `DELETE /settings/sub-accounts/{id}/annual-balance/{year}`
  static String settingsSubAccountAnnualBalanceDelete(dynamic id, int year) =>
      '/settings/sub-accounts/$id/annual-balance/$year';

  /// `POST /settings/sub-accounts/{id}/balance-reminder`
  static String settingsSubAccountBalanceReminder(dynamic id) =>
      '/settings/sub-accounts/$id/balance-reminder';

  /// `POST /settings/sub-accounts/{id}/transfer-permissions`
  static String settingsSubAccountTransferPermissions(dynamic id) =>
      '/settings/sub-accounts/$id/transfer-permissions';

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

  // Settings - Invoices — V3
  static const String settingsInvoicesList = '/settings/invoices/list';

  /// V3: `GET /settings/invoices/{id}/pdf`.
  static String settingsInvoicePdf(dynamic id) => '/settings/invoices/$id/pdf';

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

  // Statistics — V3 (sub-accounts breakdown)
  static const String statisticsSubaccounts = '/statistics/subaccounts';

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

  // Short Links — Bulk operations (V3)
  static const String shortLinksBulkDelete = '/short-links/bulk-delete';

  // ══════════════════════════════════════════════
  //  VIP CARDS (V3 — bulk only declared here)
  // ══════════════════════════════════════════════
  static const String vipCardsTemplatesBulkDelete = '/vip-cards/templates/bulk-delete';

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

  // Occasion Cards — V3 send/preview/list/templates
  static const String occasionCardsSend = '/occasion-cards/send';
  static const String occasionCardsPreview = '/occasion-cards/preview';
  static const String occasionCardsList = '/occasion-cards/list';

  /// V3 alias of [occasionCardTemplates] using the new naming convention.
  static const String occasionCardsTemplates = '/occasion-cards/templates';

  // ══════════════════════════════════════════════
  //  CONTACT ME
  // ══════════════════════════════════════════════
  static const String contactMe = '/contact-me';

  static String contactMeShow(dynamic id) => '/contact-me/$id';
  static String contactMeUpdate(dynamic id) => '/contact-me/$id';
  static String contactMeDelete(dynamic id) => '/contact-me/$id';

  // ══════════════════════════════════════════════
  //  BANNERS (V3 — login carousel + dashboard banner)
  // ══════════════════════════════════════════════
  static const String bannersLogin = '/banners/login';
  static const String bannersDashboard = '/banners/dashboard';

  // ══════════════════════════════════════════════
  //  SUPPORT TICKETS (V3)
  // ══════════════════════════════════════════════
  static const String supportTickets = '/support-tickets';
  static const String supportTicketsList = '/support-tickets/list';

  // ══════════════════════════════════════════════
  //  INTERACTION  (V3: singular path — was `/interactions/`)
  // ══════════════════════════════════════════════
  static const String interactionCheckRoot = '/interaction/check-root';
  static const String interactionSend = '/interaction/send';
  static const String interactionPreview = '/interaction/preview';
  static const String interactionReplies = '/interaction/replies';

  static String interactionReplyShow(dynamic id) => '/interaction/replies/$id';

  /// Public reply endpoint: `/interaction/{root_name}/reply`.
  static String interactionPublicReply(String rootName) =>
      '/interaction/$rootName/reply';

  // ══════════════════════════════════════════════
  //  FILES
  // ══════════════════════════════════════════════
  static const String files = '/files';

  static String fileShow(dynamic id) => '/files/$id';
  static String fileUpdate(dynamic id) => '/files/$id';
  static String fileDelete(dynamic id) => '/files/$id';
  static String fileDownload(dynamic id) => '/files/$id/download';

  // Files — Bulk operations (V3)
  static const String filesBulkDelete = '/files/bulk-delete';

  // ══════════════════════════════════════════════
  //  CERTIFICATIONS
  // ══════════════════════════════════════════════
  static const String certifications = '/certifications';

  static String certificationShow(dynamic id) => '/certifications/$id';
  static String certificationDownload(dynamic id) => '/certifications/$id/download';

  // Certifications — V3 endpoints
  static const String certificationsList = '/certifications/list';
  static const String certificationsDelete = '/certifications/delete';
  static const String certificationsUploadPdf = '/certifications/upload-pdf-file';
  static const String certificationsFilterOptions = '/certifications/filter-options';
  static const String certificationsSettings = '/certifications/settings';
  static const String certificationsSettingsNoor = '/certifications/settings/noor';
  static const String certificationsSettingsMadrasati = '/certifications/settings/madrasati';

  // Certifications Link — V3 endpoints
  static const String certificationsLinkList = '/certifications-link/list';
  static const String certificationsLinkSend = '/certifications-link/send';
  static const String certificationsLinkPreview = '/certifications-link/preview';
  static const String certificationsLinkNoorLogin = '/certifications-link/noor/login';
  static const String certificationsLinkNoorProfiles = '/certifications-link/noor/profiles';

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
