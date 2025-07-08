# حل مشاكل Google Maps في Release Build

## المشاكل الشائعة والحلول

### 1. مفتاح Google Maps API

**المشكلة:** الخريطة تعمل في Debug لكن لا تعمل في Release

**الحل:**
```xml
<!-- في android/app/src/main/AndroidManifest.xml -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyDcWIxw6lRSHR9O8ts9R76d9Z7ZzsFmDa0" />
```

**تأكد من:**
- تفعيل المفتاح في Google Cloud Console
- إضافة SHA-1 fingerprint للـ release keystore
- تفعيل APIs المطلوبة:
  - Maps SDK for Android
  - Geocoding API
  - Places API (إذا مستخدم)

### 2. إعدادات ProGuard

**ملف:** `android/app/proguard-rules.pro` (تم إنشاؤه)

**الإعدادات المهمة:**
```
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.location.** { *; }
```

### 3. إعدادات Build

**في** `android/app/build.gradle`:
```gradle
buildTypes {
    release {
        minifyEnabled true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        shrinkResources true
    }
}
```

### 4. الصلاحيات المطلوبة

**تأكد من وجود:**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### 5. خطوات بناء APK صحيح

```bash
# 1. تنظيف المشروع
flutter clean

# 2. تحديث dependencies
flutter pub get

# 3. بناء APK release
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

**أو استخدم السكريبت:** `.\build_release.ps1`

### 6. اختبار Release APK

1. **لا تختبر على Emulator** - استخدم جهاز حقيقي
2. **تأكد من اتصال الإنترنت**
3. **امنح صلاحيات الموقع**
4. **تحقق من logs**:
   ```bash
   adb logcat | findstr -i maps
   ```

### 7. Google Maps API Key Setup

**خطوات مهمة:**

1. **فتح Google Cloud Console**
2. **إنشاء/تحديد مشروع**
3. **تفعيل APIs:**
   - Maps SDK for Android
   - Geocoding API
   - Places API
4. **إنشاء Credentials → API Key**
5. **إضافة Application restrictions:**
   - اختر "Android apps"
   - أضف package name: `com.mighty.taxidriver`
   - أضف SHA-1 fingerprint للـ release

**للحصول على SHA-1 fingerprint:**
```bash
# للـ debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# للـ release keystore (إذا كان لديك)
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
```

### 8. نصائح إضافية

- **استخدم HTTPS** للـ API calls
- **تحقق من Network Security Config**
- **اختبر في بيئات مختلفة**
- **راقب usage في Google Cloud Console**

### 9. Debug Release Issues

**إذا استمرت المشكلة:**

1. **فحص Logs:**
   ```bash
   adb logcat | findstr -i "maps\|location\|gms"
   ```

2. **تحقق من API Usage:**
   - Google Cloud Console → APIs & Services → Dashboard

3. **اختبار مع APK مؤقت:**
   ```bash
   flutter build apk --debug
   ```

### 10. مؤشرات نجاح الإعداد

✅ **الخريطة تحمل بسرعة**
✅ **تظهر بيانات Google**
✅ **تعمل وظائف الموقع**
✅ **لا توجد أخطاء في logs**
✅ **استهلاك API طبيعي** 