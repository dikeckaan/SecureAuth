import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_az.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('az'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('tr'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'SecureAuth'**
  String get appName;

  /// No description provided for @authSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to\naccess your accounts'**
  String get authSubtitle;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @lockedWithTime.
  ///
  /// In en, this message translates to:
  /// **'Locked: {time}'**
  String lockedWithTime(String time);

  /// No description provided for @failedAttemptsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} failed attempt(s)'**
  String failedAttemptsCount(int count);

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please wait.'**
  String get tooManyAttempts;

  /// No description provided for @wrongPasswordWithRemaining.
  ///
  /// In en, this message translates to:
  /// **'Wrong password ({remaining} attempt(s) left)'**
  String wrongPasswordWithRemaining(int remaining);

  /// No description provided for @maxAttemptsExceeded.
  ///
  /// In en, this message translates to:
  /// **'Maximum attempts exceeded. All data deleted.'**
  String get maxAttemptsExceeded;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Login with Biometric'**
  String get biometricLogin;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied ({seconds}s auto-clear)'**
  String codeCopied(int seconds);

  /// No description provided for @minuteShortFormat.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min {seconds} sec'**
  String minuteShortFormat(int minutes, int seconds);

  /// No description provided for @secondShortFormat.
  ///
  /// In en, this message translates to:
  /// **'{seconds} sec'**
  String secondShortFormat(int seconds);

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @setupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set a password to\nkeep your accounts safe'**
  String get setupSubtitle;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @strengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get strengthWeak;

  /// No description provided for @strengthMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get strengthMedium;

  /// No description provided for @strengthGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get strengthGood;

  /// No description provided for @strengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strengthStrong;

  /// No description provided for @strengthVeryStrong.
  ///
  /// In en, this message translates to:
  /// **'Very Strong'**
  String get strengthVeryStrong;

  /// No description provided for @biometricAuth.
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get biometricAuth;

  /// No description provided for @fingerprintOrFace.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint or face recognition'**
  String get fingerprintOrFace;

  /// No description provided for @completeSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get completeSetup;

  /// No description provided for @continueWithoutPassword.
  ///
  /// In en, this message translates to:
  /// **'Continue Without Password'**
  String get continueWithoutPassword;

  /// No description provided for @pleaseSetPassword.
  ///
  /// In en, this message translates to:
  /// **'Please set a password'**
  String get pleaseSetPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {length} characters'**
  String passwordMinLength(int length);

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @anErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get anErrorOccurred;

  /// No description provided for @strongEncryption.
  ///
  /// In en, this message translates to:
  /// **'Strong encryption with PBKDF2-SHA512'**
  String get strongEncryption;

  /// No description provided for @editAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get editAccount;

  /// No description provided for @serviceName.
  ///
  /// In en, this message translates to:
  /// **'Service Name'**
  String get serviceName;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get accountName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the {issuer} account?'**
  String deleteAccountConfirm(String issuer);

  /// No description provided for @actionIrreversible.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get actionIrreversible;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeleted;

  /// No description provided for @searchAccounts.
  ///
  /// In en, this message translates to:
  /// **'Search accounts...'**
  String get searchAccounts;

  /// No description provided for @noAccountsYet.
  ///
  /// In en, this message translates to:
  /// **'No accounts added yet'**
  String get noAccountsYet;

  /// No description provided for @addAccountsToImprove.
  ///
  /// In en, this message translates to:
  /// **'Add your 2FA accounts to\nimprove your security'**
  String get addAccountsToImprove;

  /// No description provided for @accountNotFound.
  ///
  /// In en, this message translates to:
  /// **'Account not found'**
  String get accountNotFound;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get addAccount;

  /// No description provided for @scanQRCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQRCode;

  /// No description provided for @useCamera.
  ///
  /// In en, this message translates to:
  /// **'Use your camera to scan the QR code'**
  String get useCamera;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get manualEntry;

  /// No description provided for @serviceNameHint.
  ///
  /// In en, this message translates to:
  /// **'Google, GitHub, Discord...'**
  String get serviceNameHint;

  /// No description provided for @accountNameHint.
  ///
  /// In en, this message translates to:
  /// **'user@example.com'**
  String get accountNameHint;

  /// No description provided for @secretKey.
  ///
  /// In en, this message translates to:
  /// **'Secret Key'**
  String get secretKey;

  /// No description provided for @secretKeyHint.
  ///
  /// In en, this message translates to:
  /// **'JBSWY3DPEHPK3PXP'**
  String get secretKeyHint;

  /// No description provided for @serviceNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Service name is required'**
  String get serviceNameRequired;

  /// No description provided for @accountNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Account name is required'**
  String get accountNameRequired;

  /// No description provided for @secretKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Secret key is required'**
  String get secretKeyRequired;

  /// No description provided for @invalidSecretKey.
  ///
  /// In en, this message translates to:
  /// **'Invalid secret key'**
  String get invalidSecretKey;

  /// No description provided for @saveAccount.
  ///
  /// In en, this message translates to:
  /// **'Save Account'**
  String get saveAccount;

  /// No description provided for @errorAddingAccount.
  ///
  /// In en, this message translates to:
  /// **'Error adding account'**
  String get errorAddingAccount;

  /// No description provided for @alignQRCode.
  ///
  /// In en, this message translates to:
  /// **'Align the QR code within the frame'**
  String get alignQRCode;

  /// No description provided for @invalidQRCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code. Please scan a TOTP QR code.'**
  String get invalidQRCode;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// No description provided for @qrCodeTransferInfo.
  ///
  /// In en, this message translates to:
  /// **'You can transfer this account by scanning this QR code on another device'**
  String get qrCodeTransferInfo;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @useDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme'**
  String get useDarkTheme;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get appLock;

  /// No description provided for @requirePasswordOnLaunch.
  ///
  /// In en, this message translates to:
  /// **'Require password on launch'**
  String get requirePasswordOnLaunch;

  /// No description provided for @fingerprintFaceId.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint / Face ID'**
  String get fingerprintFaceId;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @setPassword.
  ///
  /// In en, this message translates to:
  /// **'Set Password'**
  String get setPassword;

  /// No description provided for @advancedSecurity.
  ///
  /// In en, this message translates to:
  /// **'Advanced Security'**
  String get advancedSecurity;

  /// No description provided for @autoLock.
  ///
  /// In en, this message translates to:
  /// **'Auto Lock'**
  String get autoLock;

  /// No description provided for @clipboardClear.
  ///
  /// In en, this message translates to:
  /// **'Clipboard Clear'**
  String get clipboardClear;

  /// No description provided for @clipboardClearAfterSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds later'**
  String clipboardClearAfterSeconds(int seconds);

  /// No description provided for @maxFailedAttemptsLabel.
  ///
  /// In en, this message translates to:
  /// **'Max Failed Attempts'**
  String get maxFailedAttemptsLabel;

  /// No description provided for @attemptsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} attempts'**
  String attemptsCount(int count);

  /// No description provided for @wipeOnMaxAttemptsLabel.
  ///
  /// In en, this message translates to:
  /// **'Wipe Data on Max Attempts'**
  String get wipeOnMaxAttemptsLabel;

  /// No description provided for @wipeAllDataOnMax.
  ///
  /// In en, this message translates to:
  /// **'Delete all data on max attempts'**
  String get wipeAllDataOnMax;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @exportAccounts.
  ///
  /// In en, this message translates to:
  /// **'Export Accounts'**
  String get exportAccounts;

  /// No description provided for @nAccounts.
  ///
  /// In en, this message translates to:
  /// **'{count} accounts'**
  String nAccounts(int count);

  /// No description provided for @importAccounts.
  ///
  /// In en, this message translates to:
  /// **'Import Accounts'**
  String get importAccounts;

  /// No description provided for @loadFromJSON.
  ///
  /// In en, this message translates to:
  /// **'Load from JSON file'**
  String get loadFromJSON;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllData;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @wipeWarning.
  ///
  /// In en, this message translates to:
  /// **'After {count} failed login attempts, all data will be automatically deleted. This feature may cause irreversible data loss.'**
  String wipeWarning(int count);

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @needPasswordFirst.
  ///
  /// In en, this message translates to:
  /// **'You need to set a password first'**
  String get needPasswordFirst;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @currentPasswordWrong.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get currentPasswordWrong;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccess;

  /// No description provided for @deleteAllDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will delete all accounts and settings.'**
  String get deleteAllDataConfirm;

  /// No description provided for @actionIrreversibleExcl.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone!'**
  String get actionIrreversibleExcl;

  /// No description provided for @allDataDeleted.
  ///
  /// In en, this message translates to:
  /// **'All data deleted'**
  String get allDataDeleted;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @nSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count} seconds'**
  String nSeconds(int count);

  /// No description provided for @nMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes'**
  String nMinutes(int count);

  /// No description provided for @clipboardClearTime.
  ///
  /// In en, this message translates to:
  /// **'Clipboard Clear Time'**
  String get clipboardClearTime;

  /// No description provided for @secureAuthBackup.
  ///
  /// In en, this message translates to:
  /// **'SecureAuth Backup'**
  String get secureAuthBackup;

  /// No description provided for @backupFileDescription.
  ///
  /// In en, this message translates to:
  /// **'SecureAuth account backup file'**
  String get backupFileDescription;

  /// No description provided for @accountsExported.
  ///
  /// In en, this message translates to:
  /// **'Accounts exported'**
  String get accountsExported;

  /// No description provided for @nAccountsImported.
  ///
  /// In en, this message translates to:
  /// **'{count} accounts imported successfully'**
  String nAccountsImported(int count);

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Export error'**
  String get exportError;

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Import error'**
  String get importError;

  /// No description provided for @aboutEncryption.
  ///
  /// In en, this message translates to:
  /// **'PBKDF2-SHA512 | AES-256 | Fully Offline'**
  String get aboutEncryption;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackup;

  /// No description provided for @encryptedExport.
  ///
  /// In en, this message translates to:
  /// **'Encrypted (Recommended)'**
  String get encryptedExport;

  /// No description provided for @encryptedExportDesc.
  ///
  /// In en, this message translates to:
  /// **'AES-256-GCM protected. Safe to share anywhere.'**
  String get encryptedExportDesc;

  /// No description provided for @unencryptedExport.
  ///
  /// In en, this message translates to:
  /// **'Unencrypted'**
  String get unencryptedExport;

  /// No description provided for @unencryptedExportDesc.
  ///
  /// In en, this message translates to:
  /// **'Plain JSON. For trusted storage only.'**
  String get unencryptedExportDesc;

  /// No description provided for @setBackupPassword.
  ///
  /// In en, this message translates to:
  /// **'Set Backup Password'**
  String get setBackupPassword;

  /// No description provided for @backupPassword.
  ///
  /// In en, this message translates to:
  /// **'Backup Password'**
  String get backupPassword;

  /// No description provided for @confirmBackupPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Backup Password'**
  String get confirmBackupPassword;

  /// No description provided for @backupPasswordWarning.
  ///
  /// In en, this message translates to:
  /// **'Store this password safely. Without it, your backup cannot be recovered.'**
  String get backupPasswordWarning;

  /// No description provided for @encryptingBackup.
  ///
  /// In en, this message translates to:
  /// **'Encrypting backup...'**
  String get encryptingBackup;

  /// No description provided for @decryptingBackup.
  ///
  /// In en, this message translates to:
  /// **'Decrypting backup...'**
  String get decryptingBackup;

  /// No description provided for @decryptBackup.
  ///
  /// In en, this message translates to:
  /// **'Decrypt Backup'**
  String get decryptBackup;

  /// No description provided for @enterBackupPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter the password you used when exporting this backup.'**
  String get enterBackupPassword;

  /// No description provided for @wrongPasswordOrCorrupted.
  ///
  /// In en, this message translates to:
  /// **'Wrong password or corrupted file'**
  String get wrongPasswordOrCorrupted;

  /// No description provided for @loadFromFile.
  ///
  /// In en, this message translates to:
  /// **'Load from JSON or encrypted .saenc file'**
  String get loadFromFile;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @dataWipedTitle.
  ///
  /// In en, this message translates to:
  /// **'All Data Deleted'**
  String get dataWipedTitle;

  /// No description provided for @dataWipedBody.
  ///
  /// In en, this message translates to:
  /// **'Maximum failed password attempts exceeded.\n\nAll your accounts and settings have been permanently deleted for security. Tap OK to start over.'**
  String get dataWipedBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'az',
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'ko',
    'pt',
    'ru',
    'tr',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'az':
      return AppLocalizationsAz();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
