// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'SecureAuth';

  @override
  String get authSubtitle => '계정에 접근하려면\n본인 인증을 해주세요';

  @override
  String get password => '비밀번호';

  @override
  String get pleaseEnterPassword => '비밀번호를 입력해주세요';

  @override
  String lockedWithTime(String time) {
    return '잠금: $time';
  }

  @override
  String failedAttemptsCount(int count) {
    return '$count회 실패';
  }

  @override
  String get tooManyAttempts => '실패 횟수가 너무 많습니다. 잠시 기다려주세요.';

  @override
  String wrongPasswordWithRemaining(int remaining) {
    return '비밀번호가 틀렸습니다 ($remaining회 남음)';
  }

  @override
  String get maxAttemptsExceeded => '최대 시도 횟수 초과. 모든 데이터가 삭제되었습니다.';

  @override
  String get login => '로그인';

  @override
  String get biometricLogin => '생체 인증으로 로그인';

  @override
  String codeCopied(int seconds) {
    return '코드 복사됨 ($seconds초 후 삭제)';
  }

  @override
  String minuteShortFormat(int minutes, int seconds) {
    return '$minutes분 $seconds초';
  }

  @override
  String secondShortFormat(int seconds) {
    return '$seconds초';
  }

  @override
  String get welcome => '환영합니다';

  @override
  String get setupSubtitle => '계정을 안전하게 보호하기 위해\n비밀번호를 설정해주세요';

  @override
  String get confirmPassword => '비밀번호 확인';

  @override
  String get strengthWeak => '약함';

  @override
  String get strengthMedium => '보통';

  @override
  String get strengthGood => '좋음';

  @override
  String get strengthStrong => '강함';

  @override
  String get strengthVeryStrong => '매우 강함';

  @override
  String get biometricAuth => '생체 인증';

  @override
  String get fingerprintOrFace => '지문 또는 얼굴 인식';

  @override
  String get completeSetup => '설정 완료';

  @override
  String get continueWithoutPassword => '비밀번호 없이 계속';

  @override
  String get pleaseSetPassword => '비밀번호를 설정해주세요';

  @override
  String passwordMinLength(int length) {
    return '비밀번호는 최소 $length자 이상이어야 합니다';
  }

  @override
  String get passwordsDoNotMatch => '비밀번호가 일치하지 않습니다';

  @override
  String get anErrorOccurred => '오류가 발생했습니다';

  @override
  String get strongEncryption => 'PBKDF2-SHA512 강력한 암호화';

  @override
  String get editAccount => '계정 편집';

  @override
  String get serviceName => '서비스 이름';

  @override
  String get accountName => '계정 이름';

  @override
  String get cancel => '취소';

  @override
  String get save => '저장';

  @override
  String get deleteAccount => '계정 삭제';

  @override
  String deleteAccountConfirm(String issuer) {
    return '$issuer 계정을 삭제하시겠습니까?';
  }

  @override
  String get actionIrreversible => '이 작업은 되돌릴 수 없습니다';

  @override
  String get delete => '삭제';

  @override
  String get accountDeleted => '계정이 삭제되었습니다';

  @override
  String get searchAccounts => '계정 검색...';

  @override
  String get noAccountsYet => '아직 계정이 없습니다';

  @override
  String get addAccountsToImprove => '2FA 계정을 추가하여\n보안을 강화하세요';

  @override
  String get accountNotFound => '계정을 찾을 수 없습니다';

  @override
  String get addAccount => '계정 추가';

  @override
  String get scanQRCode => 'QR 코드 스캔';

  @override
  String get useCamera => '카메라로 QR 코드를 스캔하세요';

  @override
  String get or => '또는';

  @override
  String get manualEntry => '수동 입력';

  @override
  String get serviceNameHint => 'Google, GitHub, Discord...';

  @override
  String get accountNameHint => 'user@example.com';

  @override
  String get secretKey => '시크릿 키';

  @override
  String get secretKeyHint => 'JBSWY3DPEHPK3PXP';

  @override
  String get serviceNameRequired => '서비스 이름은 필수입니다';

  @override
  String get accountNameRequired => '계정 이름은 필수입니다';

  @override
  String get secretKeyRequired => '시크릿 키는 필수입니다';

  @override
  String get invalidSecretKey => '잘못된 시크릿 키';

  @override
  String get saveAccount => '계정 저장';

  @override
  String get errorAddingAccount => '계정 추가 중 오류';

  @override
  String get alignQRCode => 'QR 코드를 프레임 안에 맞춰주세요';

  @override
  String get invalidQRCode => '잘못된 QR 코드입니다. TOTP QR 코드를 스캔해주세요.';

  @override
  String get qrCode => 'QR 코드';

  @override
  String get qrCodeTransferInfo => '이 QR 코드를 다른 기기에서 스캔하여 계정을 전송할 수 있습니다';

  @override
  String get settings => '설정';

  @override
  String get appearance => '외관';

  @override
  String get darkMode => '다크 모드';

  @override
  String get useDarkTheme => '다크 테마 사용';

  @override
  String get systemTheme => '시스템';

  @override
  String get lightTheme => '라이트';

  @override
  String get darkTheme => '다크';

  @override
  String get themeMode => '테마';

  @override
  String get security => '보안';

  @override
  String get appLock => '앱 잠금';

  @override
  String get requirePasswordOnLaunch => '실행 시 비밀번호 요구';

  @override
  String get fingerprintFaceId => '지문 / Face ID';

  @override
  String get changePassword => '비밀번호 변경';

  @override
  String get setPassword => '비밀번호 설정';

  @override
  String get advancedSecurity => '고급 보안';

  @override
  String get autoLock => '자동 잠금';

  @override
  String get clipboardClear => '클립보드 삭제';

  @override
  String clipboardClearAfterSeconds(int seconds) {
    return '$seconds초 후';
  }

  @override
  String get maxFailedAttemptsLabel => '최대 실패 횟수';

  @override
  String attemptsCount(int count) {
    return '$count회';
  }

  @override
  String get wipeOnMaxAttemptsLabel => '최대 시도 시 데이터 삭제';

  @override
  String get wipeAllDataOnMax => '최대 시도 횟수에서 모든 데이터 삭제';

  @override
  String get backup => '백업';

  @override
  String get exportAccounts => '계정 내보내기';

  @override
  String nAccounts(int count) {
    return '$count개 계정';
  }

  @override
  String get importAccounts => '계정 가져오기';

  @override
  String get loadFromJSON => 'JSON 파일에서 불러오기';

  @override
  String get dangerZone => '위험 구역';

  @override
  String get deleteAllData => '모든 데이터 삭제';

  @override
  String get warning => '경고';

  @override
  String wipeWarning(int count) {
    return '$count회 로그인 실패 후 모든 데이터가 자동으로 삭제됩니다. 이 기능은 복구 불가능한 데이터 손실을 초래할 수 있습니다.';
  }

  @override
  String get enable => '활성화';

  @override
  String get needPasswordFirst => '먼저 비밀번호를 설정해야 합니다';

  @override
  String get currentPassword => '현재 비밀번호';

  @override
  String get newPassword => '새 비밀번호';

  @override
  String get confirmNewPassword => '새 비밀번호 확인';

  @override
  String get currentPasswordWrong => '현재 비밀번호가 올바르지 않습니다';

  @override
  String get passwordChangedSuccess => '비밀번호가 성공적으로 변경되었습니다';

  @override
  String get deleteAllDataConfirm => '모든 계정과 설정이 삭제됩니다.';

  @override
  String get actionIrreversibleExcl => '이 작업은 되돌릴 수 없습니다!';

  @override
  String get allDataDeleted => '모든 데이터가 삭제되었습니다';

  @override
  String get disabled => '비활성화';

  @override
  String nSeconds(int count) {
    return '$count초';
  }

  @override
  String nMinutes(int count) {
    return '$count분';
  }

  @override
  String get clipboardClearTime => '클립보드 삭제 시간';

  @override
  String get secureAuthBackup => 'SecureAuth 백업';

  @override
  String get backupFileDescription => 'SecureAuth 계정 백업 파일';

  @override
  String get accountsExported => '계정이 내보내졌습니다';

  @override
  String nAccountsImported(int count) {
    return '$count개 계정이 성공적으로 가져왔습니다';
  }

  @override
  String get exportError => '내보내기 오류';

  @override
  String get importError => '가져오기 오류';

  @override
  String get aboutEncryption => 'PBKDF2-SHA512 | AES-256 | 완전 오프라인';

  @override
  String get edit => '편집';

  @override
  String get language => '언어';

  @override
  String get selectLanguage => '언어 선택';

  @override
  String get exportBackup => '백업 내보내기';

  @override
  String get encryptedExport => '암호화됨 (권장)';

  @override
  String get encryptedExportDesc =>
      'AES-256-GCM으로 보호됩니다. 어디서든 안전하게 공유할 수 있습니다.';

  @override
  String get unencryptedExport => '암호화되지 않음';

  @override
  String get unencryptedExportDesc => '일반 JSON. 신뢰할 수 있는 저장소에만 사용하세요.';

  @override
  String get setBackupPassword => '백업 비밀번호 설정';

  @override
  String get backupPassword => '백업 비밀번호';

  @override
  String get confirmBackupPassword => '백업 비밀번호 확인';

  @override
  String get backupPasswordWarning =>
      '이 비밀번호를 안전한 곳에 보관하세요. 비밀번호 없이는 백업을 열 수 없습니다.';

  @override
  String get encryptingBackup => '백업 암호화 중...';

  @override
  String get decryptingBackup => '백업 복호화 중...';

  @override
  String get decryptBackup => '백업 복호화';

  @override
  String get enterBackupPassword => '이 백업을 내보낼 때 사용한 비밀번호를 입력하세요.';

  @override
  String get wrongPasswordOrCorrupted => '잘못된 비밀번호 또는 손상된 파일';

  @override
  String get loadFromFile => 'JSON 또는 암호화된 .saenc 파일에서 불러오기';

  @override
  String get ok => '확인';

  @override
  String get dataWipedTitle => '모든 데이터 삭제됨';

  @override
  String get dataWipedBody =>
      '최대 비밀번호 시도 횟수를 초과했습니다.\n\n보안을 위해 모든 계정과 설정이 영구적으로 삭제되었습니다. 확인을 탭하여 처음부터 시작하세요.';
}
