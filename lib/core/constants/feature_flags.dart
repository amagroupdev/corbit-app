/// ================================================================
/// Feature Flags - أعلام الميزات
/// ================================================================
/// Flags عامة للتحكم في ظهور/إخفاء المزايا بدون حذف الكود.
///
/// السياسة الحالية: الفلاقز تُفعَّل على **Android فقط**.
/// على **iOS** تبقى محصورة (false) لتمرير مراجعة Apple
/// (Guideline 3.1.1 - In-App Purchase). على **Web** أيضاً false
/// لأن Platform.* يرمي استثناء خارج Android/iOS.
///
/// ⚠️ [kRechargeEnabled]: ميزة الشحن/التعبئة (شراء الرصيد، تحويل
/// الرصيد، السجلات، طرق الدفع).
///
/// ⚠️ [kBusinessRegistrationEnabled]: ميزة إنشاء حساب جديد
/// (Sign Up / Register). iOS يصير Login-only للعملاء الحاليين
/// (زي Slack/Netflix).
///
/// كل الكود (شاشات، controllers، routes، ترجمات، API) محفوظ بالحرف
/// ويشتغل فوراً حين يقيّم الفلاج True.
/// ================================================================

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// مفعّلة على Android فقط. iOS/Web = false (Apple 3.1.1).
bool get kRechargeEnabled => !kIsWeb && Platform.isAndroid;

/// مفعّلة على Android فقط. iOS/Web = false (Apple 3.1.1).
bool get kBusinessRegistrationEnabled => !kIsWeb && Platform.isAndroid;

// ════════════════════════════════════════════════════════════════════
//  V3 — Waves 3+ feature flags
// ════════════════════════════════════════════════════════════════════

/// Wave 3 — Drafts (مسودات الرسائل).
const bool kDraftsEnabled = true;

/// Wave 4 — Voice Messages (تسجيل ورفع الرسائل الصوتية). محمي بإذن المايك.
const bool kVoiceMessagesEnabled = true;

/// Wave 5 — Messages Enhancements (dynamic texts, AI generate, DLR,
/// receipt report, send variants موسّعة).
const bool kMessagesEnhancementsEnabled = true;
const bool kAiGenerateEnabled = kMessagesEnhancementsEnabled;
const bool kDynamicTextsEnabled = kMessagesEnhancementsEnabled;
const bool kDlrByNumberEnabled = kMessagesEnhancementsEnabled;
const bool kReceiptReportEnabled = kMessagesEnhancementsEnabled;
const bool kSendVariantsEnabled = kMessagesEnhancementsEnabled;

/// Wave 6 — Bulk Operations + Multi-select UI.
/// Enables long-press multi-select on lists (Groups, Numbers, Files,
/// Short Links, Archive…) + bulk delete/move/copy/resend.
const bool kBulkOperationsEnabled = true;

/// Wave 8 — Promotional banner carousels (Login + Dashboard).
const bool kBannersEnabled = true;

/// Wave 8 — Support tickets list + create.
const bool kSupportTicketsEnabled = true;

/// Wave 8 — Occasion Cards Send/Preview/Archive.
const bool kOccasionCardsSendEnabled = true;

/// Wave 8 — Sub-accounts statistics tab.
const bool kStatisticsSubaccountsEnabled = true;

/// Wave 8 — Server-triggered statements export.
const bool kStatementsExportEnabled = true;
