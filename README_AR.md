# TaskFlow — مشروع Flutter كامل المصدر

هذا المشروع يحتوي على كود Flutter وملفات إعداد Android الأساسية لبناء APK من بيئة Flutter مثل Klencod.

## الاستيراد
1. نزّل ملف ZIP وفك ضغطه.
2. استورد المجلد `TaskFlow_Flutter_Full_Project` الذي يحتوي على `pubspec.yaml`.
3. من Klencod اختر مزامنة/تنزيل الحزم إن ظهرت، أو شغّل `flutter pub get`.
4. اختر **Build APK**.

## الملفات
- `lib/main.dart`: التطبيق.
- `pubspec.yaml`: الحزم والإعدادات.
- `android/`: إعدادات بناء Android.

## ملاحظة
ملفات Gradle Wrapper تتضمن `gradle-wrapper.properties` وسكربتات التشغيل. بعض بيئات IDE السحابية تنشئ/تضيف ملف `gradle-wrapper.jar` تلقائيًا عند استيراد المشروع أو تشغيل البناء. إذا طلب Klencod إنشاء مشروع Flutter أولًا، أنشئ مشروعًا جديدًا ثم استبدل `lib/main.dart` و`pubspec.yaml` بهذه الملفات.
