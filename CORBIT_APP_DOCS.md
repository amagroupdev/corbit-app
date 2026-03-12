# توثيق تطبيق ORBIT (المدار) - دليل الفريق الشامل

> آخر تحديث: 2026-03-10
> هذا الملف يحتوي على كل شيء يحتاجه الفريق لإكمال العمل على التطبيق بشكل مستقل.

---

## 1. نظرة عامة على المشروع

| البند | التفاصيل |
|-------|---------|
| اسم التطبيق | ORBIT / المدار |
| النوع | تطبيق موبايل (Flutter) لبوابة ORBIT SMS V3 |
| الموقع | app.mobile.net.sa |
| API Base URL | `https://app.mobile.net.sa/api/v3` |
| Staging URL | `https://staging.mobile.net.sa/api/v3` |
| النسخة الحالية | 1.0.0+5 |
| Android Package | `com.orbit.orbit_app` |
| iOS Bundle ID | `Orbit.Technology.corbit` |
| GitHub Repo | `amagroupdev/corbit-app` |
| الفرع الرئيسي | `main` |

---

## 2. بيئة التطوير

### المتطلبات
- Flutter SDK 3.38.7+
- Dart SDK (مضمن مع Flutter)
- Android Studio / VS Code
- Xcode (لبناء iOS)
- Git

### إعداد المشروع
```bash
git clone https://github.com/amagroupdev/corbit-app.git
cd corbit-app
flutter pub get
flutter run
```

### أوامر البناء
```bash
# تشغيل عادي
flutter run

# بناء APK للأندرويد
flutter build apk --release

# بناء AAB (للنشر على Google Play)
flutter build appbundle --release

# بناء iOS
flutter build ios --release

# بناء الويب
flutter build web --release

# تشغيل الويب محلياً
npx serve build/web -l 8080 --single
```

---

## 3. الهيكل المعماري (Architecture)

### النمط: Clean Architecture + Feature-based

```
lib/
├── core/                          # الطبقة الأساسية المشتركة
│   ├── constants/
│   │   ├── api_constants.dart     # جميع endpoints الـ API
│   │   ├── app_colors.dart        # ألوان التطبيق
│   │   ├── app_text_styles.dart   # أنماط النصوص
│   │   └── sa_regions.dart        # بيانات المناطق والمدن الثابتة
│   ├── network/
│   │   ├── dio_client.dart        # إعداد Dio HTTP client
│   │   └── api_interceptors.dart  # Auth interceptor (إضافة Token تلقائياً)
│   ├── router/
│   │   └── app_router.dart        # جميع الروابط (GoRouter)
│   ├── theme/
│   │   └── app_theme.dart         # ثيم التطبيق
│   └── utils/                     # أدوات مساعدة
│
├── features/                      # الميزات (كل ميزة مستقلة)
│   ├── auth/                      # المصادقة
│   ├── dashboard/                 # لوحة التحكم
│   ├── messages/                  # الرسائل
│   ├── groups/                    # المجموعات
│   ├── balance/                   # الرصيد
│   ├── templates/                 # القوالب
│   ├── senders/                   # أسماء المرسلين
│   ├── archive/                   # الأرشيف
│   ├── statistics/                # الإحصائيات
│   ├── notifications/             # الإشعارات
│   ├── settings/                  # الإعدادات
│   ├── transfer/                  # التحويل
│   ├── short_links/               # الروابط القصيرة
│   ├── addons/                    # الإضافات
│   ├── questionnaires/            # الاستبيانات
│   ├── statements/                # البيانات
│   ├── occasion_cards/            # بطاقات المناسبات
│   ├── contact_me/                # تواصل معي
│   ├── interactions/              # التفاعلات
│   ├── files/                     # الملفات
│   ├── certifications/            # الشهادات
│   └── absence_messages/          # رسائل الغياب
│
├── shared/                        # مكونات مشتركة
│   ├── models/
│   │   ├── api_response.dart      # ApiResponse<T>
│   │   └── paginated_response.dart # PaginatedResponse<T>
│   ├── widgets/                   # ويدجتات مشتركة
│   └── providers/                 # Riverpod providers مشتركة
│
└── main.dart                      # نقطة البداية
```

### بنية كل Feature
```
features/{name}/
├── data/
│   ├── datasources/
│   │   └── {name}_remote_datasource.dart   # طلبات API
│   ├── models/
│   │   └── {name}_model.dart               # نماذج البيانات
│   └── repositories/
│       └── {name}_repository.dart          # Repository pattern
├── presentation/
│   ├── controllers/
│   │   └── {name}_controller.dart          # Riverpod controller
│   ├── screens/
│   │   └── {name}_screen.dart              # الشاشات
│   └── widgets/
│       └── {name}_widget.dart              # ويدجتات خاصة
```

---

## 4. التقنيات المستخدمة

| التقنية | الاستخدام |
|---------|----------|
| **Flutter** | إطار العمل الرئيسي |
| **Riverpod** | إدارة الحالة (State Management) |
| **GoRouter** | التنقل (Navigation/Routing) |
| **Dio** | طلبات HTTP |
| **flutter_secure_storage** | تخزين Token آمن |
| **SharedPreferences** | تخزين الإعدادات |
| **flutter_svg** | عرض صور SVG |
| **image_picker** | اختيار الصور |
| **intl** | التنسيقات (تاريخ، أرقام) |
| **url_launcher** | فتح روابط خارجية |

---

## 5. نظام المصادقة (Authentication)

### التدفق الكامل

```
Login Screen --> Check requires2fa flag --> [if true] --> 2FA Screen --> Dashboard
                                       --> [if false] --> Check requiresPhoneVerification
                                                          --> [if true] --> Verify Phone --> Dashboard
                                                          --> [if false] --> Dashboard

Register Screen --> Verify OTP Screen --> Login Screen
```

### الملفات المعنية
- `lib/features/auth/presentation/screens/login_screen.dart` - شاشة تسجيل الدخول
- `lib/features/auth/presentation/screens/register_screen.dart` - شاشة التسجيل (3 خطوات)
- `lib/features/auth/presentation/screens/verify_otp_screen.dart` - تحقق OTP بعد التسجيل
- `lib/features/auth/presentation/screens/two_factor_screen.dart` - التحقق الثنائي عند الدخول
- `lib/features/auth/presentation/screens/forgot_password_screen.dart` - نسيت كلمة المرور
- `lib/features/auth/presentation/controllers/auth_controller.dart` - متحكم المصادقة
- `lib/features/auth/presentation/controllers/otp_controller.dart` - متحكم OTP و 2FA
- `lib/features/auth/data/datasources/auth_remote_datasource.dart` - طلبات API المصادقة
- `lib/features/auth/data/models/auth_response_model.dart` - نموذج الاستجابة

### Token
- الصيغة: `id|hash` (مفصول بـ pipe)
- يُخزن في `flutter_secure_storage`
- يُضاف تلقائياً لكل طلب عبر `AuthInterceptor`
- Header: `Authorization: Bearer {token}`

### التسجيل (3 خطوات)
1. **الخطوة 1**: البيانات الشخصية (اسم، إيميل، اسم مستخدم، جوال، جنس، كلمة مرور)
2. **الخطوة 2**: بيانات المنشأة (نوع المنشأة، اسم المنشأة، السجل التجاري، المنطقة، المدينة)
3. **الخطوة 3**: اتفاقية الاستخدام + ملف المنشأة (اختياري)

---

## 6. جميع المسارات (Routes)

```
/login                          // تسجيل الدخول
/register                       // التسجيل
/verify-otp                     // تحقق OTP
/two-factor                     // التحقق الثنائي
/forgot-password                // نسيت كلمة المرور
/                               // لوحة التحكم (الرئيسية)
/messages                       // إرسال رسالة جديدة
/messages/preview               // معاينة الرسالة
/groups                         // قائمة المجموعات
/groups/create                  // إنشاء مجموعة
/groups/:id                     // تفاصيل مجموعة
/groups/:id/edit                // تعديل مجموعة
/groups/:id/numbers             // أرقام المجموعة
/groups/:id/import              // استيراد أرقام
/templates                      // قائمة القوالب
/templates/create               // إنشاء قالب
/templates/:id/edit             // تعديل قالب
/senders                        // أسماء المرسلين
/senders/create                 // إنشاء مرسل
/archive                        // سجل الرسائل
/archive/:id                    // تفاصيل رسالة
/balance                        // الرصيد
/balance/purchase               // شراء رصيد
/balance/transactions           // سجل المعاملات
/transfer                       // تحويل رصيد
/transfer/history               // سجل التحويلات
/transfer/subaccounts           // حسابات فرعية
/statistics                     // الإحصائيات
/notifications                  // الإشعارات
/short-links                    // الروابط القصيرة
/short-links/create             // إنشاء رابط
/short-links/:id                // تفاصيل رابط
/settings                       // الإعدادات الرئيسية
/settings/profile               // الملف الشخصي
/settings/password              // تغيير كلمة المرور
/settings/sub-accounts          // الحسابات الفرعية
/settings/roles                 // الأدوار
/settings/api-keys              // مفاتيح API
/settings/senders               // المرسلين
/settings/invoices              // الفواتير
/settings/contracts             // العقود
/addons                         // الإضافات
/questionnaires                 // الاستبيانات
/statements                     // البيانات
/occasion-cards                 // بطاقات المناسبات
/contact-me                     // تواصل معي
/interactions                   // التفاعلات
/files                          // الملفات
/certifications                 // الشهادات
/absence-messages               // رسائل الغياب
```

---

## 7. API Endpoints الرئيسية

### الملف: `lib/core/constants/api_constants.dart`

جميع الـ endpoints معرفة في هذا الملف. الاستخدام:
```dart
final url = ApiConstants.url(ApiConstants.login);
// => "https://app.mobile.net.sa/api/v3/auth/login"
```

### ملاحظات مهمة عن الـ API

1. **أغلب قوائم V3 تستخدم POST وليس GET**:
   ```
   POST /api/v3/groups/list     (وليس GET /api/v3/groups)
   POST /api/v3/templates/list  (وليس GET /api/v3/templates)
   ```

2. **صيغة الاستجابة المعيارية**:
   ```json
   {
     "success": true,
     "message": "...",
     "data": { ... }
   }
   ```

3. **صيغة القوائم (Pagination)**:
   ```json
   {
     "success": true,
     "data": {
       "data": [...],
       "current_page": 1,
       "last_page": 5,
       "per_page": 15,
       "total": 73
     }
   }
   ```

4. **أخطاء التحقق (Validation)**:
   ```json
   {
     "success": false,
     "message": "...",
     "errors": {
       "field_name": ["رسالة الخطأ"]
     }
   }
   ```

### قائمة الـ Endpoints حسب الميزة

#### Auth (المصادقة)
| Method | Endpoint | الوصف |
|--------|----------|-------|
| POST | `/auth/login` | تسجيل الدخول |
| POST | `/auth/register` | تسجيل حساب جديد |
| POST | `/auth/verify-2fa` | تحقق ثنائي |
| POST | `/auth/verify-phone` | تحقق رقم الجوال |
| POST | `/auth/resend-otp` | إعادة إرسال OTP |
| POST | `/auth/forgot-password` | نسيت كلمة المرور |
| POST | `/auth/reset-password` | إعادة تعيين كلمة المرور |
| GET | `/auth/me` | بيانات المستخدم الحالي |
| POST | `/auth/logout` | تسجيل الخروج |
| POST | `/auth/refresh` | تجديد Token |

#### Common (بيانات مشتركة)
| Method | Endpoint | الوصف |
|--------|----------|-------|
| GET | `/common/organization-types` | أنواع المنشآت |
| GET | `/common/regions` | المناطق |
| GET | `/common/cities?region_id=X` | مدن المنطقة |
| POST | `/common/check-email` | التحقق من الإيميل |
| POST | `/common/check-username` | التحقق من اسم المستخدم |
| POST | `/common/check-phone` | التحقق من رقم الجوال |

#### Dashboard (لوحة التحكم)
| Method | Endpoint | الوصف |
|--------|----------|-------|
| GET | `/dashboard` | بيانات لوحة التحكم |
| GET | `/dashboard/banners` | بانرات إعلانية |

#### Messages (الرسائل)
| Method | Endpoint | الوصف |
|--------|----------|-------|
| POST | `/messages/send` | إرسال رسالة |
| POST | `/messages/preview` | معاينة رسالة |
| POST | `/messages/calculate-sms-count` | حساب عدد الرسائل |
| POST | `/messages/validate-blocked-links` | فحص الروابط المحظورة |
| POST | `/messages/check-duplicate` | فحص التكرار |

#### Groups (المجموعات)
| Method | Endpoint | الوصف |
|--------|----------|-------|
| GET/POST | `/groups` | قائمة/إنشاء مجموعة |
| GET | `/groups/{id}` | تفاصيل مجموعة |
| PUT | `/groups/{id}` | تعديل مجموعة |
| DELETE | `/groups/{id}` | حذف مجموعة |
| POST | `/groups/{id}/restore` | استعادة مجموعة |
| GET | `/groups/{id}/numbers` | أرقام المجموعة |
| POST | `/groups/{id}/import-excel` | استيراد Excel |

#### Templates (القوالب)
| Method | Endpoint | الوصف |
|--------|----------|-------|
| GET/POST | `/templates` | قائمة/إنشاء قالب |
| GET | `/templates/{id}` | تفاصيل قالب |
| PUT | `/templates/{id}` | تعديل قالب |
| DELETE | `/templates/{id}` | حذف قالب |

#### Balance (الرصيد)
| Method | Endpoint | الوصف |
|--------|----------|-------|
| GET | `/balance/current` | الرصيد الحالي |
| GET | `/balance/summary` | ملخص الرصيد |
| GET | `/balance/prices` | الأسعار |
| GET | `/balance/banks` | البنوك |
| GET | `/balance/offers` | العروض |
| GET | `/balance/transactions` | سجل المعاملات |
| POST | `/balance/purchase/calculate` | حساب الشراء |
| POST | `/balance/purchase` | شراء رصيد |

#### Archive (الأرشيف)
| Method | Endpoint | الوصف |
|--------|----------|-------|
| GET | `/archive` | قائمة الرسائل المرسلة |
| GET | `/archive/count` | عدد الرسائل |
| POST | `/archive/export` | تصدير |
| POST | `/archive/cancel-pending` | إلغاء المعلقة |

#### Senders (المرسلين)
| Method | Endpoint | الوصف |
|--------|----------|-------|
| GET | `/senders` | قائمة المرسلين |
| POST | `/senders/validate` | التحقق من اسم مرسل |

#### Settings (الإعدادات)
| Method | Endpoint | الوصف |
|--------|----------|-------|
| GET/PUT | `/settings/profile` | الملف الشخصي |
| POST | `/settings/profile/photo` | صورة الملف الشخصي |
| PUT | `/settings/password` | تغيير كلمة المرور |
| CRUD | `/settings/sub-accounts` | الحسابات الفرعية |
| CRUD | `/settings/roles` | الأدوار |
| CRUD | `/settings/api-keys` | مفاتيح API |
| CRUD | `/settings/senders` | المرسلين |
| GET | `/settings/invoices` | الفواتير |
| GET | `/settings/contracts` | العقود |

---

## 8. حالة الميزات (Feature Status)

### جاهزة ومكتملة
| الميزة | الحالة | ملاحظات |
|--------|--------|---------|
| تسجيل الدخول | مكتمل | يعمل بالكامل |
| التحقق الثنائي (2FA) | مكتمل | شاشة + Controller + API |
| تحقق OTP (بعد التسجيل) | مكتمل | شاشة + Controller + API |
| نسيت كلمة المرور | مكتمل | شاشة + Controller + API |
| لوحة التحكم | مكتمل | بانرات + إحصائيات |
| الإشعارات | مكتمل | قائمة + تعليم كمقروء |
| الملف الشخصي | مكتمل | عرض + تعديل + صورة |
| التنقل (Navigation) | مكتمل | Bottom nav + Drawer + GoRouter |

### تحتاج اختبار/تعديل بسيط
| الميزة | الحالة | ملاحظات |
|--------|--------|---------|
| التسجيل | باقٍ خطأ سيرفر | city_id + gender - انظر قسم الأخطاء المعروفة |
| إرسال الرسائل | يحتاج اختبار | الشاشة جاهزة - يحتاج اختبار مع السيرفر |
| المجموعات | يحتاج اختبار | CRUD جاهز |
| القوالب | يحتاج اختبار | CRUD جاهز |
| الأرشيف | يحتاج اختبار | قائمة + تفاصيل |

### تحتاج تطوير (Endpoints جديدة من تقرير السيرفر)
| الميزة | الحالة | ملاحظات |
|--------|--------|---------|
| سلة المشتريات (Cart) | جديد | endpoints جديدة - يحتاج بناء كامل |
| المسودات (Drafts) | جديد | endpoints جديدة - يحتاج بناء كامل |
| تذاكر الدعم (Support) | جديد | endpoints جديدة - يحتاج بناء كامل |
| البطاقات الجاهزة (Ready Cards) | جديد | endpoints جديدة |
| أنظمة الدفع (Payment) | جديد | mada, visa, stc_pay, mastercard, sadad, apple_pay |

---

## 9. الأخطاء المعروفة (Known Bugs)

### خطأ 1: التسجيل - city_id (خطأ سيرفر - BACKEND FIX NEEDED)
- **الوصف**: عند التسجيل، السيرفر يرجع خطأ "القيمة المحددة المدينة غير موجودة"
- **السبب**: خطأ في validation rule في Laravel - يتحقق من جدول خاطئ
- **التأكيد**: نفس الخطأ يظهر في نسخة الويب على `orbit-ui-pi.vercel.app/signup`
- **الحل**: يحتاج تعديل في السيرفر (backend) - القاعدة `exists` تشير لجدول خاطئ
- **تأثير على التطبيق**: بمجرد إصلاح السيرفر، التطبيق سيعمل مباشرة بدون أي تعديل

### خطأ 2: التسجيل - gender (محتمل - خطأ سيرفر)
- **الوصف**: التطبيق يرسل `M`/`F` للجنس، لكن نسخة الويب تستخدم `male`/`female`
- **الملف**: `register_screen.dart` سطر 768
- **الحل المقترح**: تغيير القيم من `M`/`F` إلى `male`/`female`
- **ملاحظة**: يحتاج تأكيد من فريق السيرفر عن القيم المقبولة

```dart
// الحالي في register_screen.dart:
DropdownMenuItem(value: 'M', child: Text('ذكر')),
DropdownMenuItem(value: 'F', child: Text('أنثى')),

// المقترح (يحتاج تأكيد من Backend):
DropdownMenuItem(value: 'male', child: Text('ذكر')),
DropdownMenuItem(value: 'female', child: Text('أنثى')),
```

---

## 10. كيف تضيف ميزة جديدة (خطوة بخطوة)

### مثال: إضافة ميزة "سلة المشتريات" (Cart)

#### الخطوة 1: إنشاء هيكل المجلدات
```
lib/features/cart/
├── data/
│   ├── datasources/
│   │   └── cart_remote_datasource.dart
│   ├── models/
│   │   └── cart_model.dart
│   └── repositories/
│       └── cart_repository.dart
└── presentation/
    ├── controllers/
    │   └── cart_controller.dart
    ├── screens/
    │   └── cart_screen.dart
    └── widgets/
```

#### الخطوة 2: إضافة الـ Endpoints في `api_constants.dart`
```dart
// CART
static const String cart = '/cart';
static const String cartAdd = '/cart/add';
static const String cartRemove = '/cart/remove';
static const String cartClear = '/cart/clear';
static const String cartCheckout = '/cart/checkout';
```

#### الخطوة 3: إنشاء Model
```dart
// lib/features/cart/data/models/cart_model.dart
import 'package:flutter/foundation.dart';

@immutable
class CartItem {
  final int id;
  final String name;
  final int quantity;
  final double price;

  const CartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] as int,
    name: json['name'] as String,
    quantity: json['quantity'] as int,
    price: (json['price'] as num).toDouble(),
  );
}
```

#### الخطوة 4: إنشاء Remote Datasource
```dart
// lib/features/cart/data/datasources/cart_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

class CartRemoteDatasource {
  final Dio _dio;

  CartRemoteDatasource() : _dio = DioClient.instance;

  Future<Map<String, dynamic>> getCart() async {
    final response = await _dio.get(ApiConstants.url(ApiConstants.cart));
    return response.data;
  }

  Future<Map<String, dynamic>> addItem(Map<String, dynamic> data) async {
    final response = await _dio.post(
      ApiConstants.url(ApiConstants.cartAdd),
      data: data,
    );
    return response.data;
  }
}
```

#### الخطوة 5: إنشاء Controller (Riverpod)
```dart
// lib/features/cart/presentation/controllers/cart_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/cart_remote_datasource.dart';
import '../../data/models/cart_model.dart';

final cartProvider = StateNotifierProvider<CartController, AsyncValue<List<CartItem>>>((ref) {
  return CartController();
});

class CartController extends StateNotifier<AsyncValue<List<CartItem>>> {
  final _datasource = CartRemoteDatasource();

  CartController() : super(const AsyncValue.loading()) {
    loadCart();
  }

  Future<void> loadCart() async {
    state = const AsyncValue.loading();
    try {
      final response = await _datasource.getCart();
      final items = (response['data'] as List)
          .map((e) => CartItem.fromJson(e))
          .toList();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
```

#### الخطوة 6: إنشاء الشاشة
```dart
// lib/features/cart/presentation/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/cart_controller.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('سلة المشتريات')),
      body: cartState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              title: Text(item.name),
              subtitle: Text('الكمية: ${item.quantity} - السعر: ${item.price}'),
            );
          },
        ),
      ),
    );
  }
}
```

#### الخطوة 7: إضافة المسار في `app_router.dart`
```dart
GoRoute(
  path: '/cart',
  builder: (context, state) => const CartScreen(),
),
```

---

## 11. نظام الشبكة (Networking)

### DioClient
- ملف: `lib/core/network/dio_client.dart`
- Singleton Dio instance مع الإعدادات الافتراضية
- Base URL: `ApiConstants.baseUrl`
- Timeout: 30 ثانية (connect + receive + send)
- Headers: `Accept` + `Content-Type` = `application/json`
- Interceptors: `AuthInterceptor`

### AuthInterceptor
- ملف: `lib/core/network/api_interceptors.dart`
- يضيف تلقائياً: `Authorization: Bearer {token}` لكل طلب
- يضيف: `Accept-Language: ar` (أو `en`)
- يتعامل مع: `401 Unauthorized` => يوجه لشاشة تسجيل الدخول
- Token refresh تلقائي

### التعامل مع الأخطاء
```dart
try {
  final response = await dio.post(url, data: data);
  // نجاح
} on DioException catch (e) {
  if (e.response?.statusCode == 422) {
    // أخطاء validation
    final errors = e.response?.data['errors'] as Map<String, dynamic>?;
    // errors = { "email": ["الإيميل مستخدم"], "phone": ["الجوال مطلوب"] }
  } else if (e.response?.statusCode == 401) {
    // غير مصرح - التوكن منتهي
  } else {
    // خطأ آخر
  }
}
```

---

## 12. المناطق والمدن (Regions and Cities)

### ملاحظة مهمة
المناطق والمدن مخزنة ثابتة (hardcoded) في التطبيق بدل الاعتماد على API لأن API المناطق والمدن كان يسبب مشاكل.

### الملف: `lib/core/constants/sa_regions.dart`

```dart
// 13 منطقة سعودية مع مدنها
// الاستخدام:
final regions = SaRegions.regions;
// [{ "id": 1, "name": "الرياض" }, ...]

final cities = SaRegions.cities[1];
// [{ "id": 1, "name": "الرياض" }, { "id": 2, "name": "الدرعية" }, ...]
```

---

## 13. CI/CD - النشر التلقائي

### iOS (TestFlight) - جاهز ويعمل
- **الملف**: `.github/workflows/ios-build.yml`
- **Trigger**: Push to `main`
- **العملية**: بناء IPA => رفع على TestFlight تلقائياً
- **Secrets المطلوبة**: شهادات Apple Developer (موجودة)

### Android (Google Play) - يحتاج إعداد
- **الملف**: `.github/workflows/android-build.yml` (يحتاج إنشاء)
- **الخطوات المطلوبة**:
  1. إنشاء Android Keystore للتوقيع
  2. تحديث `android/app/build.gradle.kts` مع signingConfigs
  3. إنشاء Google Play Service Account من Google Play Console
  4. إضافة GitHub Secrets:
     - `ANDROID_KEYSTORE_BASE64`
     - `ANDROID_KEYSTORE_PASSWORD`
     - `ANDROID_KEY_ALIAS`
     - `ANDROID_KEY_PASSWORD`
     - `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
  5. رفع أول نسخة يدوياً على Google Play Console (مطلوب قبل النشر التلقائي)

---

## 14. الملفات المرجعية في مجلد `apis/`

| الملف | الوصف |
|-------|-------|
| `backend-response-to-frontend-report.md` | تقرير استجابة السيرفر: 88/95 مشكلة محلولة + 31 endpoint جديد |
| `Orbit-API-V3-New-Endpoints.postman_collection.json` | مجموعة Postman لـ 31 endpoint جديد - استيرادها في Postman للاختبار |

### الـ Endpoints الجديدة (31 endpoint)
من تقرير `backend-response-to-frontend-report.md`:

1. **Dashboard**: `GET /dashboard` - بيانات لوحة التحكم
2. **Banners**: `GET /dashboard/banners` - بانرات إعلانية
3. **Cart**: CRUD operations للسلة
4. **Drafts**: CRUD operations للمسودات
5. **Notifications**: `GET/PUT /notifications` + mark read
6. **Support Tickets**: CRUD + reply + close
7. **Ready Cards**: قوالب بطاقات جاهزة
8. **Payment**: mada, visa, stc_pay, mastercard, sadad, apple_pay

### طرق الدفع المدعومة
```
mada, visa, stc_pay, mastercard, sadad, apple_pay
```

---

## 15. التبديل بين Production و Staging

```dart
// في api_constants.dart سطر 20:
static const bool isProduction = true;  // غيرها لـ false للـ staging
```

---

## 16. أوامر مفيدة

```bash
# تشغيل على محاكي Android
flutter run -d emulator-5554

# تشغيل على محاكي iOS
flutter run -d "iPhone 15"

# تشغيل على Chrome (Web)
flutter run -d chrome

# تنظيف المشروع
flutter clean && flutter pub get

# تحديث الحزم
flutter pub upgrade

# فحص المشاكل
flutter analyze

# بناء APK للاختبار
flutter build apk --debug
# الملف: build/app/outputs/flutter-apk/app-debug.apk

# بناء APK للنشر
flutter build apk --release
# الملف: build/app/outputs/flutter-apk/app-release.apk
```

---

## 17. الإعدادات المهمة

### Android (`android/app/build.gradle.kts`)
- `applicationId`: `com.orbit.orbit_app`
- `minSdk`: 21
- `targetSdk`: 34
- `compileSdk`: 35

### iOS (`ios/Runner.xcodeproj`)
- Bundle ID: `Orbit.Technology.corbit`
- Deployment Target: iOS 13.0

### التبعيات الرئيسية (`pubspec.yaml`)
```yaml
dependencies:
  flutter_riverpod: ^2.x    # State management
  go_router: ^14.x          # Navigation
  dio: ^5.x                 # HTTP client
  flutter_secure_storage: ^9.x  # Secure token storage
  shared_preferences: ^2.x  # Settings storage
  image_picker: ^1.x        # Image selection
  flutter_svg: ^2.x         # SVG rendering
  intl: ^0.19.x             # Internationalization
  url_launcher: ^6.x        # External links
```

---

## 18. قائمة المهام المتبقية (TODO)

### أولوية عالية (يجب إنهاؤها أولاً)
- [ ] إصلاح خطأ city_id في السيرفر (فريق Backend)
- [ ] تأكيد قيم gender المقبولة من السيرفر (M/F أو male/female)
- [ ] اختبار شامل لتدفق التسجيل بعد إصلاح السيرفر
- [ ] اختبار تسجيل الدخول + 2FA + OTP على بيئة الإنتاج

### أولوية متوسطة
- [ ] بناء ميزة سلة المشتريات (Cart) - endpoints جديدة
- [ ] بناء ميزة المسودات (Drafts) - endpoints جديدة
- [ ] بناء ميزة تذاكر الدعم (Support Tickets) - endpoints جديدة
- [ ] دمج أنظمة الدفع (Payment Integration)
- [ ] إعداد CI/CD للأندرويد (Google Play)

### أولوية منخفضة
- [ ] تحسين تجربة المستخدم (Animations, Loading states)
- [ ] إضافة دعم اللغة الإنجليزية (i18n)
- [ ] تحسين أداء التطبيق (Performance optimization)
- [ ] إضافة Unit Tests و Widget Tests
- [ ] توثيق الكود (Code documentation)

---

## 19. معلومات التواصل والمراجع

| المرجع | الرابط |
|--------|--------|
| API Production | `https://app.mobile.net.sa/api/v3` |
| API Staging | `https://staging.mobile.net.sa/api/v3` |
| Web Version | `https://orbit-ui-pi.vercel.app` |
| GitHub Repo | `https://github.com/amagroupdev/corbit-app` |
| Postman Collection | `apis/Orbit-API-V3-New-Endpoints.postman_collection.json` |
| Backend Report | `apis/backend-response-to-frontend-report.md` |

---

> هذا الملف يكفي الفريق للعمل بشكل مستقل.
> أي ميزة جديدة اتبعوا القسم 10 (كيف تضيف ميزة جديدة).
> لأي استفسار عن الـ API، راجعوا ملف api_constants.dart وملفات مجلد apis/.
