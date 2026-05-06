# Corbit — كوربت

تطبيق Flutter لخدمة **Corbit SMS V3** (Android + iOS + Web).
شركة **Corbit / كوربت** — السجل التجاري `4650037318`، ترخيص CITC `LGP0921-22`.

---

## 🚀 ابدأ هنا (للفريق البرمجي الجديد)

اقرأ بالترتيب:
1. **[`HANDOVER.md`](./HANDOVER.md)** — ملف التسليم الرسمي، نقطة الدخول الأولى.
2. **[`CORBIT_APP_DOCS.md`](./CORBIT_APP_DOCS.md)** — التوثيق التقني الشامل (845 سطر).
3. **[`CORBIT_FEATURES.md`](./CORBIT_FEATURES.md)** — قائمة المزايا الكاملة.
4. **[`MIGRATION.md`](./MIGRATION.md)** — ملاحظات الترحيل من الإصدار السابق.

---

## 📱 معلومات سريعة

| البند | القيمة |
|------|------|
| النسخة | `1.0.4+34` |
| Flutter | `3.38.7+` (نسخة CI) |
| State | Riverpod |
| Routing | GoRouter |
| HTTP | Dio + AuthInterceptor |
| API | `https://app.mobile.net.sa/api/v3` |
| iOS Bundle | `Orbit.Technology.corbit` |
| Android Package | `com.orbit.orbit_app` |
| Apple App ID | `6760257754` |

---

## ⚡ الإعداد السريع

```bash
git clone https://github.com/amagroupdev/corbit-app.git
cd corbit-app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

> ⚠️ **تحذير مهم**: قبل أي تعديل، اقرأ `HANDOVER.md` بالكامل — خاصةً قسم **Feature Flags** و **تنبيهات أمنية**.

---

## 🔗 روابط

- **App Store**: https://apps.apple.com/sa/app/corbit/id6760257754
- **Privacy Policy**: https://development.saudismart.co/portfolio/corbit/privacy-policy
- **الإيميل الرسمي**: `info@corbit.sa`

---

© 2026 Corbit. كل الحقوق محفوظة.
