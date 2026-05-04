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

/// ─── Wave 5 — Messages Enhancements ───────────────────────────────
/// تجميع تحسينات الرسائل V3:
///  - متغيّرات ديناميكية من السيرفر (`/messages/dynamic-texts`)
///  - توليد نص بالذكاء الاصطناعي (`/messages/ai-generate`)
///  - تقرير DLR لرقم محدد (`/messages/dlr-by-number`)
///  - تقرير استلام شامل (`/messages/{uuid}/receipt-report`)
///  - send variants موسّعة (specific group, short link, attendance,
///    certifications, vip card, excel, with_file)
///
/// كله متاح على كل المنصّات لأنه ميزات نصية لا علاقة لها بمدفوعات
/// داخل التطبيق. الـ flags مفصولة لتسهيل التعطيل المنفصل لو تطلب.
const bool kMessagesEnhancementsEnabled = true;
const bool kAiGenerateEnabled = kMessagesEnhancementsEnabled;
const bool kDynamicTextsEnabled = kMessagesEnhancementsEnabled;
const bool kDlrByNumberEnabled = kMessagesEnhancementsEnabled;
const bool kReceiptReportEnabled = kMessagesEnhancementsEnabled;
const bool kSendVariantsEnabled = kMessagesEnhancementsEnabled;
