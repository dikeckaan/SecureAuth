// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'SecureAuth';

  @override
  String get authSubtitle =>
      'Verifique sua identidade para\nacessar suas contas';

  @override
  String get password => 'Senha';

  @override
  String get pleaseEnterPassword => 'Por favor, insira sua senha';

  @override
  String lockedWithTime(String time) {
    return 'Bloqueado: $time';
  }

  @override
  String failedAttemptsCount(int count) {
    return '$count tentativas falhadas';
  }

  @override
  String get tooManyAttempts =>
      'Muitas tentativas falhadas. Por favor, aguarde.';

  @override
  String wrongPasswordWithRemaining(int remaining) {
    return 'Senha incorreta ($remaining tentativas restantes)';
  }

  @override
  String get maxAttemptsExceeded =>
      'Tentativas máximas excedidas. Todos os dados apagados.';

  @override
  String get login => 'Entrar';

  @override
  String get biometricLogin => 'Entrar com Biometria';

  @override
  String codeCopied(int seconds) {
    return 'Código copiado (limpa em ${seconds}s)';
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
  String get welcome => 'Bem-vindo';

  @override
  String get setupSubtitle =>
      'Defina uma senha para\nmanter suas contas seguras';

  @override
  String get confirmPassword => 'Confirmar Senha';

  @override
  String get strengthWeak => 'Fraca';

  @override
  String get strengthMedium => 'Média';

  @override
  String get strengthGood => 'Boa';

  @override
  String get strengthStrong => 'Forte';

  @override
  String get strengthVeryStrong => 'Muito Forte';

  @override
  String get biometricAuth => 'Autenticação Biométrica';

  @override
  String get fingerprintOrFace => 'Impressão digital ou reconhecimento facial';

  @override
  String get completeSetup => 'Concluir Configuração';

  @override
  String get continueWithoutPassword => 'Continuar Sem Senha';

  @override
  String get pleaseSetPassword => 'Por favor, defina uma senha';

  @override
  String passwordMinLength(int length) {
    return 'A senha deve ter pelo menos $length caracteres';
  }

  @override
  String get passwordsDoNotMatch => 'As senhas não coincidem';

  @override
  String get anErrorOccurred => 'Ocorreu um erro';

  @override
  String get strongEncryption => 'Criptografia forte com PBKDF2-SHA512';

  @override
  String get editAccount => 'Editar Conta';

  @override
  String get serviceName => 'Nome do Serviço';

  @override
  String get accountName => 'Nome da Conta';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get deleteAccount => 'Excluir Conta';

  @override
  String deleteAccountConfirm(String issuer) {
    return 'Tem certeza de que deseja excluir a conta $issuer?';
  }

  @override
  String get actionIrreversible => 'Esta ação não pode ser desfeita';

  @override
  String get delete => 'Excluir';

  @override
  String get accountDeleted => 'Conta excluída';

  @override
  String get searchAccounts => 'Pesquisar contas...';

  @override
  String get noAccountsYet => 'Nenhuma conta adicionada ainda';

  @override
  String get addAccountsToImprove =>
      'Adicione suas contas 2FA para\nmelhorar sua segurança';

  @override
  String get accountNotFound => 'Conta não encontrada';

  @override
  String get addAccount => 'Adicionar Conta';

  @override
  String get scanQRCode => 'Escanear Código QR';

  @override
  String get useCamera => 'Use sua câmera para escanear o código QR';

  @override
  String get or => 'ou';

  @override
  String get manualEntry => 'Entrada Manual';

  @override
  String get serviceNameHint => 'Google, GitHub, Discord...';

  @override
  String get accountNameHint => 'usuario@exemplo.com';

  @override
  String get secretKey => 'Chave Secreta';

  @override
  String get secretKeyHint => 'JBSWY3DPEHPK3PXP';

  @override
  String get serviceNameRequired => 'Nome do serviço é obrigatório';

  @override
  String get accountNameRequired => 'Nome da conta é obrigatório';

  @override
  String get secretKeyRequired => 'Chave secreta é obrigatória';

  @override
  String get invalidSecretKey => 'Chave secreta inválida';

  @override
  String get saveAccount => 'Salvar Conta';

  @override
  String get errorAddingAccount => 'Erro ao adicionar conta';

  @override
  String get alignQRCode => 'Alinhe o código QR dentro do quadro';

  @override
  String get invalidQRCode => 'Código QR inválido. Escaneie um código QR TOTP.';

  @override
  String get qrCode => 'Código QR';

  @override
  String get qrCodeTransferInfo =>
      'Você pode transferir esta conta escaneando este código QR em outro dispositivo';

  @override
  String get settings => 'Configurações';

  @override
  String get appearance => 'Aparência';

  @override
  String get darkMode => 'Modo Escuro';

  @override
  String get useDarkTheme => 'Usar tema escuro';

  @override
  String get security => 'Segurança';

  @override
  String get appLock => 'Bloqueio do App';

  @override
  String get requirePasswordOnLaunch => 'Exigir senha ao abrir';

  @override
  String get fingerprintFaceId => 'Impressão digital / Face ID';

  @override
  String get changePassword => 'Alterar Senha';

  @override
  String get setPassword => 'Definir Senha';

  @override
  String get advancedSecurity => 'Segurança Avançada';

  @override
  String get autoLock => 'Bloqueio Automático';

  @override
  String get clipboardClear => 'Limpar Área de Transferência';

  @override
  String clipboardClearAfterSeconds(int seconds) {
    return 'Após $seconds segundos';
  }

  @override
  String get maxFailedAttemptsLabel => 'Máx. Tentativas Falhadas';

  @override
  String attemptsCount(int count) {
    return '$count tentativas';
  }

  @override
  String get wipeOnMaxAttemptsLabel => 'Apagar Dados no Máx.';

  @override
  String get wipeAllDataOnMax => 'Excluir todos os dados no máx.';

  @override
  String get backup => 'Backup';

  @override
  String get exportAccounts => 'Exportar Contas';

  @override
  String nAccounts(int count) {
    return '$count contas';
  }

  @override
  String get importAccounts => 'Importar Contas';

  @override
  String get loadFromJSON => 'Carregar de arquivo JSON';

  @override
  String get dangerZone => 'Zona de Perigo';

  @override
  String get deleteAllData => 'Excluir Todos os Dados';

  @override
  String get warning => 'Atenção';

  @override
  String wipeWarning(int count) {
    return 'Após $count tentativas de login falhadas, todos os dados serão automaticamente excluídos. Este recurso pode causar perda irreversível de dados.';
  }

  @override
  String get enable => 'Ativar';

  @override
  String get needPasswordFirst => 'Você precisa definir uma senha primeiro';

  @override
  String get currentPassword => 'Senha Atual';

  @override
  String get newPassword => 'Nova Senha';

  @override
  String get confirmNewPassword => 'Confirmar Nova Senha';

  @override
  String get currentPasswordWrong => 'A senha atual está incorreta';

  @override
  String get passwordChangedSuccess => 'Senha alterada com sucesso';

  @override
  String get deleteAllDataConfirm =>
      'Isso excluirá todas as contas e configurações.';

  @override
  String get actionIrreversibleExcl => 'Esta ação não pode ser desfeita!';

  @override
  String get allDataDeleted => 'Todos os dados excluídos';

  @override
  String get disabled => 'Desativado';

  @override
  String nSeconds(int count) {
    return '$count segundos';
  }

  @override
  String nMinutes(int count) {
    return '$count minutos';
  }

  @override
  String get clipboardClearTime => 'Tempo de Limpeza da Área de Transferência';

  @override
  String get secureAuthBackup => 'Backup SecureAuth';

  @override
  String get backupFileDescription => 'Arquivo de backup de contas SecureAuth';

  @override
  String get accountsExported => 'Contas exportadas';

  @override
  String nAccountsImported(int count) {
    return '$count contas importadas com sucesso';
  }

  @override
  String get exportError => 'Erro na exportação';

  @override
  String get importError => 'Erro na importação';

  @override
  String get aboutEncryption => 'PBKDF2-SHA512 | AES-256 | Totalmente Offline';

  @override
  String get edit => 'Editar';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Selecionar Idioma';
}
