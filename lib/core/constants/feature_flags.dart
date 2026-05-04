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

// ════════════════════════════════════════════════════════════════
//  Wave 9: Certifications + Madrasati + Settings Extensions
// ════════════════════════════════════════════════════════════════

/// Wave 9 — تفعيل ميزات الشهادات المتقدمة (filters + bulk delete + PDF).
const bool kCertificationsAdvancedEnabled = true;

/// Wave 9 — تفعيل نظام إرسال الشهادات عبر روابط (Certifications Link).
const bool kCertificationsLinkEnabled = true;

/// Wave 9 — تفعيل دعم منصة مدرستي في إعدادات الشهادات.
const bool kMadrasatiEnabled = true;

/// Wave 9 — تفعيل Invoices الموسعة (list/show/pdf via /settings/invoices/...).
const bool kInvoicesEnabled = true;

/// Wave 9 — تفعيل Sub-accounts المتقدمة (consumption, annual balance,
/// balance reminder, transfer permissions).
const bool kSubAccountsAdvancedEnabled = true;
