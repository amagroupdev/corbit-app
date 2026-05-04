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

/// Bulk Operations + Multi-select UI (Wave 6 — V3 sync).
///
/// Enables long-press-to-select on lists (Groups, Numbers, Files,
/// Short Links, Archive…) plus bulk delete/move/copy/resend actions
/// against the V3 endpoints (`/groups/bulk-delete`, `/numbers/move-to-group`,
/// `/archive/resend`, …). Tap on a single item still opens its detail.
const bool kBulkOperationsEnabled = true;
