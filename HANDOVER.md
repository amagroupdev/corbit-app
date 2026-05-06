# 📦 ملف تسليم مشروع Corbit (HANDOVER)

> **تاريخ التسليم:** 2026-05-06
> **المسلِّم:** عزام الماجد (المؤسس)
> **الحالة الحالية:** تطبيق منشور على App Store + Google Play (نسخة 1.0.4+34)
> **النوع:** تسليم رسمي للفريق البرمجي للاستكمال والصيانة

هذا الملف هو **نقطة الدخول الرسمية** للفريق. اقرأه بالكامل قبل أي تعديل.
للتفاصيل التقنية العميقة راجع `CORBIT_APP_DOCS.md` و `CORBIT_FEATURES.md`.

---

## 1. الشركة (هام للتسويق + الوثائق)

| البند | القيمة |
|------|------|
| الاسم الإنجليزي | **Corbit** |
| الاسم العربي | **كوربت** |
| السجل التجاري | `4650037318` |
| ترخيص خدمات SMS (CITC) | `LGP0921-22` |
| الإيميل الرسمي | `info@corbit.sa` |
| موقع الشركة | `corbit.sa` |
| API الإنتاج | `https://app.mobile.net.sa/api/v3` |

> ⚠️ **ممنوع كتابياً** استخدام `Orbit` / `ORBIT` / `أوربيت` / `اوربيت` في أي نص يظهر للمستخدم (وصف App Store، Marketing، Privacy Policy، Support).
> Bundle ID و package name الحاليان (`Orbit.Technology.corbit` / `com.orbit.orbit_app`) **يبقيان كما هما** — لا يمكن تغييرهما لأن التطبيق منشور.

---

## 2. التطبيق - بطاقة تعريف

| البند | القيمة |
|------|------|
| نوع المشروع | تطبيق Flutter (Android + iOS + Web) |
| النسخة الحالية | `1.0.4+34` |
| Apple App ID | `6760257754` |
| Apple Team ID | `HT3R33ZP7W` |
| iOS Bundle | `Orbit.Technology.corbit` |
| Android Package | `com.orbit.orbit_app` |
| Min iOS | 13.0 |
| Min Android | API 21 (Lollipop) |
| الفرع الرئيسي | `main` |

### روابط مهمة
- **GitHub**: https://github.com/amagroupdev/corbit-app
- **App Store**: https://apps.apple.com/sa/app/corbit/id6760257754
- **App Store Connect**: https://appstoreconnect.apple.com/apps/6760257754
- **TestFlight**: https://appstoreconnect.apple.com/teams/69a6de83-f699-47e3-e053-5b8c7c11a4d1/apps/6760257754/testflight/ios
- **Privacy Policy**: https://development.saudismart.co/portfolio/corbit/privacy-policy

---

## 3. البنية التقنية

### Stack
- **Framework**: Flutter (Dart `^3.4.0`)
- **State Management**: Riverpod (مع code generation)
- **Routing**: GoRouter
- **HTTP**: Dio + AuthInterceptor (يحقن JWT تلقائياً)
- **Storage**: `flutter_secure_storage` (للتوكن) + `shared_preferences` (للإعدادات)
- **Forms**: reactive_forms
- **Voice**: record + audioplayers (Wave 4)
- **Font**: IBM Plex Sans Arabic (4 أوزان)

### النمط: Clean Architecture + Feature-based
كل feature فيها: `data/` (datasources, models, repositories) + `domain/` (entities, usecases) + `presentation/` (screens, widgets, controllers).

### عدد الـ Features: **40+**
auth, dashboard, messages, archive, templates, groups, balance, statistics,
ai_assistant, banners, voice_messages, contact_me, addons, notifications,
settings, support, files, drafts, invoices, statements, vip_cards,
occasion_cards, attendance, absence, certifications, questionnaires,
short_links, noor_import, transfer_subaccounts, interaction, cart, common.

---

## 4. ⚡ Feature Flags - حرج جداً

**الملف**: `lib/core/constants/feature_flags.dart`

```dart
bool get kRechargeEnabled => !kIsWeb && Platform.isAndroid;
bool get kBusinessRegistrationEnabled => !kIsWeb && Platform.isAndroid;
```

### السبب: Apple App Store Guideline 3.1.1
- Apple ترفض بيع خدمات رقمية خارج IAP داخل التطبيق.
- لذلك على **iOS** يكون التطبيق **Login-only** للعملاء الحاليين، **بدون شحن، بدون تسجيل حساب جديد**.
- على **Android** كل الميزات مفتوحة (Google Play لا تمنع).
- على **Web** نفس iOS (محصور لتجنب أخطاء `Platform.*`).

### عند الحاجة لتغيير السلوك
- **افتح المزايا على iOS أيضاً**: غيّر التعريفات لتعيد `true`. ⚠️ سيُرفض من Apple.
- **أغلق على كل المنصات**: غيّرها إلى `false` ثابت.
- **لا تحذف الكود الموجود تحت الـ flags** — كل الشاشات/الـ controllers/الـ routes للشحن والتسجيل **محفوظة بالحرف** ومُغلَّفة بـ `if (kRechargeEnabled)` / `if (kBusinessRegistrationEnabled)`.

### النقاط المتأثرة (للمراجعة عند تعديل الـ flags)
**Recharge** (`kRechargeEnabled`):
- `lib/shared/widgets/main_shell.dart` (Bottom Nav tab #3)
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` (Quick Actions)
- `lib/features/ai_assistant/presentation/widgets/ai_suggestion_chips.dart`
- `lib/routing/app_router.dart` (`/balance`, `/buy-balance`, `/transfer-balance`, `/transactions`, `/payment-webview`)
- `lib/features/balance/**` (الشاشات والـ controllers والـ data layer كلها سليمة)

**Business Registration** (`kBusinessRegistrationEnabled`):
- `lib/features/auth/presentation/screens/login_screen.dart` (زر "إنشاء حساب")
- `lib/routing/app_router.dart` (`/register` يُحوّل لـ `/login`)
- `lib/features/auth/presentation/screens/register_screen.dart` (1552 سطر، 5 خطوات — سليم)

---

## 5. بوابات الدفع

| الطريقة | الحالة |
|------|------|
| **Noon Payment** (الأساسية) | API مدمج في الـ backend، التطبيق يفتح WebView على `/balance/purchase` |
| تحويل بنكي | عبر API |
| STC Pay | عبر API |
| SADAD | عبر API |

> ⚠️ **حرج**: لا تستخدم `Paylink` في أي مكان في Corbit. Paylink لشركة أخرى (SaudiSmart). Corbit = Noon Payment فقط.

---

## 6. CI/CD - GitHub Actions

### iOS → TestFlight (يعمل ✅)
- Workflow: `.github/workflows/` (راجع المجلد)
- Runner: `macos-15` + Flutter 3.38.7 + Xcode 16
- Trigger: push إلى `main`
- النتيجة: build يُرفع تلقائياً لـ TestFlight

### Android → Google Play (يعمل ✅)
- نفس الـ trigger
- يُرفع AAB تلقائياً

### GitHub Secrets المطلوبة (موجودة)
```
BUILD_CERTIFICATE_BASE64
P12_PASSWORD
BUILD_PROVISION_PROFILE_BASE64
KEYCHAIN_PASSWORD
APPLE_ID
APP_SPECIFIC_PASSWORD
ANDROID_KEYSTORE_*
```

---

## 7. الإعداد للمطور الجديد (Quick Start)

```bash
# 1. Clone
git clone https://github.com/amagroupdev/corbit-app.git
cd corbit-app

# 2. تثبيت Flutter 3.38.7 (مهم: نفس نسخة CI)
flutter --version  # يجب أن تكون ≥ 3.38

# 3. التبعيات
flutter pub get

# 4. توليد الكود (Riverpod / json_serializable)
dart run build_runner build --delete-conflicting-outputs

# 5. تشغيل
flutter run

# 6. بناء iOS (يحتاج macOS + Xcode 16)
flutter build ios --release

# 7. بناء Android
flutter build appbundle --release
```

### بيئة الاختبار
- Backend: `https://app.mobile.net.sa/api/v3`
- Test login: `591257714` / `Rrttuoo12#`

> ⚠️ **تحذير Gradle**: بعد كل بناء Android، Gradle Daemon يأكل 2.6GB+ رام بالخلفية. شغّل `gradle --stop` بعد البناء.

---

## 8. ملاحظات API دقيقة (مهمة جداً للفريق)

| المسار | الملاحظة |
|------|------|
| `POST /templates` | حقل المحتوى اسمه **`template`** (مو `body` ولا `content`) |
| `POST /archive/list` | يتطلب `archive_type: 'general'` وإلا يرجع HTTP 422 |
| `GET /dashboard` | بيانات ناقصة — لازم supplement من `/auth/me` و `/archive/list` |
| `POST /auth/register` | حقول `city_id` و `gender` فيها أخطاء validation معروفة (راجع قسم Bugs) |
| `POST /auth/verify-phone` | يُستخدم للتسجيل + للـ 2FA — لا تلمسه عند تعطيل التسجيل |
| Preview العدّاد | الـ V3 backend يرجع `total_sms`/`total_numbers`/`cost` — `MessagePreview.fromJson` يقرأ كل الأشكال للتوافق الخلفي |

---

## 9. أخطاء معروفة (Known Bugs)

1. **التسجيل**: `city_id` validation خطأ في السيرفر — يحتاج إصلاح Backend.
2. **التسجيل**: `gender` values: التطبيق يرسل `M/F` بينما الـ API قد يتوقع `male/female`.
3. **حساب المعاينة**: الـ regex القديم لـ `_containsUnicode` كان مكسوراً — أُصلح في Build 32 (انتقلنا لفحص code points يدوياً مقابل GSM-7 + extension table).

---

## 10. سجل النسخ والتقديم لـ Apple

| Build | الحالة | السبب |
|-------|------|------|
| 22 | منشور سابقاً | — |
| 23 | منشور | Privacy Policy URL + ملاحظات حذف الحساب + خط جديد |
| 25 | ❌ مرفوض | Apple 3.1.1 (account registration) |
| 26 | ❌ — | شِلنا الشحن، Apple طلبت تشيل التسجيل |
| 27 | ❌ مرفوض | 2.1 Privacy + 5.0 Legal (مكان غير قانوني للـ mass SMS) |
| 28+ | — | (داخلي) |
| 32 | ✅ منشور | Autofill 2FA + إصلاح حساب المعاينة |
| 33 | داخلي | Wave 10 + إصلاح duplicate keys |
| **34** | **الحالي** | إصلاح Banner من V3 + iOS-only TestFlight workflow |

### نسخة 1.0.1 (Metadata-only) — أُرسلت 2026-04-26
تنظيف اسم Orbit من وصف App Store + إضافة س.ت + ترخيص SMS.

### الحل النهائي لمراجعة Apple
- **حصر التطبيق في 6 دول خليجية فقط**: السعودية، الإمارات، الكويت، البحرين، قطر، عُمان.
- iOS = Login-only (kRechargeEnabled=false, kBusinessRegistrationEnabled=false).
- Android = جميع المزايا مفتوحة.

---

## 11. تنبيهات أمنية حرجة 🚨

### 1. ممنوع إرسال SMS اختبار على أرقام حقيقية
- لا ترسل OTP/SMS اختبار على رقم حقيقي (حتى رقمك الشخصي).
- استخدم: تعديل DB مباشرة، أو طباعة OTP في log، أو mock.

### 2. API Key للذكاء الاصطناعي
- مفتاح DeepSeek **محقون حالياً في التطبيق** (خطر أمني).
- **الخطة**: نقله إلى backend الشركة بحيث التطبيق يكلم سيرفركم → السيرفر يكلم DeepSeek.
- راجع `CORBIT_AI_SERVER_SETUP.md` (إن وجد) للتفاصيل.

### 3. GitHub Token مكشوف في `.git/config` المحلي
- الـ remote URL يحتوي على `ghp_***` token. هذا للتطوير المحلي فقط.
- عند clone جديد، استخدم SSH أو `git credential` بدل تضمين الـ token في الـ URL.

### 4. Privacy Policy
- الإيميل الرسمي **`info@corbit.sa`** فقط — لا تستخدم إيميل شخصي.
- Apple App Store Connect contact = `azzammajed@gmail.com` (حساب Apple Developer).

---

## 12. الماك المحلي (لو احتجتم)

```
IP: 192.168.1.3
User: mamualmutairi
Pass: Majed123
```

- macOS 13.7.8 (قديم — لا يدعم Xcode 16)
- Flutter 3.22.3, Xcode 15.2, CocoaPods 1.16.2
- ⚠️ نسخة Flutter 3.22 تستخدم `CardTheme/TabBarTheme/DialogTheme` بينما CI (3.38) تستخدم `CardThemeData/TabBarThemeData/DialogThemeData`. **الكود يجب أن يكون متوافقاً مع نسخة CI**.
- الحل: استخدم GitHub Actions للبلد iOS بدل الماك المحلي.

---

## 13. خطوات التسليم المُنجزة ✅

- [x] التطبيق منشور على App Store
- [x] التطبيق منشور على Google Play
- [x] CI/CD يعمل (iOS + Android)
- [x] Privacy Policy منشورة (عربي/إنجليزي/صيني)
- [x] التوثيق الكامل (CORBIT_APP_DOCS.md, CORBIT_FEATURES.md, MIGRATION.md, HANDOVER.md)
- [x] السجل التجاري + ترخيص SMS مدرجة في وصف App Store
- [x] المستودع GitHub **عام** (public) للوصول

## 14. مهام مفتوحة للفريق ⏳

- [ ] نقل DeepSeek API Key من التطبيق إلى Backend الشركة (أمن).
- [ ] إصلاح `city_id` validation في `POST /auth/register` (Backend).
- [ ] توحيد قيمة `gender` بين Frontend و Backend (`M/F` vs `male/female`).
- [ ] (اختياري بعد قبول Apple مستقر) فتح ميزات الشحن والتسجيل على iOS مرة أخرى — يحتاج موافقة Apple.
- [ ] متابعة مراجعة Apple للنسخ القادمة.
- [ ] صيانة دورية لـ pubspec.yaml (تحديث التبعيات).

---

## 15. للتواصل والاستفسار

- **المؤسس**: عزام الماجد
- **الإيميل الرسمي للشركة**: `info@corbit.sa`
- **Apple Developer**: `azzammajed@gmail.com`

---

> هذا الملف رسمي وحديث (2026-05-06). أي تعديل في الكود يستوجب تحديث القسم المعني هنا.
> **الفريق هو المسؤول الأول عن المشروع من الآن.** بالتوفيق 🚀
