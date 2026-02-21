// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'SecureAuth';

  @override
  String get authSubtitle =>
      'Bestätigen Sie Ihre Identität, um\nauf Ihre Konten zuzugreifen';

  @override
  String get password => 'Passwort';

  @override
  String get pleaseEnterPassword => 'Bitte geben Sie Ihr Passwort ein';

  @override
  String lockedWithTime(String time) {
    return 'Gesperrt: $time';
  }

  @override
  String failedAttemptsCount(int count) {
    return '$count fehlgeschlagene Versuche';
  }

  @override
  String get tooManyAttempts =>
      'Zu viele fehlgeschlagene Versuche. Bitte warten.';

  @override
  String wrongPasswordWithRemaining(int remaining) {
    return 'Falsches Passwort ($remaining Versuche übrig)';
  }

  @override
  String get maxAttemptsExceeded =>
      'Maximale Versuche überschritten. Alle Daten gelöscht.';

  @override
  String get login => 'Anmelden';

  @override
  String get biometricLogin => 'Biometrische Anmeldung';

  @override
  String codeCopied(int seconds) {
    return 'Code kopiert (wird in ${seconds}s gelöscht)';
  }

  @override
  String minuteShortFormat(int minutes, int seconds) {
    return '$minutes Min $seconds Sek';
  }

  @override
  String secondShortFormat(int seconds) {
    return '$seconds Sek';
  }

  @override
  String get welcome => 'Willkommen';

  @override
  String get setupSubtitle =>
      'Legen Sie ein Passwort fest, um\nIhre Konten zu schützen';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String get strengthWeak => 'Schwach';

  @override
  String get strengthMedium => 'Mittel';

  @override
  String get strengthGood => 'Gut';

  @override
  String get strengthStrong => 'Stark';

  @override
  String get strengthVeryStrong => 'Sehr Stark';

  @override
  String get biometricAuth => 'Biometrische Authentifizierung';

  @override
  String get fingerprintOrFace => 'Fingerabdruck oder Gesichtserkennung';

  @override
  String get completeSetup => 'Einrichtung abschließen';

  @override
  String get continueWithoutPassword => 'Ohne Passwort fortfahren';

  @override
  String get pleaseSetPassword => 'Bitte legen Sie ein Passwort fest';

  @override
  String passwordMinLength(int length) {
    return 'Passwort muss mindestens $length Zeichen haben';
  }

  @override
  String get passwordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String get anErrorOccurred => 'Ein Fehler ist aufgetreten';

  @override
  String get strongEncryption => 'Starke Verschlüsselung mit PBKDF2-SHA512';

  @override
  String get editAccount => 'Konto bearbeiten';

  @override
  String get serviceName => 'Dienstname';

  @override
  String get accountName => 'Kontoname';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String deleteAccountConfirm(String issuer) {
    return 'Möchten Sie das Konto $issuer wirklich löschen?';
  }

  @override
  String get actionIrreversible =>
      'Diese Aktion kann nicht rückgängig gemacht werden';

  @override
  String get delete => 'Löschen';

  @override
  String get accountDeleted => 'Konto gelöscht';

  @override
  String get searchAccounts => 'Konten suchen...';

  @override
  String get noAccountsYet => 'Noch keine Konten hinzugefügt';

  @override
  String get addAccountsToImprove =>
      'Fügen Sie Ihre 2FA-Konten hinzu, um\nIhre Sicherheit zu verbessern';

  @override
  String get accountNotFound => 'Konto nicht gefunden';

  @override
  String get addAccount => 'Konto hinzufügen';

  @override
  String get scanQRCode => 'QR-Code scannen';

  @override
  String get useCamera => 'Verwenden Sie Ihre Kamera zum Scannen des QR-Codes';

  @override
  String get or => 'oder';

  @override
  String get manualEntry => 'Manuelle Eingabe';

  @override
  String get serviceNameHint => 'Google, GitHub, Discord...';

  @override
  String get accountNameHint => 'benutzer@beispiel.de';

  @override
  String get secretKey => 'Geheimer Schlüssel';

  @override
  String get secretKeyHint => 'JBSWY3DPEHPK3PXP';

  @override
  String get serviceNameRequired => 'Dienstname ist erforderlich';

  @override
  String get accountNameRequired => 'Kontoname ist erforderlich';

  @override
  String get secretKeyRequired => 'Geheimer Schlüssel ist erforderlich';

  @override
  String get invalidSecretKey => 'Ungültiger geheimer Schlüssel';

  @override
  String get saveAccount => 'Konto speichern';

  @override
  String get errorAddingAccount => 'Fehler beim Hinzufügen des Kontos';

  @override
  String get alignQRCode => 'Richten Sie den QR-Code im Rahmen aus';

  @override
  String get invalidQRCode =>
      'Ungültiger QR-Code. Bitte scannen Sie einen TOTP-QR-Code.';

  @override
  String get qrCode => 'QR-Code';

  @override
  String get qrCodeTransferInfo =>
      'Sie können dieses Konto übertragen, indem Sie diesen QR-Code auf einem anderen Gerät scannen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get darkMode => 'Dunkelmodus';

  @override
  String get useDarkTheme => 'Dunkles Design verwenden';

  @override
  String get systemTheme => 'System';

  @override
  String get lightTheme => 'Hell';

  @override
  String get darkTheme => 'Dunkel';

  @override
  String get themeMode => 'Design';

  @override
  String get security => 'Sicherheit';

  @override
  String get appLock => 'App-Sperre';

  @override
  String get requirePasswordOnLaunch => 'Passwort beim Start erforderlich';

  @override
  String get fingerprintFaceId => 'Fingerabdruck / Face ID';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get setPassword => 'Passwort festlegen';

  @override
  String get advancedSecurity => 'Erweiterte Sicherheit';

  @override
  String get autoLock => 'Automatische Sperre';

  @override
  String get clipboardClear => 'Zwischenablage leeren';

  @override
  String clipboardClearAfterSeconds(int seconds) {
    return 'Nach $seconds Sekunden';
  }

  @override
  String get maxFailedAttemptsLabel => 'Max. fehlgeschlagene Versuche';

  @override
  String attemptsCount(int count) {
    return '$count Versuche';
  }

  @override
  String get wipeOnMaxAttemptsLabel => 'Daten bei Max. Versuchen löschen';

  @override
  String get wipeAllDataOnMax => 'Alle Daten bei max. Versuchen löschen';

  @override
  String get backup => 'Sicherung';

  @override
  String get exportAccounts => 'Konten exportieren';

  @override
  String nAccounts(int count) {
    return '$count Konten';
  }

  @override
  String get importAccounts => 'Konten importieren';

  @override
  String get loadFromJSON => 'Aus JSON-Datei laden';

  @override
  String get dangerZone => 'Gefahrenzone';

  @override
  String get deleteAllData => 'Alle Daten löschen';

  @override
  String get warning => 'Warnung';

  @override
  String wipeWarning(int count) {
    return 'Nach $count fehlgeschlagenen Anmeldeversuchen werden alle Daten automatisch gelöscht. Diese Funktion kann zu unwiderruflichem Datenverlust führen.';
  }

  @override
  String get enable => 'Aktivieren';

  @override
  String get needPasswordFirst => 'Sie müssen zuerst ein Passwort festlegen';

  @override
  String get currentPassword => 'Aktuelles Passwort';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get confirmNewPassword => 'Neues Passwort bestätigen';

  @override
  String get currentPasswordWrong => 'Aktuelles Passwort ist falsch';

  @override
  String get passwordChangedSuccess => 'Passwort erfolgreich geändert';

  @override
  String get deleteAllDataConfirm =>
      'Dadurch werden alle Konten und Einstellungen gelöscht.';

  @override
  String get actionIrreversibleExcl =>
      'Diese Aktion kann nicht rückgängig gemacht werden!';

  @override
  String get allDataDeleted => 'Alle Daten gelöscht';

  @override
  String get disabled => 'Deaktiviert';

  @override
  String nSeconds(int count) {
    return '$count Sekunden';
  }

  @override
  String nMinutes(int count) {
    return '$count Minuten';
  }

  @override
  String get clipboardClearTime => 'Zwischenablage-Löschzeit';

  @override
  String get secureAuthBackup => 'SecureAuth-Sicherung';

  @override
  String get backupFileDescription => 'SecureAuth Konto-Sicherungsdatei';

  @override
  String get accountsExported => 'Konten exportiert';

  @override
  String nAccountsImported(int count) {
    return '$count Konten erfolgreich importiert';
  }

  @override
  String get exportError => 'Exportfehler';

  @override
  String get importError => 'Importfehler';

  @override
  String get aboutEncryption => 'PBKDF2-SHA512 | AES-256 | Vollständig Offline';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get language => 'Sprache';

  @override
  String get selectLanguage => 'Sprache auswählen';

  @override
  String get exportBackup => 'Backup Exportieren';

  @override
  String get encryptedExport => 'Verschlüsselt (Empfohlen)';

  @override
  String get encryptedExportDesc =>
      'Mit AES-256-GCM geschützt. Sicher zum Teilen.';

  @override
  String get unencryptedExport => 'Unverschlüsselt';

  @override
  String get unencryptedExportDesc =>
      'Einfaches JSON. Nur für vertrauenswürdige Orte.';

  @override
  String get setBackupPassword => 'Backup-Passwort Festlegen';

  @override
  String get backupPassword => 'Backup-Passwort';

  @override
  String get confirmBackupPassword => 'Backup-Passwort Bestätigen';

  @override
  String get backupPasswordWarning =>
      'Bewahren Sie dieses Passwort sicher auf. Ohne es kann das Backup nicht geöffnet werden.';

  @override
  String get encryptingBackup => 'Backup wird verschlüsselt...';

  @override
  String get decryptingBackup => 'Backup wird entschlüsselt...';

  @override
  String get decryptBackup => 'Backup Entschlüsseln';

  @override
  String get enterBackupPassword =>
      'Geben Sie das Passwort ein, das Sie beim Exportieren verwendet haben.';

  @override
  String get wrongPasswordOrCorrupted =>
      'Falsches Passwort oder beschädigte Datei';

  @override
  String get loadFromFile => 'Aus JSON oder verschlüsselter .saenc-Datei laden';

  @override
  String get ok => 'OK';

  @override
  String get dataWipedTitle => 'Alle Daten Gelöscht';

  @override
  String get dataWipedBody =>
      'Maximale Anzahl fehlgeschlagener Versuche überschritten.\n\nAlle Konten und Einstellungen wurden aus Sicherheitsgründen dauerhaft gelöscht. Tippen Sie auf OK, um neu zu beginnen.';

  @override
  String get normalDark => 'Dunkel';

  @override
  String get pureDark => 'Reines Dunkel';

  @override
  String get accentColor => 'Akzentfarbe';
}
