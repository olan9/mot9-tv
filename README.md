# mot⁹ TV

تطبيق IPTV لـ Android TV و Google TV مستوحى من Netflix.

## المميزات
- 📺 بث مباشر مع تصفية بالفئات
- 🎬 VOD (أفلام) مع صور وبحث
- 🔑 دعم كامل لـ Xtream API
- 🎮 تنقل كامل بالريموت
- 🖤 تصميم Netflix-inspired

## بناء الـ APK

### عبر GitHub Actions (موصى به)
1. ارفع المشروع على GitHub
2. اذهب لـ Actions → Build mot⁹ APK → Run workflow
3. حمّل الـ APK من Artifacts

### محلياً
```bash
flutter pub get
flutter build apk --release
```

## التثبيت على الجهاز
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```
