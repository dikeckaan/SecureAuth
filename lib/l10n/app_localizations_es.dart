// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'SecureAuth';

  @override
  String get authSubtitle =>
      'Verifica tu identidad para\nacceder a tus cuentas';

  @override
  String get password => 'Contraseña';

  @override
  String get pleaseEnterPassword => 'Por favor ingresa tu contraseña';

  @override
  String lockedWithTime(String time) {
    return 'Bloqueado: $time';
  }

  @override
  String failedAttemptsCount(int count) {
    return '$count intentos fallidos';
  }

  @override
  String get tooManyAttempts =>
      'Demasiados intentos fallidos. Por favor espera.';

  @override
  String wrongPasswordWithRemaining(int remaining) {
    return 'Contraseña incorrecta ($remaining intentos restantes)';
  }

  @override
  String get maxAttemptsExceeded =>
      'Intentos máximos superados. Todos los datos eliminados.';

  @override
  String get login => 'Iniciar Sesión';

  @override
  String get biometricLogin => 'Iniciar con Biometría';

  @override
  String codeCopied(int seconds) {
    return 'Código copiado (se borrará en ${seconds}s)';
  }

  @override
  String minuteShortFormat(int minutes, int seconds) {
    return '$minutes min $seconds seg';
  }

  @override
  String secondShortFormat(int seconds) {
    return '$seconds seg';
  }

  @override
  String get welcome => 'Bienvenido';

  @override
  String get setupSubtitle =>
      'Establece una contraseña para\nmantener tus cuentas seguras';

  @override
  String get confirmPassword => 'Confirmar Contraseña';

  @override
  String get strengthWeak => 'Débil';

  @override
  String get strengthMedium => 'Media';

  @override
  String get strengthGood => 'Buena';

  @override
  String get strengthStrong => 'Fuerte';

  @override
  String get strengthVeryStrong => 'Muy Fuerte';

  @override
  String get biometricAuth => 'Autenticación Biométrica';

  @override
  String get fingerprintOrFace => 'Huella dactilar o reconocimiento facial';

  @override
  String get completeSetup => 'Completar Configuración';

  @override
  String get continueWithoutPassword => 'Continuar Sin Contraseña';

  @override
  String get pleaseSetPassword => 'Por favor establece una contraseña';

  @override
  String passwordMinLength(int length) {
    return 'La contraseña debe tener al menos $length caracteres';
  }

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get anErrorOccurred => 'Ocurrió un error';

  @override
  String get strongEncryption => 'Cifrado fuerte con PBKDF2-SHA512';

  @override
  String get editAccount => 'Editar Cuenta';

  @override
  String get serviceName => 'Nombre del Servicio';

  @override
  String get accountName => 'Nombre de Cuenta';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get deleteAccount => 'Eliminar Cuenta';

  @override
  String deleteAccountConfirm(String issuer) {
    return '¿Estás seguro de que deseas eliminar la cuenta $issuer?';
  }

  @override
  String get actionIrreversible => 'Esta acción no se puede deshacer';

  @override
  String get delete => 'Eliminar';

  @override
  String get accountDeleted => 'Cuenta eliminada';

  @override
  String get searchAccounts => 'Buscar cuentas...';

  @override
  String get noAccountsYet => 'Aún no has agregado cuentas';

  @override
  String get addAccountsToImprove =>
      'Agrega tus cuentas 2FA para\nmejorar tu seguridad';

  @override
  String get accountNotFound => 'Cuenta no encontrada';

  @override
  String get addAccount => 'Agregar Cuenta';

  @override
  String get scanQRCode => 'Escanear Código QR';

  @override
  String get useCamera => 'Usa tu cámara para escanear el código QR';

  @override
  String get or => 'o';

  @override
  String get manualEntry => 'Entrada Manual';

  @override
  String get serviceNameHint => 'Google, GitHub, Discord...';

  @override
  String get accountNameHint => 'usuario@ejemplo.com';

  @override
  String get secretKey => 'Clave Secreta';

  @override
  String get secretKeyHint => 'JBSWY3DPEHPK3PXP';

  @override
  String get serviceNameRequired => 'El nombre del servicio es obligatorio';

  @override
  String get accountNameRequired => 'El nombre de cuenta es obligatorio';

  @override
  String get secretKeyRequired => 'La clave secreta es obligatoria';

  @override
  String get invalidSecretKey => 'Clave secreta inválida';

  @override
  String get saveAccount => 'Guardar Cuenta';

  @override
  String get errorAddingAccount => 'Error al agregar la cuenta';

  @override
  String get alignQRCode => 'Alinea el código QR dentro del marco';

  @override
  String get invalidQRCode =>
      'Código QR inválido. Por favor escanea un código QR TOTP.';

  @override
  String get qrCode => 'Código QR';

  @override
  String get qrCodeTransferInfo =>
      'Puedes transferir esta cuenta escaneando este código QR en otro dispositivo';

  @override
  String get settings => 'Configuración';

  @override
  String get appearance => 'Apariencia';

  @override
  String get darkMode => 'Modo Oscuro';

  @override
  String get useDarkTheme => 'Usar tema oscuro';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get lightTheme => 'Claro';

  @override
  String get darkTheme => 'Oscuro';

  @override
  String get themeMode => 'Tema';

  @override
  String get security => 'Seguridad';

  @override
  String get appLock => 'Bloqueo de App';

  @override
  String get requirePasswordOnLaunch => 'Pedir contraseña al abrir';

  @override
  String get fingerprintFaceId => 'Huella dactilar / Face ID';

  @override
  String get changePassword => 'Cambiar Contraseña';

  @override
  String get setPassword => 'Establecer Contraseña';

  @override
  String get advancedSecurity => 'Seguridad Avanzada';

  @override
  String get autoLock => 'Bloqueo Automático';

  @override
  String get clipboardClear => 'Limpieza del Portapapeles';

  @override
  String clipboardClearAfterSeconds(int seconds) {
    return '$seconds segundos después';
  }

  @override
  String get maxFailedAttemptsLabel => 'Máx. Intentos Fallidos';

  @override
  String attemptsCount(int count) {
    return '$count intentos';
  }

  @override
  String get wipeOnMaxAttemptsLabel => 'Borrar Datos en Máx. Intentos';

  @override
  String get wipeAllDataOnMax => 'Eliminar todos los datos en máx. intentos';

  @override
  String get backup => 'Respaldo';

  @override
  String get exportAccounts => 'Exportar Cuentas';

  @override
  String nAccounts(int count) {
    return '$count cuentas';
  }

  @override
  String get importAccounts => 'Importar Cuentas';

  @override
  String get loadFromJSON => 'Cargar desde archivo JSON';

  @override
  String get dangerZone => 'Zona de Peligro';

  @override
  String get deleteAllData => 'Eliminar Todos los Datos';

  @override
  String get warning => 'Advertencia';

  @override
  String wipeWarning(int count) {
    return 'Después de $count intentos fallidos de inicio de sesión, todos los datos se eliminarán automáticamente. Esta función puede causar pérdida irreversible de datos.';
  }

  @override
  String get enable => 'Activar';

  @override
  String get needPasswordFirst => 'Primero necesitas establecer una contraseña';

  @override
  String get currentPassword => 'Contraseña Actual';

  @override
  String get newPassword => 'Nueva Contraseña';

  @override
  String get confirmNewPassword => 'Confirmar Nueva Contraseña';

  @override
  String get currentPasswordWrong => 'La contraseña actual es incorrecta';

  @override
  String get passwordChangedSuccess => 'Contraseña cambiada exitosamente';

  @override
  String get deleteAllDataConfirm =>
      'Esto eliminará todas las cuentas y configuraciones.';

  @override
  String get actionIrreversibleExcl => '¡Esta acción no se puede deshacer!';

  @override
  String get allDataDeleted => 'Todos los datos eliminados';

  @override
  String get disabled => 'Desactivado';

  @override
  String nSeconds(int count) {
    return '$count segundos';
  }

  @override
  String nMinutes(int count) {
    return '$count minutos';
  }

  @override
  String get clipboardClearTime => 'Tiempo de Limpieza del Portapapeles';

  @override
  String get secureAuthBackup => 'Respaldo SecureAuth';

  @override
  String get backupFileDescription =>
      'Archivo de respaldo de cuentas SecureAuth';

  @override
  String get accountsExported => 'Cuentas exportadas';

  @override
  String nAccountsImported(int count) {
    return '$count cuentas importadas exitosamente';
  }

  @override
  String get exportError => 'Error de exportación';

  @override
  String get importError => 'Error de importación';

  @override
  String get aboutEncryption =>
      'PBKDF2-SHA512 | AES-256 | Completamente Offline';

  @override
  String get edit => 'Editar';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Seleccionar Idioma';

  @override
  String get exportBackup => 'Exportar Copia de Seguridad';

  @override
  String get encryptedExport => 'Cifrado (Recomendado)';

  @override
  String get encryptedExportDesc =>
      'Protegido con AES-256-GCM. Seguro para compartir en cualquier lugar.';

  @override
  String get unencryptedExport => 'Sin Cifrar';

  @override
  String get unencryptedExportDesc =>
      'JSON simple. Solo para almacenamiento de confianza.';

  @override
  String get setBackupPassword => 'Establecer Contraseña de Copia';

  @override
  String get backupPassword => 'Contraseña de Copia';

  @override
  String get confirmBackupPassword => 'Confirmar Contraseña de Copia';

  @override
  String get backupPasswordWarning =>
      'Guarda esta contraseña en un lugar seguro. Sin ella, no podrás abrir tu copia de seguridad.';

  @override
  String get encryptingBackup => 'Cifrando copia de seguridad...';

  @override
  String get decryptingBackup => 'Descifrando copia de seguridad...';

  @override
  String get decryptBackup => 'Descifrar Copia';

  @override
  String get enterBackupPassword =>
      'Ingresa la contraseña que usaste al exportar esta copia de seguridad.';

  @override
  String get wrongPasswordOrCorrupted =>
      'Contraseña incorrecta o archivo corrupto';

  @override
  String get loadFromFile => 'Cargar desde JSON o archivo .saenc cifrado';

  @override
  String get ok => 'Aceptar';

  @override
  String get dataWipedTitle => 'Todos los Datos Eliminados';

  @override
  String get dataWipedBody =>
      'Se excedió el número máximo de intentos fallidos.\n\nTodas sus cuentas y configuraciones han sido eliminadas permanentemente. Toca Aceptar para comenzar de nuevo.';
}
