/// Asset path constants for the ORBIT SMS V3 application.
///
/// All asset references are centralized here to avoid hardcoded
/// path strings scattered across the codebase.
///
/// Directories are defined in `pubspec.yaml`:
/// - `assets/images/`
/// - `assets/icons/`
/// - `assets/fonts/`
///
/// Usage:
/// ```dart
/// Image.asset(AppAssets.logo);
/// SvgPicture.asset(AppAssets.iconHome);
/// ```
abstract final class AppAssets {
  // ──────────────────────────────────────────────
  // Base Paths
  // ──────────────────────────────────────────────
  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';
  static const String _fonts = 'assets/fonts';

  // ══════════════════════════════════════════════
  //  IMAGES
  // ══════════════════════════════════════════════

  // ── Branding ──
  static const String logo = '$_images/logo.png';
  static const String logoDark = '$_images/logo_dark.png';
  static const String logoWhite = '$_images/logo_white.png';
  static const String logoIcon = '$_images/logo_icon.png';
  static const String logoFull = '$_images/logo_full.png';
  static const String logoFullDark = '$_images/logo_full_dark.png';

  // ── Onboarding ──
  static const String onboarding1 = '$_images/onboarding_1.png';
  static const String onboarding2 = '$_images/onboarding_2.png';
  static const String onboarding3 = '$_images/onboarding_3.png';

  // ── Auth ──
  static const String loginBackground = '$_images/login_background.png';
  static const String registerBackground = '$_images/register_background.png';
  static const String otpIllustration = '$_images/otp_illustration.png';
  static const String forgotPasswordIllustration = '$_images/forgot_password_illustration.png';
  static const String resetSuccessIllustration = '$_images/reset_success_illustration.png';

  // ── Empty States ──
  static const String emptyMessages = '$_images/empty_messages.png';
  static const String emptyGroups = '$_images/empty_groups.png';
  static const String emptyTemplates = '$_images/empty_templates.png';
  static const String emptyNotifications = '$_images/empty_notifications.png';
  static const String emptyArchive = '$_images/empty_archive.png';
  static const String emptyStatistics = '$_images/empty_statistics.png';
  static const String emptySearch = '$_images/empty_search.png';
  static const String emptyBalance = '$_images/empty_balance.png';
  static const String emptyTransactions = '$_images/empty_transactions.png';
  static const String emptySubAccounts = '$_images/empty_sub_accounts.png';
  static const String emptyInvoices = '$_images/empty_invoices.png';
  static const String emptyShortLinks = '$_images/empty_short_links.png';
  static const String emptyQuestionnaires = '$_images/empty_questionnaires.png';
  static const String emptyFiles = '$_images/empty_files.png';
  static const String emptyOccasionCards = '$_images/empty_occasion_cards.png';
  static const String emptyInteractions = '$_images/empty_interactions.png';
  static const String emptyGeneral = '$_images/empty_general.png';

  // ── Error States ──
  static const String errorGeneral = '$_images/error_general.png';
  static const String errorNetwork = '$_images/error_network.png';
  static const String errorServer = '$_images/error_server.png';
  static const String error404 = '$_images/error_404.png';
  static const String errorTimeout = '$_images/error_timeout.png';

  // ── Success ──
  static const String successGeneral = '$_images/success_general.png';
  static const String successMessage = '$_images/success_message.png';
  static const String successPurchase = '$_images/success_purchase.png';
  static const String successTransfer = '$_images/success_transfer.png';

  // ── Placeholders ──
  static const String placeholderAvatar = '$_images/placeholder_avatar.png';
  static const String placeholderImage = '$_images/placeholder_image.png';

  // ── Balance ──
  static const String balanceBackground = '$_images/balance_background.png';
  static const String balancePattern = '$_images/balance_pattern.png';

  // ── Misc ──
  static const String splashBackground = '$_images/splash_background.png';
  static const String maintenanceIllustration = '$_images/maintenance_illustration.png';
  static const String updateRequiredIllustration = '$_images/update_required_illustration.png';

  // ══════════════════════════════════════════════
  //  SVG ICONS
  // ══════════════════════════════════════════════

  // ── Navigation / Tab Bar ──
  static const String iconHome = '$_icons/ic_home.svg';
  static const String iconHomeActive = '$_icons/ic_home_active.svg';
  static const String iconMessages = '$_icons/ic_messages.svg';
  static const String iconMessagesActive = '$_icons/ic_messages_active.svg';
  static const String iconGroups = '$_icons/ic_groups.svg';
  static const String iconGroupsActive = '$_icons/ic_groups_active.svg';
  static const String iconBalance = '$_icons/ic_balance.svg';
  static const String iconBalanceActive = '$_icons/ic_balance_active.svg';
  static const String iconMore = '$_icons/ic_more.svg';
  static const String iconMoreActive = '$_icons/ic_more_active.svg';

  // ── Actions ──
  static const String iconSend = '$_icons/ic_send.svg';
  static const String iconSchedule = '$_icons/ic_schedule.svg';
  static const String iconPreview = '$_icons/ic_preview.svg';
  static const String iconEdit = '$_icons/ic_edit.svg';
  static const String iconDelete = '$_icons/ic_delete.svg';
  static const String iconCopy = '$_icons/ic_copy.svg';
  static const String iconShare = '$_icons/ic_share.svg';
  static const String iconExport = '$_icons/ic_export.svg';
  static const String iconImport = '$_icons/ic_import.svg';
  static const String iconDownload = '$_icons/ic_download.svg';
  static const String iconUpload = '$_icons/ic_upload.svg';
  static const String iconFilter = '$_icons/ic_filter.svg';
  static const String iconSort = '$_icons/ic_sort.svg';
  static const String iconSearch = '$_icons/ic_search.svg';
  static const String iconRefresh = '$_icons/ic_refresh.svg';
  static const String iconAdd = '$_icons/ic_add.svg';
  static const String iconClose = '$_icons/ic_close.svg';
  static const String iconBack = '$_icons/ic_back.svg';
  static const String iconForward = '$_icons/ic_forward.svg';
  static const String iconMenu = '$_icons/ic_menu.svg';
  static const String iconCheck = '$_icons/ic_check.svg';
  static const String iconCancel = '$_icons/ic_cancel.svg';
  static const String iconPrint = '$_icons/ic_print.svg';
  static const String iconLink = '$_icons/ic_link.svg';

  // ── Features ──
  static const String iconSms = '$_icons/ic_sms.svg';
  static const String iconTemplate = '$_icons/ic_template.svg';
  static const String iconSender = '$_icons/ic_sender.svg';
  static const String iconArchive = '$_icons/ic_archive.svg';
  static const String iconStatistics = '$_icons/ic_statistics.svg';
  static const String iconTransfer = '$_icons/ic_transfer.svg';
  static const String iconWallet = '$_icons/ic_wallet.svg';
  static const String iconOffer = '$_icons/ic_offer.svg';
  static const String iconBank = '$_icons/ic_bank.svg';
  static const String iconShortLink = '$_icons/ic_short_link.svg';
  static const String iconQuestionnaire = '$_icons/ic_questionnaire.svg';
  static const String iconStatement = '$_icons/ic_statement.svg';
  static const String iconOccasionCard = '$_icons/ic_occasion_card.svg';
  static const String iconContactMe = '$_icons/ic_contact_me.svg';
  static const String iconInteraction = '$_icons/ic_interaction.svg';
  static const String iconFile = '$_icons/ic_file.svg';
  static const String iconCertification = '$_icons/ic_certification.svg';
  static const String iconAddon = '$_icons/ic_addon.svg';

  // ── Settings ──
  static const String iconSettings = '$_icons/ic_settings.svg';
  static const String iconProfile = '$_icons/ic_profile.svg';
  static const String iconPassword = '$_icons/ic_password.svg';
  static const String iconNotification = '$_icons/ic_notification.svg';
  static const String iconNotificationBell = '$_icons/ic_notification_bell.svg';
  static const String iconLanguage = '$_icons/ic_language.svg';
  static const String iconTheme = '$_icons/ic_theme.svg';
  static const String iconHelp = '$_icons/ic_help.svg';
  static const String iconAbout = '$_icons/ic_about.svg';
  static const String iconLogout = '$_icons/ic_logout.svg';
  static const String iconSubAccount = '$_icons/ic_sub_account.svg';
  static const String iconRole = '$_icons/ic_role.svg';
  static const String iconApiKey = '$_icons/ic_api_key.svg';
  static const String iconInvoice = '$_icons/ic_invoice.svg';
  static const String iconContract = '$_icons/ic_contract.svg';
  static const String iconBalanceReminder = '$_icons/ic_balance_reminder.svg';
  static const String iconCategory = '$_icons/ic_category.svg';
  static const String iconPrivacy = '$_icons/ic_privacy.svg';
  static const String iconTerms = '$_icons/ic_terms.svg';

  // ── Status ──
  static const String iconStatusSent = '$_icons/ic_status_sent.svg';
  static const String iconStatusDelivered = '$_icons/ic_status_delivered.svg';
  static const String iconStatusFailed = '$_icons/ic_status_failed.svg';
  static const String iconStatusPending = '$_icons/ic_status_pending.svg';
  static const String iconStatusScheduled = '$_icons/ic_status_scheduled.svg';
  static const String iconStatusRejected = '$_icons/ic_status_rejected.svg';

  // ── Social / Contact ──
  static const String iconPhone = '$_icons/ic_phone.svg';
  static const String iconEmail = '$_icons/ic_email.svg';
  static const String iconWhatsapp = '$_icons/ic_whatsapp.svg';
  static const String iconTwitter = '$_icons/ic_twitter.svg';
  static const String iconWebsite = '$_icons/ic_website.svg';

  // ── Auth ──
  static const String iconEye = '$_icons/ic_eye.svg';
  static const String iconEyeOff = '$_icons/ic_eye_off.svg';
  static const String iconFingerprint = '$_icons/ic_fingerprint.svg';
  static const String iconFaceId = '$_icons/ic_face_id.svg';
  static const String iconLock = '$_icons/ic_lock.svg';
  static const String iconUser = '$_icons/ic_user.svg';

  // ── Misc ──
  static const String iconCalendar = '$_icons/ic_calendar.svg';
  static const String iconClock = '$_icons/ic_clock.svg';
  static const String iconCamera = '$_icons/ic_camera.svg';
  static const String iconGallery = '$_icons/ic_gallery.svg';
  static const String iconDocument = '$_icons/ic_document.svg';
  static const String iconExcel = '$_icons/ic_excel.svg';
  static const String iconPdf = '$_icons/ic_pdf.svg';
  static const String iconInfo = '$_icons/ic_info.svg';
  static const String iconWarning = '$_icons/ic_warning.svg';
  static const String iconError = '$_icons/ic_error.svg';
  static const String iconSuccess = '$_icons/ic_success.svg';
  static const String iconEmpty = '$_icons/ic_empty.svg';
  static const String iconArrowUp = '$_icons/ic_arrow_up.svg';
  static const String iconArrowDown = '$_icons/ic_arrow_down.svg';
  static const String iconArrowLeft = '$_icons/ic_arrow_left.svg';
  static const String iconArrowRight = '$_icons/ic_arrow_right.svg';
  static const String iconChevronUp = '$_icons/ic_chevron_up.svg';
  static const String iconChevronDown = '$_icons/ic_chevron_down.svg';
  static const String iconChevronLeft = '$_icons/ic_chevron_left.svg';
  static const String iconChevronRight = '$_icons/ic_chevron_right.svg';
  static const String iconStar = '$_icons/ic_star.svg';
  static const String iconStarFilled = '$_icons/ic_star_filled.svg';
  static const String iconHeart = '$_icons/ic_heart.svg';
  static const String iconPin = '$_icons/ic_pin.svg';
  static const String iconLocation = '$_icons/ic_location.svg';
  static const String iconGlobe = '$_icons/ic_globe.svg';

  // ══════════════════════════════════════════════
  //  FONTS
  // ══════════════════════════════════════════════
  static const String fontCairoRegular = '$_fonts/Cairo-Regular.ttf';
  static const String fontCairoMedium = '$_fonts/Cairo-Medium.ttf';
  static const String fontCairoSemiBold = '$_fonts/Cairo-SemiBold.ttf';
  static const String fontCairoBold = '$_fonts/Cairo-Bold.ttf';

  // ══════════════════════════════════════════════
  //  LOTTIE ANIMATIONS (if used in future)
  // ══════════════════════════════════════════════
  static const String _animations = 'assets/animations';

  static const String animLoading = '$_animations/loading.json';
  static const String animSuccess = '$_animations/success.json';
  static const String animError = '$_animations/error.json';
  static const String animEmpty = '$_animations/empty.json';
  static const String animSending = '$_animations/sending.json';
  static const String animConfetti = '$_animations/confetti.json';
}
