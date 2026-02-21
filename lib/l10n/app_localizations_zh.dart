// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'SecureAuth';

  @override
  String get authSubtitle => '验证您的身份\n以访问您的账户';

  @override
  String get password => '密码';

  @override
  String get pleaseEnterPassword => '请输入密码';

  @override
  String lockedWithTime(String time) {
    return '已锁定: $time';
  }

  @override
  String failedAttemptsCount(int count) {
    return '$count次失败尝试';
  }

  @override
  String get tooManyAttempts => '失败次数过多，请稍候。';

  @override
  String wrongPasswordWithRemaining(int remaining) {
    return '密码错误（剩余$remaining次机会）';
  }

  @override
  String get maxAttemptsExceeded => '已超过最大尝试次数。所有数据已删除。';

  @override
  String get login => '登录';

  @override
  String get biometricLogin => '生物识别登录';

  @override
  String codeCopied(int seconds) {
    return '验证码已复制（$seconds秒后清除）';
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
  String get welcome => '欢迎';

  @override
  String get setupSubtitle => '设置密码\n保护您的账户安全';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get strengthWeak => '弱';

  @override
  String get strengthMedium => '中等';

  @override
  String get strengthGood => '良好';

  @override
  String get strengthStrong => '强';

  @override
  String get strengthVeryStrong => '非常强';

  @override
  String get biometricAuth => '生物识别认证';

  @override
  String get fingerprintOrFace => '指纹或面部识别';

  @override
  String get completeSetup => '完成设置';

  @override
  String get continueWithoutPassword => '不设密码继续';

  @override
  String get pleaseSetPassword => '请设置密码';

  @override
  String passwordMinLength(int length) {
    return '密码至少需要$length个字符';
  }

  @override
  String get passwordsDoNotMatch => '密码不匹配';

  @override
  String get anErrorOccurred => '发生错误';

  @override
  String get strongEncryption => 'PBKDF2-SHA512强加密';

  @override
  String get editAccount => '编辑账户';

  @override
  String get serviceName => '服务名称';

  @override
  String get accountName => '账户名称';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get deleteAccount => '删除账户';

  @override
  String deleteAccountConfirm(String issuer) {
    return '确定要删除$issuer账户吗？';
  }

  @override
  String get actionIrreversible => '此操作无法撤销';

  @override
  String get delete => '删除';

  @override
  String get accountDeleted => '账户已删除';

  @override
  String get searchAccounts => '搜索账户...';

  @override
  String get noAccountsYet => '尚未添加账户';

  @override
  String get addAccountsToImprove => '添加您的2FA账户\n提升安全性';

  @override
  String get accountNotFound => '未找到账户';

  @override
  String get addAccount => '添加账户';

  @override
  String get scanQRCode => '扫描二维码';

  @override
  String get useCamera => '使用相机扫描二维码';

  @override
  String get or => '或';

  @override
  String get manualEntry => '手动输入';

  @override
  String get serviceNameHint => 'Google, GitHub, Discord...';

  @override
  String get accountNameHint => 'user@example.com';

  @override
  String get secretKey => '密钥';

  @override
  String get secretKeyHint => 'JBSWY3DPEHPK3PXP';

  @override
  String get serviceNameRequired => '服务名称为必填';

  @override
  String get accountNameRequired => '账户名称为必填';

  @override
  String get secretKeyRequired => '密钥为必填';

  @override
  String get invalidSecretKey => '无效的密钥';

  @override
  String get saveAccount => '保存账户';

  @override
  String get errorAddingAccount => '添加账户时出错';

  @override
  String get alignQRCode => '将二维码对准框内';

  @override
  String get invalidQRCode => '无效的二维码。请扫描TOTP二维码。';

  @override
  String get qrCode => '二维码';

  @override
  String get qrCodeTransferInfo => '您可以在其他设备上扫描此二维码来转移账户';

  @override
  String get settings => '设置';

  @override
  String get appearance => '外观';

  @override
  String get darkMode => '深色模式';

  @override
  String get useDarkTheme => '使用深色主题';

  @override
  String get systemTheme => '跟随系统';

  @override
  String get lightTheme => '浅色';

  @override
  String get darkTheme => '深色';

  @override
  String get themeMode => '主题';

  @override
  String get security => '安全';

  @override
  String get appLock => '应用锁定';

  @override
  String get requirePasswordOnLaunch => '启动时要求输入密码';

  @override
  String get fingerprintFaceId => '指纹 / Face ID';

  @override
  String get changePassword => '更改密码';

  @override
  String get setPassword => '设置密码';

  @override
  String get advancedSecurity => '高级安全';

  @override
  String get autoLock => '自动锁定';

  @override
  String get clipboardClear => '剪贴板清除';

  @override
  String clipboardClearAfterSeconds(int seconds) {
    return '$seconds秒后';
  }

  @override
  String get maxFailedAttemptsLabel => '最大失败次数';

  @override
  String attemptsCount(int count) {
    return '$count次';
  }

  @override
  String get wipeOnMaxAttemptsLabel => '超限时删除数据';

  @override
  String get wipeAllDataOnMax => '达到最大次数时删除所有数据';

  @override
  String get backup => '备份';

  @override
  String get exportAccounts => '导出账户';

  @override
  String nAccounts(int count) {
    return '$count个账户';
  }

  @override
  String get importAccounts => '导入账户';

  @override
  String get loadFromJSON => '从JSON文件加载';

  @override
  String get dangerZone => '危险区域';

  @override
  String get deleteAllData => '删除所有数据';

  @override
  String get warning => '警告';

  @override
  String wipeWarning(int count) {
    return '$count次登录失败后，所有数据将被自动删除。此功能可能导致不可恢复的数据丢失。';
  }

  @override
  String get enable => '启用';

  @override
  String get needPasswordFirst => '需要先设置密码';

  @override
  String get currentPassword => '当前密码';

  @override
  String get newPassword => '新密码';

  @override
  String get confirmNewPassword => '确认新密码';

  @override
  String get currentPasswordWrong => '当前密码不正确';

  @override
  String get passwordChangedSuccess => '密码修改成功';

  @override
  String get deleteAllDataConfirm => '这将删除所有账户和设置。';

  @override
  String get actionIrreversibleExcl => '此操作无法撤销！';

  @override
  String get allDataDeleted => '所有数据已删除';

  @override
  String get disabled => '已禁用';

  @override
  String nSeconds(int count) {
    return '$count秒';
  }

  @override
  String nMinutes(int count) {
    return '$count分钟';
  }

  @override
  String get clipboardClearTime => '剪贴板清除时间';

  @override
  String get secureAuthBackup => 'SecureAuth备份';

  @override
  String get backupFileDescription => 'SecureAuth账户备份文件';

  @override
  String get accountsExported => '账户已导出';

  @override
  String nAccountsImported(int count) {
    return '$count个账户导入成功';
  }

  @override
  String get exportError => '导出错误';

  @override
  String get importError => '导入错误';

  @override
  String get aboutEncryption => 'PBKDF2-SHA512 | AES-256 | 完全离线';

  @override
  String get edit => '编辑';

  @override
  String get language => '语言';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get exportBackup => '导出备份';

  @override
  String get encryptedExport => '加密（推荐）';

  @override
  String get encryptedExportDesc => 'AES-256-GCM保护，可安全分享。';

  @override
  String get unencryptedExport => '未加密';

  @override
  String get unencryptedExportDesc => '纯JSON格式，仅用于可信存储。';

  @override
  String get setBackupPassword => '设置备份密码';

  @override
  String get backupPassword => '备份密码';

  @override
  String get confirmBackupPassword => '确认备份密码';

  @override
  String get backupPasswordWarning => '请将此密码保存在安全的地方。没有密码，您将无法打开备份。';

  @override
  String get encryptingBackup => '正在加密备份...';

  @override
  String get decryptingBackup => '正在解密备份...';

  @override
  String get decryptBackup => '解密备份';

  @override
  String get enterBackupPassword => '请输入导出此备份时使用的密码。';

  @override
  String get wrongPasswordOrCorrupted => '密码错误或文件已损坏';

  @override
  String get loadFromFile => '从JSON或加密的.saenc文件加载';

  @override
  String get ok => '确定';

  @override
  String get dataWipedTitle => '所有数据已删除';

  @override
  String get dataWipedBody => '超过最大密码尝试次数。\n\n为了安全，所有账户和设置已被永久删除。点击确定重新开始。';

  @override
  String get normalDark => '深色';

  @override
  String get pureDark => '纯黑';

  @override
  String get accentColor => '主题色';
}
