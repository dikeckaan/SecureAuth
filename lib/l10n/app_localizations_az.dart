// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Azerbaijani (`az`).
class AppLocalizationsAz extends AppLocalizations {
  AppLocalizationsAz([String locale = 'az']) : super(locale);

  @override
  String get appName => 'SecureAuth';

  @override
  String get authSubtitle =>
      'Hesablariniza daxil olmaq ucun\nkimliginizi tesdiq edin';

  @override
  String get password => 'Sifre';

  @override
  String get pleaseEnterPassword => 'Zehmet olmasa sifrenizi daxil edin';

  @override
  String lockedWithTime(String time) {
    return 'Kilidlenmis: $time';
  }

  @override
  String failedAttemptsCount(int count) {
    return '$count ugursuz cehd';
  }

  @override
  String get tooManyAttempts => 'Cox ugursuz cehd. Zehmet olmasa gozleyin.';

  @override
  String wrongPasswordWithRemaining(int remaining) {
    return 'Sehv sifre ($remaining cehd qaldi)';
  }

  @override
  String get maxAttemptsExceeded =>
      'Maksimum cehd asıldi. Butun melumatlat silindi.';

  @override
  String get login => 'Daxil Ol';

  @override
  String get biometricLogin => 'Biometrik ile Daxil Ol';

  @override
  String codeCopied(int seconds) {
    return 'Kod kopyalandi (${seconds}sn sonra silinecek)';
  }

  @override
  String minuteShortFormat(int minutes, int seconds) {
    return '$minutes deq $seconds san';
  }

  @override
  String secondShortFormat(int seconds) {
    return '$seconds san';
  }

  @override
  String get welcome => 'Xos Geldiniz';

  @override
  String get setupSubtitle =>
      'Hesablarinizi qorumaq ucun\nbir sifre teyin edin';

  @override
  String get confirmPassword => 'Sifre Tekrar';

  @override
  String get strengthWeak => 'Zeyif';

  @override
  String get strengthMedium => 'Orta';

  @override
  String get strengthGood => 'Yaxsi';

  @override
  String get strengthStrong => 'Guclu';

  @override
  String get strengthVeryStrong => 'Cox Guclu';

  @override
  String get biometricAuth => 'Biometrik Dogrulama';

  @override
  String get fingerprintOrFace => 'Barmaq izi ve ya uz tanima';

  @override
  String get completeSetup => 'Qurasdiirmani Tamamla';

  @override
  String get continueWithoutPassword => 'Sifresiz Davam Et';

  @override
  String get pleaseSetPassword => 'Zehmet olmasa bir sifre teyin edin';

  @override
  String passwordMinLength(int length) {
    return 'Sifre en azi $length simvol olmalidir';
  }

  @override
  String get passwordsDoNotMatch => 'Sifreler uygun gelmir';

  @override
  String get anErrorOccurred => 'Xeta bas verdi';

  @override
  String get strongEncryption => 'PBKDF2-SHA512 ile guclu sifreleme';

  @override
  String get editAccount => 'Hesabi Redakte Et';

  @override
  String get serviceName => 'Servis Adi';

  @override
  String get accountName => 'Hesab Adi';

  @override
  String get cancel => 'Legv Et';

  @override
  String get save => 'Saxla';

  @override
  String get deleteAccount => 'Hesabi Sil';

  @override
  String deleteAccountConfirm(String issuer) {
    return '$issuer hesabini silmek isteyinize eminsiniz?';
  }

  @override
  String get actionIrreversible => 'Bu emeliyyat geri alinmaz';

  @override
  String get delete => 'Sil';

  @override
  String get accountDeleted => 'Hesab silindi';

  @override
  String get searchAccounts => 'Hesab axtar...';

  @override
  String get noAccountsYet => 'Hele hesab elave etmemisiniz';

  @override
  String get addAccountsToImprove =>
      '2FA hesablarinizi elave ederek\ntehlukezizliginizi artirin';

  @override
  String get accountNotFound => 'Hesab tapilmadi';

  @override
  String get addAccount => 'Hesab Elave Et';

  @override
  String get scanQRCode => 'QR Kod Oxut';

  @override
  String get useCamera => 'Kameranizla QR kodu oxudun';

  @override
  String get or => 've ya';

  @override
  String get manualEntry => 'Manuel Daxiletme';

  @override
  String get serviceNameHint => 'Google, GitHub, Discord...';

  @override
  String get accountNameHint => 'istifadeci@numune.com';

  @override
  String get secretKey => 'Gizli Acar';

  @override
  String get secretKeyHint => 'JBSWY3DPEHPK3PXP';

  @override
  String get serviceNameRequired => 'Servis adi teleb olunur';

  @override
  String get accountNameRequired => 'Hesab adi teleb olunur';

  @override
  String get secretKeyRequired => 'Gizli acar teleb olunur';

  @override
  String get invalidSecretKey => 'Kecersiz gizli acar';

  @override
  String get saveAccount => 'Hesabi Saxla';

  @override
  String get errorAddingAccount => 'Hesab elave edilerken xeta';

  @override
  String get alignQRCode => 'QR kodu cercive icine duzun';

  @override
  String get invalidQRCode =>
      'Kecersiz QR kod. Zehmet olmasa TOTP QR kodu oxudun.';

  @override
  String get qrCode => 'QR Kod';

  @override
  String get qrCodeTransferInfo =>
      'Bu QR kodu basqa bir cihazda oxudaraq hesabi kocure bilersiniz';

  @override
  String get settings => 'Parametrler';

  @override
  String get appearance => 'Gorunus';

  @override
  String get darkMode => 'Qaranlig Rejim';

  @override
  String get useDarkTheme => 'Tund tema istifade et';

  @override
  String get systemTheme => 'Sistem';

  @override
  String get lightTheme => 'Isiqli';

  @override
  String get darkTheme => 'Tund';

  @override
  String get themeMode => 'Tema';

  @override
  String get security => 'Tehlukezizlik';

  @override
  String get appLock => 'Tetbiq Kilidi';

  @override
  String get requirePasswordOnLaunch => 'Acilisda sifre tele et';

  @override
  String get fingerprintFaceId => 'Barmaq izi / uz tanima';

  @override
  String get changePassword => 'Sifreni Deyis';

  @override
  String get setPassword => 'Sifre Teyin Et';

  @override
  String get advancedSecurity => 'Gelismis Tehlukezizlik';

  @override
  String get autoLock => 'Avtomatik Kilidleme';

  @override
  String get clipboardClear => 'Buferi Temizle';

  @override
  String clipboardClearAfterSeconds(int seconds) {
    return '$seconds saniye sonra';
  }

  @override
  String get maxFailedAttemptsLabel => 'Maks Ugursuz Cehd';

  @override
  String attemptsCount(int count) {
    return '$count cehd';
  }

  @override
  String get wipeOnMaxAttemptsLabel => 'Maks Cehdde Melumat Silme';

  @override
  String get wipeAllDataOnMax => 'Maks cehdde butun melumatlari sil';

  @override
  String get backup => 'Ehtiyat Nusxe';

  @override
  String get exportAccounts => 'Hesablari Ixrac Et';

  @override
  String nAccounts(int count) {
    return '$count hesab';
  }

  @override
  String get importAccounts => 'Hesablari Idxal Et';

  @override
  String get loadFromJSON => 'JSON faylindan yukle';

  @override
  String get dangerZone => 'Tehlikeli Zona';

  @override
  String get deleteAllData => 'Butun Melumatlari Sil';

  @override
  String get warning => 'Diqqet';

  @override
  String wipeWarning(int count) {
    return '$count ugursuz giris cehdinden sonra butun melumatlar avtomatik silinecek. Bu xususiyyet geri alinmaz melumat itkisine sebeb ola biler.';
  }

  @override
  String get enable => 'Aktivlesdirmek';

  @override
  String get needPasswordFirst => 'Evvelce sifre teyin etmelisiniz';

  @override
  String get currentPassword => 'Cari Sifre';

  @override
  String get newPassword => 'Yeni Sifre';

  @override
  String get confirmNewPassword => 'Yeni Sifre Tekrar';

  @override
  String get currentPasswordWrong => 'Cari sifre sehvdir';

  @override
  String get passwordChangedSuccess => 'Sifre ugurla deyisdirildi';

  @override
  String get deleteAllDataConfirm =>
      'Bu emeliyyat butun hesablari ve parametrleri silecek.';

  @override
  String get actionIrreversibleExcl => 'Bu emeliyyat geri alinmaz!';

  @override
  String get allDataDeleted => 'Butun melumatlar silindi';

  @override
  String get disabled => 'Deaktiv';

  @override
  String nSeconds(int count) {
    return '$count saniye';
  }

  @override
  String nMinutes(int count) {
    return '$count deqiqe';
  }

  @override
  String get clipboardClearTime => 'Bufer Temizleme Vaxti';

  @override
  String get secureAuthBackup => 'SecureAuth Ehtiyat Nusxe';

  @override
  String get backupFileDescription => 'SecureAuth hesab ehtiyat nusxe faylu';

  @override
  String get accountsExported => 'Hesablar ixrac edildi';

  @override
  String nAccountsImported(int count) {
    return '$count hesab ugurla idxal edildi';
  }

  @override
  String get exportError => 'Ixrac xetasi';

  @override
  String get importError => 'Idxal xetasi';

  @override
  String get aboutEncryption => 'PBKDF2-SHA512 | AES-256 | Tamam Oflayn';

  @override
  String get edit => 'Redakte Et';

  @override
  String get language => 'Dil';

  @override
  String get selectLanguage => 'Dil Secin';

  @override
  String get exportBackup => 'Ehtiyat Nüsxəni İxrac Et';

  @override
  String get encryptedExport => 'Şifrəli (Tövsiyə edilir)';

  @override
  String get encryptedExportDesc =>
      'AES-256-GCM ilə qorunur. Hər yerdə paylaşmaq üçün təhlükəsizdir.';

  @override
  String get unencryptedExport => 'Şifrəsiz';

  @override
  String get unencryptedExportDesc =>
      'Sadə JSON. Yalnız etibarlı saxlama üçün.';

  @override
  String get setBackupPassword => 'Ehtiyat Şifrəsini Tənzimlə';

  @override
  String get backupPassword => 'Ehtiyat Şifrəsi';

  @override
  String get confirmBackupPassword => 'Ehtiyat Şifrəsini Təsdiqlə';

  @override
  String get backupPasswordWarning =>
      'Bu şifrəni təhlükəsiz yerdə saxlayın. Şifrə olmadan ehtiyat nüsxənizi aça bilməzsiniz.';

  @override
  String get encryptingBackup => 'Ehtiyat nüsxə şifrələnir...';

  @override
  String get decryptingBackup => 'Ehtiyat nüsxə açılır...';

  @override
  String get decryptBackup => 'Ehtiyat Nüsxəni Aç';

  @override
  String get enterBackupPassword =>
      'Bu ehtiyat nüsxəni ixrac edərkən istifadə etdiyiniz şifrəni daxil edin.';

  @override
  String get wrongPasswordOrCorrupted => 'Yanlış şifrə və ya zədəli fayl';

  @override
  String get loadFromFile => 'JSON və ya şifrəli .saenc faylından yüklə';

  @override
  String get ok => 'Tamam';

  @override
  String get dataWipedTitle => 'Bütün Məlumatlar Silindi';

  @override
  String get dataWipedBody =>
      'Maksimum uğursuz cəhd sayı aşıldı.\n\nTəhlükəsizlik üçün bütün hesablarınız və parametrləriniz birdəfəlik silindi. Yenidən başlamaq üçün Tamam\'a toxunun.';

  @override
  String get normalDark => 'Tünd';

  @override
  String get pureDark => 'Saf Tünd';

  @override
  String get accentColor => 'Vurğu Rəngi';
}
