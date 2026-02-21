// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'SecureAuth';

  @override
  String get authSubtitle =>
      'Vérifiez votre identité pour\naccéder à vos comptes';

  @override
  String get password => 'Mot de passe';

  @override
  String get pleaseEnterPassword => 'Veuillez entrer votre mot de passe';

  @override
  String lockedWithTime(String time) {
    return 'Verrouillé : $time';
  }

  @override
  String failedAttemptsCount(int count) {
    return '$count tentatives échouées';
  }

  @override
  String get tooManyAttempts =>
      'Trop de tentatives échouées. Veuillez patienter.';

  @override
  String wrongPasswordWithRemaining(int remaining) {
    return 'Mot de passe incorrect ($remaining tentatives restantes)';
  }

  @override
  String get maxAttemptsExceeded =>
      'Nombre maximum de tentatives dépassé. Toutes les données supprimées.';

  @override
  String get login => 'Se connecter';

  @override
  String get biometricLogin => 'Connexion biométrique';

  @override
  String codeCopied(int seconds) {
    return 'Code copié (effacement dans ${seconds}s)';
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
  String get welcome => 'Bienvenue';

  @override
  String get setupSubtitle =>
      'Définissez un mot de passe pour\nprotéger vos comptes';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get strengthWeak => 'Faible';

  @override
  String get strengthMedium => 'Moyen';

  @override
  String get strengthGood => 'Bon';

  @override
  String get strengthStrong => 'Fort';

  @override
  String get strengthVeryStrong => 'Très Fort';

  @override
  String get biometricAuth => 'Authentification biométrique';

  @override
  String get fingerprintOrFace =>
      'Empreinte digitale ou reconnaissance faciale';

  @override
  String get completeSetup => 'Terminer la configuration';

  @override
  String get continueWithoutPassword => 'Continuer sans mot de passe';

  @override
  String get pleaseSetPassword => 'Veuillez définir un mot de passe';

  @override
  String passwordMinLength(int length) {
    return 'Le mot de passe doit contenir au moins $length caractères';
  }

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get anErrorOccurred => 'Une erreur est survenue';

  @override
  String get strongEncryption => 'Chiffrement fort avec PBKDF2-SHA512';

  @override
  String get editAccount => 'Modifier le compte';

  @override
  String get serviceName => 'Nom du service';

  @override
  String get accountName => 'Nom du compte';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String deleteAccountConfirm(String issuer) {
    return 'Êtes-vous sûr de vouloir supprimer le compte $issuer ?';
  }

  @override
  String get actionIrreversible => 'Cette action est irréversible';

  @override
  String get delete => 'Supprimer';

  @override
  String get accountDeleted => 'Compte supprimé';

  @override
  String get searchAccounts => 'Rechercher des comptes...';

  @override
  String get noAccountsYet => 'Aucun compte ajouté';

  @override
  String get addAccountsToImprove =>
      'Ajoutez vos comptes 2FA pour\naméliorer votre sécurité';

  @override
  String get accountNotFound => 'Compte introuvable';

  @override
  String get addAccount => 'Ajouter un compte';

  @override
  String get scanQRCode => 'Scanner le code QR';

  @override
  String get useCamera => 'Utilisez votre caméra pour scanner le code QR';

  @override
  String get or => 'ou';

  @override
  String get manualEntry => 'Saisie manuelle';

  @override
  String get serviceNameHint => 'Google, GitHub, Discord...';

  @override
  String get accountNameHint => 'utilisateur@exemple.com';

  @override
  String get secretKey => 'Clé secrète';

  @override
  String get secretKeyHint => 'JBSWY3DPEHPK3PXP';

  @override
  String get serviceNameRequired => 'Le nom du service est requis';

  @override
  String get accountNameRequired => 'Le nom du compte est requis';

  @override
  String get secretKeyRequired => 'La clé secrète est requise';

  @override
  String get invalidSecretKey => 'Clé secrète invalide';

  @override
  String get saveAccount => 'Enregistrer le compte';

  @override
  String get errorAddingAccount => 'Erreur lors de l\'ajout du compte';

  @override
  String get alignQRCode => 'Alignez le code QR dans le cadre';

  @override
  String get invalidQRCode =>
      'Code QR invalide. Veuillez scanner un code QR TOTP.';

  @override
  String get qrCode => 'Code QR';

  @override
  String get qrCodeTransferInfo =>
      'Vous pouvez transférer ce compte en scannant ce code QR sur un autre appareil';

  @override
  String get settings => 'Paramètres';

  @override
  String get appearance => 'Apparence';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get useDarkTheme => 'Utiliser le thème sombre';

  @override
  String get systemTheme => 'Système';

  @override
  String get lightTheme => 'Clair';

  @override
  String get darkTheme => 'Sombre';

  @override
  String get themeMode => 'Thème';

  @override
  String get security => 'Sécurité';

  @override
  String get appLock => 'Verrouillage de l\'app';

  @override
  String get requirePasswordOnLaunch => 'Exiger le mot de passe au lancement';

  @override
  String get fingerprintFaceId => 'Empreinte / Face ID';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get setPassword => 'Définir le mot de passe';

  @override
  String get advancedSecurity => 'Sécurité avancée';

  @override
  String get autoLock => 'Verrouillage automatique';

  @override
  String get clipboardClear => 'Effacement du presse-papiers';

  @override
  String clipboardClearAfterSeconds(int seconds) {
    return 'Après $seconds secondes';
  }

  @override
  String get maxFailedAttemptsLabel => 'Max. tentatives échouées';

  @override
  String attemptsCount(int count) {
    return '$count tentatives';
  }

  @override
  String get wipeOnMaxAttemptsLabel => 'Effacer les données au max.';

  @override
  String get wipeAllDataOnMax => 'Supprimer toutes les données au max.';

  @override
  String get backup => 'Sauvegarde';

  @override
  String get exportAccounts => 'Exporter les comptes';

  @override
  String nAccounts(int count) {
    return '$count comptes';
  }

  @override
  String get importAccounts => 'Importer des comptes';

  @override
  String get loadFromJSON => 'Charger depuis un fichier JSON';

  @override
  String get dangerZone => 'Zone dangereuse';

  @override
  String get deleteAllData => 'Supprimer toutes les données';

  @override
  String get warning => 'Attention';

  @override
  String wipeWarning(int count) {
    return 'Après $count tentatives de connexion échouées, toutes les données seront automatiquement supprimées. Cette fonction peut entraîner une perte de données irréversible.';
  }

  @override
  String get enable => 'Activer';

  @override
  String get needPasswordFirst => 'Vous devez d\'abord définir un mot de passe';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmNewPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get currentPasswordWrong => 'Le mot de passe actuel est incorrect';

  @override
  String get passwordChangedSuccess => 'Mot de passe modifié avec succès';

  @override
  String get deleteAllDataConfirm =>
      'Cela supprimera tous les comptes et paramètres.';

  @override
  String get actionIrreversibleExcl => 'Cette action est irréversible !';

  @override
  String get allDataDeleted => 'Toutes les données supprimées';

  @override
  String get disabled => 'Désactivé';

  @override
  String nSeconds(int count) {
    return '$count secondes';
  }

  @override
  String nMinutes(int count) {
    return '$count minutes';
  }

  @override
  String get clipboardClearTime => 'Délai d\'effacement du presse-papiers';

  @override
  String get secureAuthBackup => 'Sauvegarde SecureAuth';

  @override
  String get backupFileDescription =>
      'Fichier de sauvegarde des comptes SecureAuth';

  @override
  String get accountsExported => 'Comptes exportés';

  @override
  String nAccountsImported(int count) {
    return '$count comptes importés avec succès';
  }

  @override
  String get exportError => 'Erreur d\'exportation';

  @override
  String get importError => 'Erreur d\'importation';

  @override
  String get aboutEncryption =>
      'PBKDF2-SHA512 | AES-256 | Entièrement Hors Ligne';

  @override
  String get edit => 'Modifier';

  @override
  String get language => 'Langue';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get exportBackup => 'Exporter la Sauvegarde';

  @override
  String get encryptedExport => 'Chiffré (Recommandé)';

  @override
  String get encryptedExportDesc =>
      'Protégé par AES-256-GCM. Sûr à partager partout.';

  @override
  String get unencryptedExport => 'Non Chiffré';

  @override
  String get unencryptedExportDesc =>
      'JSON simple. Pour stockage de confiance uniquement.';

  @override
  String get setBackupPassword => 'Définir le Mot de Passe de Sauvegarde';

  @override
  String get backupPassword => 'Mot de Passe de Sauvegarde';

  @override
  String get confirmBackupPassword => 'Confirmer le Mot de Passe de Sauvegarde';

  @override
  String get backupPasswordWarning =>
      'Conservez ce mot de passe en lieu sûr. Sans lui, votre sauvegarde ne peut être ouverte.';

  @override
  String get encryptingBackup => 'Chiffrement de la sauvegarde...';

  @override
  String get decryptingBackup => 'Déchiffrement de la sauvegarde...';

  @override
  String get decryptBackup => 'Déchiffrer la Sauvegarde';

  @override
  String get enterBackupPassword =>
      'Entrez le mot de passe utilisé lors de l\'exportation de cette sauvegarde.';

  @override
  String get wrongPasswordOrCorrupted =>
      'Mot de passe incorrect ou fichier corrompu';

  @override
  String get loadFromFile => 'Charger depuis un fichier JSON ou .saenc chiffré';

  @override
  String get ok => 'OK';

  @override
  String get dataWipedTitle => 'Toutes les données supprimées';

  @override
  String get dataWipedBody =>
      'Nombre maximum de tentatives échouées dépassé.\n\nTous vos comptes et paramètres ont été définitivement supprimés. Appuyez sur OK pour recommencer.';

  @override
  String get normalDark => 'Sombre';

  @override
  String get pureDark => 'Noir pur';

  @override
  String get accentColor => 'Couleur d\'accent';
}
