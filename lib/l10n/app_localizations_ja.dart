// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'SecureAuth';

  @override
  String get authSubtitle => 'アカウントにアクセスするために\n本人確認を行ってください';

  @override
  String get password => 'パスワード';

  @override
  String get pleaseEnterPassword => 'パスワードを入力してください';

  @override
  String lockedWithTime(String time) {
    return 'ロック中: $time';
  }

  @override
  String failedAttemptsCount(int count) {
    return '$count回の失敗';
  }

  @override
  String get tooManyAttempts => '試行回数が多すぎます。お待ちください。';

  @override
  String wrongPasswordWithRemaining(int remaining) {
    return 'パスワードが違います（残り$remaining回）';
  }

  @override
  String get maxAttemptsExceeded => '最大試行回数を超えました。全データが削除されました。';

  @override
  String get login => 'ログイン';

  @override
  String get biometricLogin => '生体認証でログイン';

  @override
  String codeCopied(int seconds) {
    return 'コードをコピーしました（$seconds秒後に消去）';
  }

  @override
  String minuteShortFormat(int minutes, int seconds) {
    return '$minutes分$seconds秒';
  }

  @override
  String secondShortFormat(int seconds) {
    return '$seconds秒';
  }

  @override
  String get welcome => 'ようこそ';

  @override
  String get setupSubtitle => 'アカウントを安全に保つために\nパスワードを設定してください';

  @override
  String get confirmPassword => 'パスワード確認';

  @override
  String get strengthWeak => '弱い';

  @override
  String get strengthMedium => '普通';

  @override
  String get strengthGood => '良い';

  @override
  String get strengthStrong => '強い';

  @override
  String get strengthVeryStrong => '非常に強い';

  @override
  String get biometricAuth => '生体認証';

  @override
  String get fingerprintOrFace => '指紋または顔認識';

  @override
  String get completeSetup => 'セットアップ完了';

  @override
  String get continueWithoutPassword => 'パスワードなしで続行';

  @override
  String get pleaseSetPassword => 'パスワードを設定してください';

  @override
  String passwordMinLength(int length) {
    return 'パスワードは$length文字以上必要です';
  }

  @override
  String get passwordsDoNotMatch => 'パスワードが一致しません';

  @override
  String get anErrorOccurred => 'エラーが発生しました';

  @override
  String get strongEncryption => 'PBKDF2-SHA512による強力な暗号化';

  @override
  String get editAccount => 'アカウント編集';

  @override
  String get serviceName => 'サービス名';

  @override
  String get accountName => 'アカウント名';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get deleteAccount => 'アカウント削除';

  @override
  String deleteAccountConfirm(String issuer) {
    return '$issuerのアカウントを削除してもよろしいですか？';
  }

  @override
  String get actionIrreversible => 'この操作は元に戻せません';

  @override
  String get delete => '削除';

  @override
  String get accountDeleted => 'アカウントが削除されました';

  @override
  String get searchAccounts => 'アカウントを検索...';

  @override
  String get noAccountsYet => 'まだアカウントがありません';

  @override
  String get addAccountsToImprove => '2FAアカウントを追加して\nセキュリティを強化しましょう';

  @override
  String get accountNotFound => 'アカウントが見つかりません';

  @override
  String get addAccount => 'アカウント追加';

  @override
  String get scanQRCode => 'QRコードをスキャン';

  @override
  String get useCamera => 'カメラでQRコードを読み取ってください';

  @override
  String get or => 'または';

  @override
  String get manualEntry => '手動入力';

  @override
  String get serviceNameHint => 'Google, GitHub, Discord...';

  @override
  String get accountNameHint => 'user@example.com';

  @override
  String get secretKey => 'シークレットキー';

  @override
  String get secretKeyHint => 'JBSWY3DPEHPK3PXP';

  @override
  String get serviceNameRequired => 'サービス名は必須です';

  @override
  String get accountNameRequired => 'アカウント名は必須です';

  @override
  String get secretKeyRequired => 'シークレットキーは必須です';

  @override
  String get invalidSecretKey => '無効なシークレットキー';

  @override
  String get saveAccount => 'アカウントを保存';

  @override
  String get errorAddingAccount => 'アカウントの追加中にエラー';

  @override
  String get alignQRCode => 'QRコードを枠内に合わせてください';

  @override
  String get invalidQRCode => '無効なQRコードです。TOTP QRコードをスキャンしてください。';

  @override
  String get qrCode => 'QRコード';

  @override
  String get qrCodeTransferInfo => 'このQRコードを別のデバイスでスキャンしてアカウントを転送できます';

  @override
  String get settings => '設定';

  @override
  String get appearance => '外観';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get useDarkTheme => 'ダークテーマを使用';

  @override
  String get systemTheme => 'システム';

  @override
  String get lightTheme => 'ライト';

  @override
  String get darkTheme => 'ダーク';

  @override
  String get themeMode => 'テーマ';

  @override
  String get security => 'セキュリティ';

  @override
  String get appLock => 'アプリロック';

  @override
  String get requirePasswordOnLaunch => '起動時にパスワードを要求';

  @override
  String get fingerprintFaceId => '指紋 / Face ID';

  @override
  String get changePassword => 'パスワード変更';

  @override
  String get setPassword => 'パスワード設定';

  @override
  String get advancedSecurity => '高度なセキュリティ';

  @override
  String get autoLock => '自動ロック';

  @override
  String get clipboardClear => 'クリップボード消去';

  @override
  String clipboardClearAfterSeconds(int seconds) {
    return '$seconds秒後';
  }

  @override
  String get maxFailedAttemptsLabel => '最大失敗回数';

  @override
  String attemptsCount(int count) {
    return '$count回';
  }

  @override
  String get wipeOnMaxAttemptsLabel => '最大試行時にデータ消去';

  @override
  String get wipeAllDataOnMax => '最大試行回数で全データを削除';

  @override
  String get backup => 'バックアップ';

  @override
  String get exportAccounts => 'アカウントをエクスポート';

  @override
  String nAccounts(int count) {
    return '$countアカウント';
  }

  @override
  String get importAccounts => 'アカウントをインポート';

  @override
  String get loadFromJSON => 'JSONファイルから読み込み';

  @override
  String get dangerZone => '危険ゾーン';

  @override
  String get deleteAllData => '全データを削除';

  @override
  String get warning => '警告';

  @override
  String wipeWarning(int count) {
    return '$count回のログイン失敗後、全データが自動的に削除されます。この機能は取り消し不能なデータ損失を引き起こす可能性があります。';
  }

  @override
  String get enable => '有効化';

  @override
  String get needPasswordFirst => '先にパスワードを設定する必要があります';

  @override
  String get currentPassword => '現在のパスワード';

  @override
  String get newPassword => '新しいパスワード';

  @override
  String get confirmNewPassword => '新しいパスワード確認';

  @override
  String get currentPasswordWrong => '現在のパスワードが正しくありません';

  @override
  String get passwordChangedSuccess => 'パスワードが正常に変更されました';

  @override
  String get deleteAllDataConfirm => '全てのアカウントと設定が削除されます。';

  @override
  String get actionIrreversibleExcl => 'この操作は元に戻せません！';

  @override
  String get allDataDeleted => '全データが削除されました';

  @override
  String get disabled => '無効';

  @override
  String nSeconds(int count) {
    return '$count秒';
  }

  @override
  String nMinutes(int count) {
    return '$count分';
  }

  @override
  String get clipboardClearTime => 'クリップボード消去時間';

  @override
  String get secureAuthBackup => 'SecureAuthバックアップ';

  @override
  String get backupFileDescription => 'SecureAuthアカウントバックアップファイル';

  @override
  String get accountsExported => 'アカウントがエクスポートされました';

  @override
  String nAccountsImported(int count) {
    return '$countアカウントが正常にインポートされました';
  }

  @override
  String get exportError => 'エクスポートエラー';

  @override
  String get importError => 'インポートエラー';

  @override
  String get aboutEncryption => 'PBKDF2-SHA512 | AES-256 | 完全オフライン';

  @override
  String get edit => '編集';

  @override
  String get language => '言語';

  @override
  String get selectLanguage => '言語を選択';

  @override
  String get exportBackup => 'バックアップのエクスポート';

  @override
  String get encryptedExport => '暗号化（推奨）';

  @override
  String get encryptedExportDesc => 'AES-256-GCMで保護。どこでも安全に共有できます。';

  @override
  String get unencryptedExport => '暗号化なし';

  @override
  String get unencryptedExportDesc => 'プレーンJSON。信頼できる保存場所のみ。';

  @override
  String get setBackupPassword => 'バックアップパスワードの設定';

  @override
  String get backupPassword => 'バックアップパスワード';

  @override
  String get confirmBackupPassword => 'バックアップパスワードを確認';

  @override
  String get backupPasswordWarning =>
      'このパスワードを安全な場所に保存してください。パスワードなしではバックアップを開けません。';

  @override
  String get encryptingBackup => 'バックアップを暗号化中...';

  @override
  String get decryptingBackup => 'バックアップを復号中...';

  @override
  String get decryptBackup => 'バックアップを復号';

  @override
  String get enterBackupPassword => 'このバックアップのエクスポート時に使用したパスワードを入力してください。';

  @override
  String get wrongPasswordOrCorrupted => 'パスワードが違うか、ファイルが破損しています';

  @override
  String get loadFromFile => 'JSONまたは暗号化.saencファイルから読み込む';

  @override
  String get ok => 'OK';

  @override
  String get dataWipedTitle => '全データが削除されました';

  @override
  String get dataWipedBody =>
      'パスワードの最大失敗試行回数を超えました。\n\nセキュリティのため、すべてのアカウントと設定が完全に削除されました。OKをタップして最初からやり直してください。';
}
