// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'SecureAuth';

  @override
  String get authSubtitle => 'تحقق من هويتك\nللوصول إلى حساباتك';

  @override
  String get password => 'كلمة المرور';

  @override
  String get pleaseEnterPassword => 'يرجى إدخال كلمة المرور';

  @override
  String lockedWithTime(String time) {
    return 'مقفل: $time';
  }

  @override
  String failedAttemptsCount(int count) {
    return '$count محاولات فاشلة';
  }

  @override
  String get tooManyAttempts => 'محاولات فاشلة كثيرة جداً. يرجى الانتظار.';

  @override
  String wrongPasswordWithRemaining(int remaining) {
    return 'كلمة مرور خاطئة ($remaining محاولات متبقية)';
  }

  @override
  String get maxAttemptsExceeded =>
      'تم تجاوز الحد الأقصى للمحاولات. تم حذف جميع البيانات.';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get biometricLogin => 'الدخول بالبصمة';

  @override
  String codeCopied(int seconds) {
    return 'تم نسخ الرمز (سيُمسح بعد $secondsث)';
  }

  @override
  String minuteShortFormat(int minutes, int seconds) {
    return '$minutesد $secondsث';
  }

  @override
  String secondShortFormat(int seconds) {
    return '$secondsث';
  }

  @override
  String get welcome => 'مرحباً';

  @override
  String get setupSubtitle => 'قم بتعيين كلمة مرور\nلحماية حساباتك';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get strengthWeak => 'ضعيفة';

  @override
  String get strengthMedium => 'متوسطة';

  @override
  String get strengthGood => 'جيدة';

  @override
  String get strengthStrong => 'قوية';

  @override
  String get strengthVeryStrong => 'قوية جداً';

  @override
  String get biometricAuth => 'المصادقة البيومترية';

  @override
  String get fingerprintOrFace => 'بصمة الإصبع أو التعرف على الوجه';

  @override
  String get completeSetup => 'إكمال الإعداد';

  @override
  String get continueWithoutPassword => 'المتابعة بدون كلمة مرور';

  @override
  String get pleaseSetPassword => 'يرجى تعيين كلمة مرور';

  @override
  String passwordMinLength(int length) {
    return 'يجب أن تكون كلمة المرور $length أحرف على الأقل';
  }

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get anErrorOccurred => 'حدث خطأ';

  @override
  String get strongEncryption => 'تشفير قوي مع PBKDF2-SHA512';

  @override
  String get editAccount => 'تعديل الحساب';

  @override
  String get serviceName => 'اسم الخدمة';

  @override
  String get accountName => 'اسم الحساب';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String deleteAccountConfirm(String issuer) {
    return 'هل أنت متأكد من حذف حساب $issuer؟';
  }

  @override
  String get actionIrreversible => 'لا يمكن التراجع عن هذا الإجراء';

  @override
  String get delete => 'حذف';

  @override
  String get accountDeleted => 'تم حذف الحساب';

  @override
  String get searchAccounts => 'البحث عن حسابات...';

  @override
  String get noAccountsYet => 'لم تتم إضافة حسابات بعد';

  @override
  String get addAccountsToImprove =>
      'أضف حسابات المصادقة الثنائية\nلتعزيز أمانك';

  @override
  String get accountNotFound => 'الحساب غير موجود';

  @override
  String get addAccount => 'إضافة حساب';

  @override
  String get scanQRCode => 'مسح رمز QR';

  @override
  String get useCamera => 'استخدم الكاميرا لمسح رمز QR';

  @override
  String get or => 'أو';

  @override
  String get manualEntry => 'إدخال يدوي';

  @override
  String get serviceNameHint => 'Google, GitHub, Discord...';

  @override
  String get accountNameHint => 'user@example.com';

  @override
  String get secretKey => 'المفتاح السري';

  @override
  String get secretKeyHint => 'JBSWY3DPEHPK3PXP';

  @override
  String get serviceNameRequired => 'اسم الخدمة مطلوب';

  @override
  String get accountNameRequired => 'اسم الحساب مطلوب';

  @override
  String get secretKeyRequired => 'المفتاح السري مطلوب';

  @override
  String get invalidSecretKey => 'مفتاح سري غير صالح';

  @override
  String get saveAccount => 'حفظ الحساب';

  @override
  String get errorAddingAccount => 'خطأ في إضافة الحساب';

  @override
  String get alignQRCode => 'قم بمحاذاة رمز QR داخل الإطار';

  @override
  String get invalidQRCode => 'رمز QR غير صالح. يرجى مسح رمز TOTP QR.';

  @override
  String get qrCode => 'رمز QR';

  @override
  String get qrCodeTransferInfo =>
      'يمكنك نقل هذا الحساب عن طريق مسح رمز QR هذا على جهاز آخر';

  @override
  String get settings => 'الإعدادات';

  @override
  String get appearance => 'المظهر';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get useDarkTheme => 'استخدام السمة الداكنة';

  @override
  String get systemTheme => 'النظام';

  @override
  String get lightTheme => 'فاتح';

  @override
  String get darkTheme => 'داكن';

  @override
  String get themeMode => 'السمة';

  @override
  String get security => 'الأمان';

  @override
  String get appLock => 'قفل التطبيق';

  @override
  String get requirePasswordOnLaunch => 'طلب كلمة المرور عند التشغيل';

  @override
  String get fingerprintFaceId => 'بصمة / Face ID';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get setPassword => 'تعيين كلمة المرور';

  @override
  String get advancedSecurity => 'أمان متقدم';

  @override
  String get autoLock => 'القفل التلقائي';

  @override
  String get clipboardClear => 'مسح الحافظة';

  @override
  String clipboardClearAfterSeconds(int seconds) {
    return 'بعد $seconds ثانية';
  }

  @override
  String get maxFailedAttemptsLabel => 'الحد الأقصى للمحاولات الفاشلة';

  @override
  String attemptsCount(int count) {
    return '$count محاولات';
  }

  @override
  String get wipeOnMaxAttemptsLabel => 'مسح البيانات عند الحد الأقصى';

  @override
  String get wipeAllDataOnMax => 'حذف جميع البيانات عند الحد الأقصى';

  @override
  String get backup => 'النسخ الاحتياطي';

  @override
  String get exportAccounts => 'تصدير الحسابات';

  @override
  String nAccounts(int count) {
    return '$count حسابات';
  }

  @override
  String get importAccounts => 'استيراد الحسابات';

  @override
  String get loadFromJSON => 'تحميل من ملف JSON';

  @override
  String get dangerZone => 'منطقة خطرة';

  @override
  String get deleteAllData => 'حذف جميع البيانات';

  @override
  String get warning => 'تحذير';

  @override
  String wipeWarning(int count) {
    return 'بعد $count محاولات تسجيل دخول فاشلة، سيتم حذف جميع البيانات تلقائياً. قد تتسبب هذه الميزة في فقدان بيانات لا رجعة فيه.';
  }

  @override
  String get enable => 'تفعيل';

  @override
  String get needPasswordFirst => 'تحتاج إلى تعيين كلمة مرور أولاً';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get currentPasswordWrong => 'كلمة المرور الحالية غير صحيحة';

  @override
  String get passwordChangedSuccess => 'تم تغيير كلمة المرور بنجاح';

  @override
  String get deleteAllDataConfirm =>
      'سيؤدي هذا إلى حذف جميع الحسابات والإعدادات.';

  @override
  String get actionIrreversibleExcl => 'لا يمكن التراجع عن هذا الإجراء!';

  @override
  String get allDataDeleted => 'تم حذف جميع البيانات';

  @override
  String get disabled => 'معطل';

  @override
  String nSeconds(int count) {
    return '$count ثانية';
  }

  @override
  String nMinutes(int count) {
    return '$count دقيقة';
  }

  @override
  String get clipboardClearTime => 'وقت مسح الحافظة';

  @override
  String get secureAuthBackup => 'نسخة احتياطية SecureAuth';

  @override
  String get backupFileDescription => 'ملف النسخ الاحتياطي لحسابات SecureAuth';

  @override
  String get accountsExported => 'تم تصدير الحسابات';

  @override
  String nAccountsImported(int count) {
    return 'تم استيراد $count حسابات بنجاح';
  }

  @override
  String get exportError => 'خطأ في التصدير';

  @override
  String get importError => 'خطأ في الاستيراد';

  @override
  String get aboutEncryption => 'PBKDF2-SHA512 | AES-256 | غير متصل بالكامل';

  @override
  String get edit => 'تعديل';

  @override
  String get language => 'اللغة';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get exportBackup => 'تصدير النسخة الاحتياطية';

  @override
  String get encryptedExport => 'مشفر (موصى به)';

  @override
  String get encryptedExportDesc =>
      'محمي بـ AES-256-GCM. آمن للمشاركة في أي مكان.';

  @override
  String get unencryptedExport => 'غير مشفر';

  @override
  String get unencryptedExportDesc => 'JSON بسيط. للتخزين الموثوق فقط.';

  @override
  String get setBackupPassword => 'تعيين كلمة مرور النسخة الاحتياطية';

  @override
  String get backupPassword => 'كلمة مرور النسخة الاحتياطية';

  @override
  String get confirmBackupPassword => 'تأكيد كلمة مرور النسخة الاحتياطية';

  @override
  String get backupPasswordWarning =>
      'احتفظ بكلمة المرور هذه في مكان آمن. بدونها، لا يمكن فتح النسخة الاحتياطية.';

  @override
  String get encryptingBackup => 'جارٍ تشفير النسخة الاحتياطية...';

  @override
  String get decryptingBackup => 'جارٍ فك تشفير النسخة الاحتياطية...';

  @override
  String get decryptBackup => 'فك تشفير النسخة الاحتياطية';

  @override
  String get enterBackupPassword =>
      'أدخل كلمة المرور التي استخدمتها عند تصدير هذه النسخة الاحتياطية.';

  @override
  String get wrongPasswordOrCorrupted => 'كلمة مرور خاطئة أو ملف تالف';

  @override
  String get loadFromFile => 'تحميل من ملف JSON أو .saenc مشفر';

  @override
  String get ok => 'موافق';

  @override
  String get dataWipedTitle => 'تم حذف جميع البيانات';

  @override
  String get dataWipedBody =>
      'تم تجاوز الحد الأقصى لمحاولات كلمة المرور.\n\nتم حذف جميع حساباتك وإعداداتك نهائيًا لأسباب أمنية. اضغط موافق للبدء من جديد.';
}
