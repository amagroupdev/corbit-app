/// App-wide string constants (non-localized keys and identifiers).
///
/// These are NOT user-facing translated strings. For localization,
/// use the generated `AppLocalizations` from `flutter_localizations`.
///
/// This class holds route names, storage keys, shared-pref keys,
/// analytics event names, notification channel IDs, and other
/// compile-time string identifiers used across the application.
abstract final class AppStrings {
  // ──────────────────────────────────────────────
  // App Identity
  // ──────────────────────────────────────────────
  static const String appName = 'ORBIT SMS';
  static const String appNameAr = 'أوربت SMS';
  static const String appPackageName = 'com.orbitsms.app';
  static const String appScheme = 'orbitsms';

  // ──────────────────────────────────────────────
  // Locale Codes
  // ──────────────────────────────────────────────
  static const String localeAr = 'ar';
  static const String localeEn = 'en';
  static const String defaultLocale = localeAr;

  // ──────────────────────────────────────────────
  // Font Family
  // ──────────────────────────────────────────────
  static const String fontCairo = 'Cairo';

  // ──────────────────────────────────────────────
  // Secure Storage Keys
  // ──────────────────────────────────────────────
  static const String storageAccessToken = 'access_token';
  static const String storageRefreshToken = 'refresh_token';
  static const String storageUserId = 'user_id';
  static const String storageUserData = 'user_data';
  static const String storageBiometricEnabled = 'biometric_enabled';
  static const String storagePinCode = 'pin_code';

  // ──────────────────────────────────────────────
  // Shared Preferences Keys
  // ──────────────────────────────────────────────
  static const String prefLocale = 'pref_locale';
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefOnboardingComplete = 'pref_onboarding_complete';
  static const String prefFirstLaunch = 'pref_first_launch';
  static const String prefNotificationsEnabled = 'pref_notifications_enabled';
  static const String prefRememberMe = 'pref_remember_me';
  static const String prefLastUsername = 'pref_last_username';
  static const String prefFcmToken = 'pref_fcm_token';
  static const String prefDeviceId = 'pref_device_id';
  static const String prefBalanceReminderThreshold = 'pref_balance_reminder_threshold';
  static const String prefLastSyncTimestamp = 'pref_last_sync_timestamp';
  static const String prefDraftMessage = 'pref_draft_message';
  static const String prefSelectedSenderId = 'pref_selected_sender_id';
  static const String prefRecentSearches = 'pref_recent_searches';

  // ──────────────────────────────────────────────
  // Route Names
  // ──────────────────────────────────────────────
  static const String routeSplash = 'splash';
  static const String routeOnboarding = 'onboarding';
  static const String routeLogin = 'login';
  static const String routeRegister = 'register';
  static const String routeForgotPassword = 'forgot-password';
  static const String routeResetPassword = 'reset-password';
  static const String routeVerifyOtp = 'verify-otp';
  static const String routeVerify2fa = 'verify-2fa';
  static const String routeHome = 'home';
  static const String routeDashboard = 'dashboard';
  static const String routeSendMessage = 'send-message';
  static const String routeMessagePreview = 'message-preview';
  static const String routeArchive = 'archive';
  static const String routeArchiveDetail = 'archive-detail';
  static const String routeGroups = 'groups';
  static const String routeGroupDetail = 'group-detail';
  static const String routeGroupCreate = 'group-create';
  static const String routeGroupEdit = 'group-edit';
  static const String routeGroupNumbers = 'group-numbers';
  static const String routeGroupImport = 'group-import';
  static const String routeTemplates = 'templates';
  static const String routeTemplateCreate = 'template-create';
  static const String routeTemplateEdit = 'template-edit';
  static const String routeSenders = 'senders';
  static const String routeBalance = 'balance';
  static const String routeBalancePurchase = 'balance-purchase';
  static const String routeBalanceOffers = 'balance-offers';
  static const String routeBalanceTransactions = 'balance-transactions';
  static const String routeTransfer = 'transfer';
  static const String routeTransferHistory = 'transfer-history';
  static const String routeStatistics = 'statistics';
  static const String routeSettings = 'settings';
  static const String routeProfile = 'profile';
  static const String routeProfileEdit = 'profile-edit';
  static const String routeChangePassword = 'change-password';
  static const String routeSubAccounts = 'sub-accounts';
  static const String routeSubAccountCreate = 'sub-account-create';
  static const String routeSubAccountEdit = 'sub-account-edit';
  static const String routeRoles = 'roles';
  static const String routeRoleCreate = 'role-create';
  static const String routeRoleEdit = 'role-edit';
  static const String routeApiKeys = 'api-keys';
  static const String routeInvoices = 'invoices';
  static const String routeInvoiceDetail = 'invoice-detail';
  static const String routeContracts = 'contracts';
  static const String routeContractDetail = 'contract-detail';
  static const String routeNotifications = 'notifications';
  static const String routeAddons = 'addons';
  static const String routeAddonDetail = 'addon-detail';
  static const String routeShortLinks = 'short-links';
  static const String routeShortLinkCreate = 'short-link-create';
  static const String routeShortLinkEdit = 'short-link-edit';
  static const String routeQuestionnaires = 'questionnaires';
  static const String routeQuestionnaireCreate = 'questionnaire-create';
  static const String routeQuestionnaireEdit = 'questionnaire-edit';
  static const String routeQuestionnaireResults = 'questionnaire-results';
  static const String routeStatements = 'statements';
  static const String routeStatementCreate = 'statement-create';
  static const String routeOccasionCards = 'occasion-cards';
  static const String routeOccasionCardCreate = 'occasion-card-create';
  static const String routeContactMe = 'contact-me';
  static const String routeInteractions = 'interactions';
  static const String routeInteractionCreate = 'interaction-create';
  static const String routeInteractionResults = 'interaction-results';
  static const String routeFiles = 'files';
  static const String routeCertifications = 'certifications';
  static const String routeHelp = 'help';
  static const String routeAbout = 'about';
  static const String routeWebView = 'webview';

  // ──────────────────────────────────────────────
  // Route Paths (URL segments)
  // ──────────────────────────────────────────────
  static const String pathSplash = '/';
  static const String pathOnboarding = '/onboarding';
  static const String pathLogin = '/login';
  static const String pathRegister = '/register';
  static const String pathForgotPassword = '/forgot-password';
  static const String pathResetPassword = '/reset-password';
  static const String pathVerifyOtp = '/verify-otp';
  static const String pathVerify2fa = '/verify-2fa';
  static const String pathHome = '/home';
  static const String pathDashboard = '/dashboard';
  static const String pathSendMessage = '/send-message';
  static const String pathMessagePreview = '/message-preview';
  static const String pathArchive = '/archive';
  static const String pathArchiveDetail = '/archive/:id';
  static const String pathGroups = '/groups';
  static const String pathGroupDetail = '/groups/:id';
  static const String pathGroupCreate = '/groups/create';
  static const String pathGroupEdit = '/groups/:id/edit';
  static const String pathGroupNumbers = '/groups/:id/numbers';
  static const String pathGroupImport = '/groups/:id/import';
  static const String pathTemplates = '/templates';
  static const String pathTemplateCreate = '/templates/create';
  static const String pathTemplateEdit = '/templates/:id/edit';
  static const String pathSenders = '/senders';
  static const String pathBalance = '/balance';
  static const String pathBalancePurchase = '/balance/purchase';
  static const String pathBalanceOffers = '/balance/offers';
  static const String pathBalanceTransactions = '/balance/transactions';
  static const String pathTransfer = '/transfer';
  static const String pathTransferHistory = '/transfer/history';
  static const String pathStatistics = '/statistics';
  static const String pathSettings = '/settings';
  static const String pathProfile = '/settings/profile';
  static const String pathProfileEdit = '/settings/profile/edit';
  static const String pathChangePassword = '/settings/change-password';
  static const String pathSubAccounts = '/settings/sub-accounts';
  static const String pathSubAccountCreate = '/settings/sub-accounts/create';
  static const String pathSubAccountEdit = '/settings/sub-accounts/:id/edit';
  static const String pathRoles = '/settings/roles';
  static const String pathRoleCreate = '/settings/roles/create';
  static const String pathRoleEdit = '/settings/roles/:id/edit';
  static const String pathApiKeys = '/settings/api-keys';
  static const String pathInvoices = '/settings/invoices';
  static const String pathInvoiceDetail = '/settings/invoices/:id';
  static const String pathContracts = '/settings/contracts';
  static const String pathContractDetail = '/settings/contracts/:id';
  static const String pathNotifications = '/notifications';
  static const String pathAddons = '/addons';
  static const String pathAddonDetail = '/addons/:id';
  static const String pathShortLinks = '/short-links';
  static const String pathShortLinkCreate = '/short-links/create';
  static const String pathShortLinkEdit = '/short-links/:id/edit';
  static const String pathQuestionnaires = '/questionnaires';
  static const String pathQuestionnaireCreate = '/questionnaires/create';
  static const String pathQuestionnaireEdit = '/questionnaires/:id/edit';
  static const String pathQuestionnaireResults = '/questionnaires/:id/results';
  static const String pathStatements = '/statements';
  static const String pathStatementCreate = '/statements/create';
  static const String pathOccasionCards = '/occasion-cards';
  static const String pathOccasionCardCreate = '/occasion-cards/create';
  static const String pathContactMe = '/contact-me';
  static const String pathInteractions = '/interactions';
  static const String pathInteractionCreate = '/interactions/create';
  static const String pathInteractionResults = '/interactions/:id/results';
  static const String pathFiles = '/files';
  static const String pathCertifications = '/certifications';
  static const String pathHelp = '/help';
  static const String pathAbout = '/about';
  static const String pathWebView = '/webview';

  // ──────────────────────────────────────────────
  // Analytics Event Names
  // ──────────────────────────────────────────────
  static const String eventLogin = 'login';
  static const String eventLogout = 'logout';
  static const String eventRegister = 'register';
  static const String eventSendMessage = 'send_message';
  static const String eventPurchaseBalance = 'purchase_balance';
  static const String eventTransferBalance = 'transfer_balance';
  static const String eventCreateGroup = 'create_group';
  static const String eventImportContacts = 'import_contacts';
  static const String eventCreateTemplate = 'create_template';
  static const String eventCreateShortLink = 'create_short_link';
  static const String eventActivateAddon = 'activate_addon';
  static const String eventViewStatistics = 'view_statistics';
  static const String eventExportData = 'export_data';
  static const String eventChangeLanguage = 'change_language';
  static const String eventChangeTheme = 'change_theme';
  static const String eventViewNotification = 'view_notification';
  static const String eventScreenView = 'screen_view';

  // ──────────────────────────────────────────────
  // Notification Channel IDs
  // ──────────────────────────────────────────────
  static const String notificationChannelGeneral = 'orbit_general';
  static const String notificationChannelMessages = 'orbit_messages';
  static const String notificationChannelBalance = 'orbit_balance';
  static const String notificationChannelPromotions = 'orbit_promotions';

  // ──────────────────────────────────────────────
  // Notification Channel Names (for Android)
  // ──────────────────────────────────────────────
  static const String notificationChannelGeneralName = 'General';
  static const String notificationChannelMessagesName = 'Messages';
  static const String notificationChannelBalanceName = 'Balance';
  static const String notificationChannelPromotionsName = 'Promotions';

  // ──────────────────────────────────────────────
  // Message Status Keys
  // ──────────────────────────────────────────────
  static const String statusSent = 'sent';
  static const String statusDelivered = 'delivered';
  static const String statusFailed = 'failed';
  static const String statusPending = 'pending';
  static const String statusRejected = 'rejected';
  static const String statusScheduled = 'scheduled';
  static const String statusExpired = 'expired';
  static const String statusCancelled = 'cancelled';

  // ──────────────────────────────────────────────
  // Sort Order Keys
  // ──────────────────────────────────────────────
  static const String sortAsc = 'asc';
  static const String sortDesc = 'desc';
  static const String sortByDate = 'created_at';
  static const String sortByName = 'name';
  static const String sortByStatus = 'status';

  // ──────────────────────────────────────────────
  // Date / Time Formats
  // ──────────────────────────────────────────────
  static const String dateFormatApi = 'yyyy-MM-dd';
  static const String dateTimeFormatApi = 'yyyy-MM-dd HH:mm:ss';
  static const String dateFormatDisplay = 'dd/MM/yyyy';
  static const String dateTimeFormatDisplay = 'dd/MM/yyyy HH:mm';
  static const String timeFormatDisplay = 'HH:mm';
  static const String dateFormatDisplayAr = 'yyyy/MM/dd';
  static const String dateTimeFormatDisplayAr = 'yyyy/MM/dd HH:mm';

  // ──────────────────────────────────────────────
  // Validation
  // ──────────────────────────────────────────────
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 64;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;
  static const int otpLength = 6;
  static const int otpResendDelaySeconds = 60;
  static const int maxMessageLength = 1000;
  static const int maxSmsPartLength = 70;
  static const int maxSmsPartLengthLatin = 160;
  static const int maxTemplateNameLength = 100;
  static const int maxGroupNameLength = 100;
  static const int maxFileUploadSizeMb = 10;
  static const int maxExcelImportRows = 50000;
  static const int saudiPhoneLength = 9;

  // ──────────────────────────────────────────────
  // Phone Prefixes
  // ──────────────────────────────────────────────
  static const String saudiCountryCode = '+966';
  static const String saudiCountryCodeNumeric = '966';

  // ──────────────────────────────────────────────
  // Mime Types
  // ──────────────────────────────────────────────
  static const String mimeExcel = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  static const String mimeCsv = 'text/csv';
  static const String mimePdf = 'application/pdf';
  static const String mimeJson = 'application/json';
  static const String mimeImage = 'image/*';
  static const String mimeJpeg = 'image/jpeg';
  static const String mimePng = 'image/png';

  // ──────────────────────────────────────────────
  // File Extensions
  // ──────────────────────────────────────────────
  static const String extExcel = '.xlsx';
  static const String extCsv = '.csv';
  static const String extPdf = '.pdf';
  static const String extJpeg = '.jpg';
  static const String extPng = '.png';

  // ──────────────────────────────────────────────
  // Pagination
  // ──────────────────────────────────────────────
  static const int defaultPageSize = 15;
  static const int firstPage = 1;

  // ──────────────────────────────────────────────
  // Cache Keys
  // ──────────────────────────────────────────────
  static const String cacheOrganizationTypes = 'cache_organization_types';
  static const String cacheRegions = 'cache_regions';
  static const String cacheCities = 'cache_cities';
  static const String cacheSenders = 'cache_senders';
  static const String cacheBalance = 'cache_balance';
  static const String cacheBanks = 'cache_banks';
  static const String cachePrices = 'cache_prices';

  // ──────────────────────────────────────────────
  // Hero Tag Prefixes (for animations)
  // ──────────────────────────────────────────────
  static const String heroLogo = 'hero_logo';
  static const String heroBalance = 'hero_balance';
  static const String heroGroup = 'hero_group_';
  static const String heroTemplate = 'hero_template_';
  static const String heroMessage = 'hero_message_';

  // ──────────────────────────────────────────────
  // Deep Link Paths
  // ──────────────────────────────────────────────
  static const String deepLinkResetPassword = 'reset-password';
  static const String deepLinkVerifyPhone = 'verify-phone';
  static const String deepLinkMessage = 'message';
  static const String deepLinkBalance = 'balance';

  // ──────────────────────────────────────────────
  // External URLs
  // ──────────────────────────────────────────────
  static const String urlPrivacyPolicy = 'https://orbitsms.com/privacy-policy';
  static const String urlTermsOfService = 'https://orbitsms.com/terms-of-service';
  static const String urlSpamRegulation = 'https://mobile.net.sa/sms/spam-regulation.pdf';
  static const String urlSupport = 'https://orbitsms.com/support';
  static const String urlFaq = 'https://orbitsms.com/faq';
  static const String urlWebPortal = 'https://portal.orbitsms.com';
  static const String urlPlayStore = 'https://play.google.com/store/apps/details?id=com.orbitsms.app';
  static const String urlAppStore = 'https://apps.apple.com/app/orbit-sms/id000000000';

  // ──────────────────────────────────────────────
  // Support Contact
  // ──────────────────────────────────────────────
  static const String supportEmail = 'support@orbitsms.com';
  static const String supportPhone = '+966XXXXXXXXX';
  static const String supportWhatsApp = '+966XXXXXXXXX';
}
