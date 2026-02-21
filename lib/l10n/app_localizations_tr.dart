// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'SecureAuth';

  @override
  String get authSubtitle =>
      'Hesaplariniza erismek icin\nkimliginizi dogrulayin';

  @override
  String get password => 'Sifre';

  @override
  String get pleaseEnterPassword => 'Lutfen sifrenizi girin';

  @override
  String lockedWithTime(String time) {
    return 'Kilitli: $time';
  }

  @override
  String failedAttemptsCount(int count) {
    return '$count basarisiz deneme';
  }

  @override
  String get tooManyAttempts => 'Cok fazla basarisiz deneme. Lutfen bekleyin.';

  @override
  String wrongPasswordWithRemaining(int remaining) {
    return 'Yanlis sifre ($remaining hak kaldi)';
  }

  @override
  String get maxAttemptsExceeded =>
      'Maksimum deneme asildi. Tum veriler silindi.';

  @override
  String get login => 'Giris Yap';

  @override
  String get biometricLogin => 'Biyometrik ile Giris';

  @override
  String codeCopied(int seconds) {
    return 'Kod kopyalandi (${seconds}sn sonra silinecek)';
  }

  @override
  String minuteShortFormat(int minutes, int seconds) {
    return '$minutes dk $seconds sn';
  }

  @override
  String secondShortFormat(int seconds) {
    return '$seconds sn';
  }

  @override
  String get welcome => 'Hos Geldiniz';

  @override
  String get setupSubtitle =>
      'Hesaplarinizi guvende tutmak icin\nbir sifre belirleyin';

  @override
  String get confirmPassword => 'Sifre Tekrar';

  @override
  String get strengthWeak => 'Zayif';

  @override
  String get strengthMedium => 'Orta';

  @override
  String get strengthGood => 'Iyi';

  @override
  String get strengthStrong => 'Guclu';

  @override
  String get strengthVeryStrong => 'Cok Guclu';

  @override
  String get biometricAuth => 'Biyometrik Dogrulama';

  @override
  String get fingerprintOrFace => 'Parmak izi veya yuz tanima';

  @override
  String get completeSetup => 'Kurulumu Tamamla';

  @override
  String get continueWithoutPassword => 'Sifresiz Devam Et';

  @override
  String get pleaseSetPassword => 'Lutfen bir sifre belirleyin';

  @override
  String passwordMinLength(int length) {
    return 'Sifre en az $length karakter olmalidir';
  }

  @override
  String get passwordsDoNotMatch => 'Sifreler eslesmyor';

  @override
  String get anErrorOccurred => 'Bir hata olustu';

  @override
  String get strongEncryption => 'PBKDF2-SHA512 ile guclu sifreleme';

  @override
  String get editAccount => 'Hesabi Duzenle';

  @override
  String get serviceName => 'Servis Adi';

  @override
  String get accountName => 'Hesap Adi';

  @override
  String get cancel => 'Iptal';

  @override
  String get save => 'Kaydet';

  @override
  String get deleteAccount => 'Hesabi Sil';

  @override
  String deleteAccountConfirm(String issuer) {
    return '$issuer hesabini silmek istediginizden emin misiniz?';
  }

  @override
  String get actionIrreversible => 'Bu islem geri alinamaz';

  @override
  String get delete => 'Sil';

  @override
  String get accountDeleted => 'Hesap silindi';

  @override
  String get searchAccounts => 'Hesap ara...';

  @override
  String get noAccountsYet => 'Henuz hesap eklemediniz';

  @override
  String get addAccountsToImprove =>
      '2FA hesaplarinizi ekleyerek\nguvenliginizi artirin';

  @override
  String get accountNotFound => 'Hesap bulunamadi';

  @override
  String get addAccount => 'Hesap Ekle';

  @override
  String get scanQRCode => 'QR Kod Tara';

  @override
  String get useCamera => 'Kameranizi kullanarak QR kodu okutun';

  @override
  String get or => 'veya';

  @override
  String get manualEntry => 'Manuel Giris';

  @override
  String get serviceNameHint => 'Google, GitHub, Discord...';

  @override
  String get accountNameHint => 'kullanici@ornek.com';

  @override
  String get secretKey => 'Secret Key';

  @override
  String get secretKeyHint => 'JBSWY3DPEHPK3PXP';

  @override
  String get serviceNameRequired => 'Servis adi gerekli';

  @override
  String get accountNameRequired => 'Hesap adi gerekli';

  @override
  String get secretKeyRequired => 'Secret key gerekli';

  @override
  String get invalidSecretKey => 'Gecersiz secret key';

  @override
  String get saveAccount => 'Hesabi Kaydet';

  @override
  String get errorAddingAccount => 'Hesap eklenirken hata olustu';

  @override
  String get alignQRCode => 'QR kodu cerceve icine hizalayin';

  @override
  String get invalidQRCode =>
      'Gecersiz QR kod. Lutfen bir TOTP QR kodu tarayin.';

  @override
  String get qrCode => 'QR Kod';

  @override
  String get qrCodeTransferInfo =>
      'Bu QR kodu baska bir cihazda tarayarak hesabi aktarabilirsiniz';

  @override
  String get settings => 'Ayarlar';

  @override
  String get appearance => 'Gorunum';

  @override
  String get darkMode => 'Karanlik Mod';

  @override
  String get useDarkTheme => 'Koyu tema kullan';

  @override
  String get systemTheme => 'Sistem';

  @override
  String get lightTheme => 'Acik';

  @override
  String get darkTheme => 'Koyu';

  @override
  String get themeMode => 'Tema';

  @override
  String get security => 'Guvenlik';

  @override
  String get appLock => 'Uygulama Kilidi';

  @override
  String get requirePasswordOnLaunch => 'Acilista sifre iste';

  @override
  String get fingerprintFaceId => 'Parmak izi / yuz tanima';

  @override
  String get changePassword => 'Sifre Degistir';

  @override
  String get setPassword => 'Sifre Belirle';

  @override
  String get advancedSecurity => 'Gelismis Guvenlik';

  @override
  String get autoLock => 'Otomatik Kilitleme';

  @override
  String get clipboardClear => 'Pano Temizleme';

  @override
  String clipboardClearAfterSeconds(int seconds) {
    return '$seconds saniye sonra';
  }

  @override
  String get maxFailedAttemptsLabel => 'Max Basarisiz Deneme';

  @override
  String attemptsCount(int count) {
    return '$count deneme';
  }

  @override
  String get wipeOnMaxAttemptsLabel => 'Denemede Veri Silme';

  @override
  String get wipeAllDataOnMax => 'Max denemede tum verileri sil';

  @override
  String get backup => 'Yedekleme';

  @override
  String get exportAccounts => 'Hesaplari Disa Aktar';

  @override
  String nAccounts(int count) {
    return '$count hesap';
  }

  @override
  String get importAccounts => 'Hesaplari Ice Aktar';

  @override
  String get loadFromJSON => 'JSON dosyasindan yukle';

  @override
  String get dangerZone => 'Tehlikeli Bolge';

  @override
  String get deleteAllData => 'Tum Verileri Sil';

  @override
  String get warning => 'Dikkat';

  @override
  String wipeWarning(int count) {
    return '$count basarisiz giris denemesinden sonra tum veriler otomatik olarak silinecek. Bu ozellik geri alinamaz veri kaybina neden olabilir.';
  }

  @override
  String get enable => 'Etkinlestir';

  @override
  String get needPasswordFirst => 'Once sifre belirlemeniz gerekiyor';

  @override
  String get currentPassword => 'Mevcut Sifre';

  @override
  String get newPassword => 'Yeni Sifre';

  @override
  String get confirmNewPassword => 'Yeni Sifre Tekrar';

  @override
  String get currentPasswordWrong => 'Mevcut sifre yanlis';

  @override
  String get passwordChangedSuccess => 'Sifre basariyla degistirildi';

  @override
  String get deleteAllDataConfirm =>
      'Bu islem tum hesaplari ve ayarlari silecektir.';

  @override
  String get actionIrreversibleExcl => 'Bu islem geri alinamaz!';

  @override
  String get allDataDeleted => 'Tum veriler silindi';

  @override
  String get disabled => 'Kapali';

  @override
  String nSeconds(int count) {
    return '$count saniye';
  }

  @override
  String nMinutes(int count) {
    return '$count dakika';
  }

  @override
  String get clipboardClearTime => 'Pano Temizleme Suresi';

  @override
  String get secureAuthBackup => 'SecureAuth Yedek';

  @override
  String get backupFileDescription => 'SecureAuth hesap yedekleme dosyasi';

  @override
  String get accountsExported => 'Hesaplar disa aktarildi';

  @override
  String nAccountsImported(int count) {
    return '$count hesap basariyla ice aktarildi';
  }

  @override
  String get exportError => 'Disa aktarma hatasi';

  @override
  String get importError => 'Ice aktarma hatasi';

  @override
  String get aboutEncryption => 'PBKDF2-SHA512 | AES-256 | Tamamen Offline';

  @override
  String get edit => 'Duzenle';

  @override
  String get language => 'Dil';

  @override
  String get selectLanguage => 'Dil Secin';

  @override
  String get exportBackup => 'Yedeği Dışa Aktar';

  @override
  String get encryptedExport => 'Şifreli (Önerilen)';

  @override
  String get encryptedExportDesc =>
      'AES-256-GCM korumalı. Her yerde güvenle paylaşılabilir.';

  @override
  String get unencryptedExport => 'Şifresiz';

  @override
  String get unencryptedExportDesc =>
      'Ham JSON. Yalnızca güvenilir depolama için.';

  @override
  String get setBackupPassword => 'Yedek Şifresi Belirle';

  @override
  String get backupPassword => 'Yedek Şifresi';

  @override
  String get confirmBackupPassword => 'Yedek Şifresini Onayla';

  @override
  String get backupPasswordWarning =>
      'Bu şifreyi güvenli bir yere kaydedin. Şifre olmadan yedeğinizi açamazsınız.';

  @override
  String get encryptingBackup => 'Yedek şifreleniyor...';

  @override
  String get decryptingBackup => 'Yedek çözülüyor...';

  @override
  String get decryptBackup => 'Yedeği Çöz';

  @override
  String get enterBackupPassword =>
      'Bu yedeği dışa aktarırken belirlediğiniz şifreyi girin.';

  @override
  String get wrongPasswordOrCorrupted => 'Yanlış şifre veya bozuk dosya';

  @override
  String get loadFromFile => 'JSON veya şifreli .saenc dosyasından yükle';

  @override
  String get ok => 'Tamam';

  @override
  String get dataWipedTitle => 'Tüm Veriler Silindi';

  @override
  String get dataWipedBody =>
      'Maksimum başarısız giriş denemesi aşıldı.\n\nGüvenliğiniz için tüm hesaplarınız ve ayarlarınız kalıcı olarak silindi. Baştan başlamak için Tamam\'a dokunun.';

  @override
  String get normalDark => 'Koyu';

  @override
  String get pureDark => 'Saf Koyu';

  @override
  String get accentColor => 'Vurgu Rengi';
}
