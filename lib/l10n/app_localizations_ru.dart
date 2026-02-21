// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'SecureAuth';

  @override
  String get authSubtitle =>
      'Подтвердите свою личность для\nдоступа к аккаунтам';

  @override
  String get password => 'Пароль';

  @override
  String get pleaseEnterPassword => 'Пожалуйста, введите пароль';

  @override
  String lockedWithTime(String time) {
    return 'Заблокировано: $time';
  }

  @override
  String failedAttemptsCount(int count) {
    return '$count неудачных попыток';
  }

  @override
  String get tooManyAttempts => 'Слишком много неудачных попыток. Подождите.';

  @override
  String wrongPasswordWithRemaining(int remaining) {
    return 'Неверный пароль (осталось $remaining попыток)';
  }

  @override
  String get maxAttemptsExceeded =>
      'Максимум попыток превышен. Все данные удалены.';

  @override
  String get login => 'Войти';

  @override
  String get biometricLogin => 'Вход по биометрии';

  @override
  String codeCopied(int seconds) {
    return 'Код скопирован (очистка через $secondsс)';
  }

  @override
  String minuteShortFormat(int minutes, int seconds) {
    return '$minutes мин $seconds сек';
  }

  @override
  String secondShortFormat(int seconds) {
    return '$seconds сек';
  }

  @override
  String get welcome => 'Добро пожаловать';

  @override
  String get setupSubtitle => 'Установите пароль для\nзащиты ваших аккаунтов';

  @override
  String get confirmPassword => 'Подтвердите пароль';

  @override
  String get strengthWeak => 'Слабый';

  @override
  String get strengthMedium => 'Средний';

  @override
  String get strengthGood => 'Хороший';

  @override
  String get strengthStrong => 'Сильный';

  @override
  String get strengthVeryStrong => 'Очень сильный';

  @override
  String get biometricAuth => 'Биометрическая аутентификация';

  @override
  String get fingerprintOrFace => 'Отпечаток пальца или распознавание лица';

  @override
  String get completeSetup => 'Завершить настройку';

  @override
  String get continueWithoutPassword => 'Продолжить без пароля';

  @override
  String get pleaseSetPassword => 'Пожалуйста, установите пароль';

  @override
  String passwordMinLength(int length) {
    return 'Пароль должен быть не менее $length символов';
  }

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get anErrorOccurred => 'Произошла ошибка';

  @override
  String get strongEncryption => 'Надёжное шифрование PBKDF2-SHA512';

  @override
  String get editAccount => 'Редактировать аккаунт';

  @override
  String get serviceName => 'Название сервиса';

  @override
  String get accountName => 'Имя аккаунта';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String deleteAccountConfirm(String issuer) {
    return 'Вы уверены, что хотите удалить аккаунт $issuer?';
  }

  @override
  String get actionIrreversible => 'Это действие нельзя отменить';

  @override
  String get delete => 'Удалить';

  @override
  String get accountDeleted => 'Аккаунт удалён';

  @override
  String get searchAccounts => 'Поиск аккаунтов...';

  @override
  String get noAccountsYet => 'Аккаунты ещё не добавлены';

  @override
  String get addAccountsToImprove =>
      'Добавьте аккаунты 2FA для\nповышения безопасности';

  @override
  String get accountNotFound => 'Аккаунт не найден';

  @override
  String get addAccount => 'Добавить аккаунт';

  @override
  String get scanQRCode => 'Сканировать QR-код';

  @override
  String get useCamera => 'Используйте камеру для сканирования QR-кода';

  @override
  String get or => 'или';

  @override
  String get manualEntry => 'Ручной ввод';

  @override
  String get serviceNameHint => 'Google, GitHub, Discord...';

  @override
  String get accountNameHint => 'user@example.com';

  @override
  String get secretKey => 'Секретный ключ';

  @override
  String get secretKeyHint => 'JBSWY3DPEHPK3PXP';

  @override
  String get serviceNameRequired => 'Название сервиса обязательно';

  @override
  String get accountNameRequired => 'Имя аккаунта обязательно';

  @override
  String get secretKeyRequired => 'Секретный ключ обязателен';

  @override
  String get invalidSecretKey => 'Недействительный секретный ключ';

  @override
  String get saveAccount => 'Сохранить аккаунт';

  @override
  String get errorAddingAccount => 'Ошибка при добавлении аккаунта';

  @override
  String get alignQRCode => 'Поместите QR-код в рамку';

  @override
  String get invalidQRCode =>
      'Недействительный QR-код. Отсканируйте TOTP QR-код.';

  @override
  String get qrCode => 'QR-код';

  @override
  String get qrCodeTransferInfo =>
      'Вы можете перенести аккаунт, отсканировав этот QR-код на другом устройстве';

  @override
  String get settings => 'Настройки';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get darkMode => 'Тёмный режим';

  @override
  String get useDarkTheme => 'Использовать тёмную тему';

  @override
  String get security => 'Безопасность';

  @override
  String get appLock => 'Блокировка приложения';

  @override
  String get requirePasswordOnLaunch => 'Запрашивать пароль при запуске';

  @override
  String get fingerprintFaceId => 'Отпечаток / Face ID';

  @override
  String get changePassword => 'Изменить пароль';

  @override
  String get setPassword => 'Установить пароль';

  @override
  String get advancedSecurity => 'Расширенная безопасность';

  @override
  String get autoLock => 'Автоблокировка';

  @override
  String get clipboardClear => 'Очистка буфера';

  @override
  String clipboardClearAfterSeconds(int seconds) {
    return 'Через $seconds секунд';
  }

  @override
  String get maxFailedAttemptsLabel => 'Макс. неудачных попыток';

  @override
  String attemptsCount(int count) {
    return '$count попыток';
  }

  @override
  String get wipeOnMaxAttemptsLabel => 'Удаление данных при макс. попытках';

  @override
  String get wipeAllDataOnMax => 'Удалить все данные при макс. попытках';

  @override
  String get backup => 'Резервное копирование';

  @override
  String get exportAccounts => 'Экспорт аккаунтов';

  @override
  String nAccounts(int count) {
    return '$count аккаунтов';
  }

  @override
  String get importAccounts => 'Импорт аккаунтов';

  @override
  String get loadFromJSON => 'Загрузить из JSON файла';

  @override
  String get dangerZone => 'Опасная зона';

  @override
  String get deleteAllData => 'Удалить все данные';

  @override
  String get warning => 'Внимание';

  @override
  String wipeWarning(int count) {
    return 'После $count неудачных попыток входа все данные будут автоматически удалены. Эта функция может привести к необратимой потере данных.';
  }

  @override
  String get enable => 'Включить';

  @override
  String get needPasswordFirst => 'Сначала нужно установить пароль';

  @override
  String get currentPassword => 'Текущий пароль';

  @override
  String get newPassword => 'Новый пароль';

  @override
  String get confirmNewPassword => 'Подтвердите новый пароль';

  @override
  String get currentPasswordWrong => 'Текущий пароль неверен';

  @override
  String get passwordChangedSuccess => 'Пароль успешно изменён';

  @override
  String get deleteAllDataConfirm => 'Будут удалены все аккаунты и настройки.';

  @override
  String get actionIrreversibleExcl => 'Это действие нельзя отменить!';

  @override
  String get allDataDeleted => 'Все данные удалены';

  @override
  String get disabled => 'Отключено';

  @override
  String nSeconds(int count) {
    return '$count секунд';
  }

  @override
  String nMinutes(int count) {
    return '$count минут';
  }

  @override
  String get clipboardClearTime => 'Время очистки буфера';

  @override
  String get secureAuthBackup => 'Резервная копия SecureAuth';

  @override
  String get backupFileDescription =>
      'Файл резервной копии аккаунтов SecureAuth';

  @override
  String get accountsExported => 'Аккаунты экспортированы';

  @override
  String nAccountsImported(int count) {
    return '$count аккаунтов успешно импортировано';
  }

  @override
  String get exportError => 'Ошибка экспорта';

  @override
  String get importError => 'Ошибка импорта';

  @override
  String get aboutEncryption => 'PBKDF2-SHA512 | AES-256 | Полностью офлайн';

  @override
  String get edit => 'Редактировать';

  @override
  String get language => 'Язык';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get exportBackup => 'Экспорт Резервной Копии';

  @override
  String get encryptedExport => 'Зашифрованный (Рекомендуется)';

  @override
  String get encryptedExportDesc => 'Защита AES-256-GCM. Безопасно для обмена.';

  @override
  String get unencryptedExport => 'Без Шифрования';

  @override
  String get unencryptedExportDesc =>
      'Простой JSON. Только для надёжного хранения.';

  @override
  String get setBackupPassword => 'Установить Пароль Резервной Копии';

  @override
  String get backupPassword => 'Пароль Резервной Копии';

  @override
  String get confirmBackupPassword => 'Подтвердить Пароль Резервной Копии';

  @override
  String get backupPasswordWarning =>
      'Сохраните этот пароль в надёжном месте. Без него резервную копию нельзя открыть.';

  @override
  String get encryptingBackup => 'Шифрование резервной копии...';

  @override
  String get decryptingBackup => 'Расшифровка резервной копии...';

  @override
  String get decryptBackup => 'Расшифровать Резервную Копию';

  @override
  String get enterBackupPassword =>
      'Введите пароль, который вы использовали при экспорте этой резервной копии.';

  @override
  String get wrongPasswordOrCorrupted =>
      'Неверный пароль или повреждённый файл';

  @override
  String get loadFromFile =>
      'Загрузить из JSON или зашифрованного .saenc файла';

  @override
  String get ok => 'ОК';

  @override
  String get dataWipedTitle => 'Все данные удалены';

  @override
  String get dataWipedBody =>
      'Превышено максимальное количество неудачных попыток.\n\nВсе аккаунты и настройки безвозвратно удалены в целях безопасности. Нажмите ОК, чтобы начать заново.';
}
