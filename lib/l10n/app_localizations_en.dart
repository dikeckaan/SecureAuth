// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SecureAuth';

  @override
  String get authSubtitle => 'Verify your identity to\naccess your accounts';

  @override
  String get password => 'Password';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String lockedWithTime(String time) {
    return 'Locked: $time';
  }

  @override
  String failedAttemptsCount(int count) {
    return '$count failed attempt(s)';
  }

  @override
  String get tooManyAttempts => 'Too many failed attempts. Please wait.';

  @override
  String wrongPasswordWithRemaining(int remaining) {
    return 'Wrong password ($remaining attempt(s) left)';
  }

  @override
  String get maxAttemptsExceeded =>
      'Maximum attempts exceeded. All data deleted.';

  @override
  String get login => 'Login';

  @override
  String get biometricLogin => 'Login with Biometric';

  @override
  String codeCopied(int seconds) {
    return 'Code copied (${seconds}s auto-clear)';
  }

  @override
  String minuteShortFormat(int minutes, int seconds) {
    return '$minutes min $seconds sec';
  }

  @override
  String secondShortFormat(int seconds) {
    return '$seconds sec';
  }

  @override
  String get welcome => 'Welcome';

  @override
  String get setupSubtitle => 'Set a password to\nkeep your accounts safe';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get strengthWeak => 'Weak';

  @override
  String get strengthMedium => 'Medium';

  @override
  String get strengthGood => 'Good';

  @override
  String get strengthStrong => 'Strong';

  @override
  String get strengthVeryStrong => 'Very Strong';

  @override
  String get biometricAuth => 'Biometric Authentication';

  @override
  String get fingerprintOrFace => 'Fingerprint or face recognition';

  @override
  String get completeSetup => 'Complete Setup';

  @override
  String get continueWithoutPassword => 'Continue Without Password';

  @override
  String get pleaseSetPassword => 'Please set a password';

  @override
  String passwordMinLength(int length) {
    return 'Password must be at least $length characters';
  }

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get anErrorOccurred => 'An error occurred';

  @override
  String get strongEncryption => 'Strong encryption with PBKDF2-SHA512';

  @override
  String get editAccount => 'Edit Account';

  @override
  String get serviceName => 'Service Name';

  @override
  String get accountName => 'Account Name';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String deleteAccountConfirm(String issuer) {
    return 'Are you sure you want to delete the $issuer account?';
  }

  @override
  String get actionIrreversible => 'This action cannot be undone';

  @override
  String get delete => 'Delete';

  @override
  String get accountDeleted => 'Account deleted';

  @override
  String get searchAccounts => 'Search accounts...';

  @override
  String get noAccountsYet => 'No accounts added yet';

  @override
  String get addAccountsToImprove =>
      'Add your 2FA accounts to\nimprove your security';

  @override
  String get accountNotFound => 'Account not found';

  @override
  String get addAccount => 'Add Account';

  @override
  String get scanQRCode => 'Scan QR Code';

  @override
  String get useCamera => 'Use your camera to scan the QR code';

  @override
  String get or => 'or';

  @override
  String get manualEntry => 'Manual Entry';

  @override
  String get serviceNameHint => 'Google, GitHub, Discord...';

  @override
  String get accountNameHint => 'user@example.com';

  @override
  String get secretKey => 'Secret Key';

  @override
  String get secretKeyHint => 'JBSWY3DPEHPK3PXP';

  @override
  String get serviceNameRequired => 'Service name is required';

  @override
  String get accountNameRequired => 'Account name is required';

  @override
  String get secretKeyRequired => 'Secret key is required';

  @override
  String get invalidSecretKey => 'Invalid secret key';

  @override
  String get saveAccount => 'Save Account';

  @override
  String get errorAddingAccount => 'Error adding account';

  @override
  String get alignQRCode => 'Align the QR code within the frame';

  @override
  String get invalidQRCode => 'Invalid QR code. Please scan a TOTP QR code.';

  @override
  String get qrCode => 'QR Code';

  @override
  String get qrCodeTransferInfo =>
      'You can transfer this account by scanning this QR code on another device';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get useDarkTheme => 'Use dark theme';

  @override
  String get security => 'Security';

  @override
  String get appLock => 'App Lock';

  @override
  String get requirePasswordOnLaunch => 'Require password on launch';

  @override
  String get fingerprintFaceId => 'Fingerprint / Face ID';

  @override
  String get changePassword => 'Change Password';

  @override
  String get setPassword => 'Set Password';

  @override
  String get advancedSecurity => 'Advanced Security';

  @override
  String get autoLock => 'Auto Lock';

  @override
  String get clipboardClear => 'Clipboard Clear';

  @override
  String clipboardClearAfterSeconds(int seconds) {
    return '$seconds seconds later';
  }

  @override
  String get maxFailedAttemptsLabel => 'Max Failed Attempts';

  @override
  String attemptsCount(int count) {
    return '$count attempts';
  }

  @override
  String get wipeOnMaxAttemptsLabel => 'Wipe Data on Max Attempts';

  @override
  String get wipeAllDataOnMax => 'Delete all data on max attempts';

  @override
  String get backup => 'Backup';

  @override
  String get exportAccounts => 'Export Accounts';

  @override
  String nAccounts(int count) {
    return '$count accounts';
  }

  @override
  String get importAccounts => 'Import Accounts';

  @override
  String get loadFromJSON => 'Load from JSON file';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get deleteAllData => 'Delete All Data';

  @override
  String get warning => 'Warning';

  @override
  String wipeWarning(int count) {
    return 'After $count failed login attempts, all data will be automatically deleted. This feature may cause irreversible data loss.';
  }

  @override
  String get enable => 'Enable';

  @override
  String get needPasswordFirst => 'You need to set a password first';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get currentPasswordWrong => 'Current password is incorrect';

  @override
  String get passwordChangedSuccess => 'Password changed successfully';

  @override
  String get deleteAllDataConfirm =>
      'This will delete all accounts and settings.';

  @override
  String get actionIrreversibleExcl => 'This action cannot be undone!';

  @override
  String get allDataDeleted => 'All data deleted';

  @override
  String get disabled => 'Disabled';

  @override
  String nSeconds(int count) {
    return '$count seconds';
  }

  @override
  String nMinutes(int count) {
    return '$count minutes';
  }

  @override
  String get clipboardClearTime => 'Clipboard Clear Time';

  @override
  String get secureAuthBackup => 'SecureAuth Backup';

  @override
  String get backupFileDescription => 'SecureAuth account backup file';

  @override
  String get accountsExported => 'Accounts exported';

  @override
  String nAccountsImported(int count) {
    return '$count accounts imported successfully';
  }

  @override
  String get exportError => 'Export error';

  @override
  String get importError => 'Import error';

  @override
  String get aboutEncryption => 'PBKDF2-SHA512 | AES-256 | Fully Offline';

  @override
  String get edit => 'Edit';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get exportBackup => 'Export Backup';

  @override
  String get encryptedExport => 'Encrypted (Recommended)';

  @override
  String get encryptedExportDesc =>
      'AES-256-GCM protected. Safe to share anywhere.';

  @override
  String get unencryptedExport => 'Unencrypted';

  @override
  String get unencryptedExportDesc => 'Plain JSON. For trusted storage only.';

  @override
  String get setBackupPassword => 'Set Backup Password';

  @override
  String get backupPassword => 'Backup Password';

  @override
  String get confirmBackupPassword => 'Confirm Backup Password';

  @override
  String get backupPasswordWarning =>
      'Store this password safely. Without it, your backup cannot be recovered.';

  @override
  String get encryptingBackup => 'Encrypting backup...';

  @override
  String get decryptingBackup => 'Decrypting backup...';

  @override
  String get decryptBackup => 'Decrypt Backup';

  @override
  String get enterBackupPassword =>
      'Enter the password you used when exporting this backup.';

  @override
  String get wrongPasswordOrCorrupted => 'Wrong password or corrupted file';

  @override
  String get loadFromFile => 'Load from JSON or encrypted .saenc file';

  @override
  String get ok => 'OK';

  @override
  String get dataWipedTitle => 'All Data Deleted';

  @override
  String get dataWipedBody =>
      'Maximum failed password attempts exceeded.\n\nAll your accounts and settings have been permanently deleted for security. Tap OK to start over.';
}
