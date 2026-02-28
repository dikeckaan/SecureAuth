import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import 'package:secure_auth/l10n/app_localizations.dart';

import '../models/account_model.dart';
import '../services/storage_service.dart';
import '../services/totp_service.dart';
import '../utils/constants.dart';
import 'qr_scanner_screen.dart';

class AddAccountScreen extends StatefulWidget {
  final StorageService storageService;
  final TOTPService totpService;

  const AddAccountScreen({
    super.key,
    required this.storageService,
    required this.totpService,
  });

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _issuerController = TextEditingController();
  final _secretController = TextEditingController();
  final _counterController = TextEditingController(text: '0');
  final _formKey = GlobalKey<FormState>();

  String _tokenType = 'totp'; // 'totp' | 'hotp' | 'steam'
  String _algorithm = 'SHA1';
  int _digits = 6;
  int _period = 30;
  bool _isLoading = false;
  bool _showAdvanced = false;
  bool _secretVisible = false;

  late TabController _tabController;

  static const _tokenTypes = [
    _TokenTypeOption('totp', 'TOTP', Icons.access_time_outlined),
    _TokenTypeOption('hotp', 'HOTP', Icons.tag_outlined),
    _TokenTypeOption('steam', 'Steam', Icons.videogame_asset_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tokenTypes.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      setState(() {
        _tokenType = _tokenTypes[_tabController.index].type;
        if (_tokenType == 'steam') {
          _digits = 5;
          _algorithm = 'SHA1';
        } else {
          _digits = 6;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _issuerController.dispose();
    _secretController.dispose();
    _counterController.dispose();
    super.dispose();
  }

  Future<void> _scanQR() async {
    final result = await Navigator.push<AccountModel>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QRScannerScreen(totpService: widget.totpService),
      ),
    );

    if (result != null && mounted) {
      _fillFromAccount(result);
    }
  }

  /// Pick an image file and scan it for a QR code without opening the camera.
  Future<void> _pickImageAndScan() async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.image);
    if (picked == null || picked.files.isEmpty) return;

    final path = picked.files.first.path;
    if (path == null) return;

    final controller = MobileScannerController();
    try {
      final capture = await controller.analyzeImage(path);
      if (!mounted) return;

      if (capture != null && capture.barcodes.isNotEmpty) {
        final code = capture.barcodes.first.rawValue;
        if (code != null) {
          final account = widget.totpService.parseOtpAuthUri(code);
          if (account != null) {
            _fillFromAccount(account);
            return;
          }
        }
      }
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.invalidQRCode);
      }
    } finally {
      await controller.dispose();
    }
  }

  void _fillFromAccount(AccountModel result) {
    _issuerController.text = result.issuer;
    _nameController.text = result.name;
    _secretController.text = result.secret;
    _algorithm = result.algorithm;
    _digits = result.digits;
    _period = result.period;

    final idx = _tokenTypes.indexWhere((t) => t.type == result.type);
    if (idx >= 0) {
      _tabController.animateTo(idx);
      _tokenType = result.type;
    }

    if (result.isHotp) {
      _counterController.text = result.counter.toString();
    }
    setState(() {});
  }

  Future<void> _saveAccount() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final secret = _secretController.text.trim().toUpperCase();
    if (!widget.totpService.validateSecret(secret)) {
      _showError(l10n.invalidSecretKey);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final account = AccountModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        issuer: _issuerController.text.trim(),
        secret: secret,
        digits: _tokenType == 'steam' ? 5 : _digits,
        period: _tokenType == 'hotp' ? 30 : _period,
        algorithm: _tokenType == 'steam' ? 'SHA1' : _algorithm,
        createdAt: DateTime.now(),
        type: _tokenType,
        counter: _tokenType == 'hotp'
            ? int.tryParse(_counterController.text) ?? 0
            : 0,
      );

      await widget.storageService.addAccount(account);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showError(l10n.errorAddingAccount);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addAccount),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Token type selector ────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  border: Border.all(
                      color: theme.colorScheme.outline.withAlpha(60)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMD - 1),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor:
                      theme.colorScheme.onSurface.withAlpha(153),
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: _tokenTypes
                      .map((t) => Tab(
                            height: 44,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(t.icon, size: 16),
                                const SizedBox(width: 6),
                                Text(t.label),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),

              if (_tokenType == 'steam') ...[
                const SizedBox(height: AppConstants.paddingSM),
                _buildInfoBanner(
                  theme,
                  Icons.info_outline,
                  'Steam Guard: 5 karakterli kod, SHA1, 30 saniyelik döngü.',
                  AppColors.accent,
                ),
              ],

              if (_tokenType == 'hotp') ...[
                const SizedBox(height: AppConstants.paddingSM),
                _buildInfoBanner(
                  theme,
                  Icons.info_outline,
                  'HOTP: Her kullanımda sayaç artar, süre yok.',
                  theme.colorScheme.secondary,
                ),
              ],

              const SizedBox(height: AppConstants.paddingLG),

              // ── QR scan button ─────────────────────────────────────────
              _buildQRScanButton(theme, l10n),

              const SizedBox(height: AppConstants.paddingLG),
              _buildOrDivider(theme, l10n),
              const SizedBox(height: AppConstants.paddingLG),

              // ── Manual entry ───────────────────────────────────────────
              Text(
                l10n.manualEntry,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppConstants.paddingMD),

              // Issuer
              TextFormField(
                controller: _issuerController,
                decoration: InputDecoration(
                  labelText: l10n.serviceName,
                  hintText: l10n.serviceNameHint,
                  prefixIcon: const Icon(Icons.business_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.serviceNameRequired
                    : null,
              ),
              const SizedBox(height: AppConstants.paddingMD),

              // Account name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.accountName,
                  hintText: l10n.accountNameHint,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.accountNameRequired
                    : null,
              ),
              const SizedBox(height: AppConstants.paddingMD),

              // Secret key
              TextFormField(
                controller: _secretController,
                obscureText: !_secretVisible,
                decoration: InputDecoration(
                  labelText: l10n.secretKey,
                  hintText: l10n.secretKeyHint,
                  prefixIcon: const Icon(Icons.key_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _secretVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _secretVisible = !_secretVisible),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-z2-7=\s]')),
                ],
                textCapitalization: TextCapitalization.characters,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.secretKeyRequired
                    : null,
              ),

              // HOTP counter field
              if (_tokenType == 'hotp') ...[
                const SizedBox(height: AppConstants.paddingMD),
                TextFormField(
                  controller: _counterController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Başlangıç sayacı',
                    hintText: '0',
                    prefixIcon: Icon(Icons.tag_outlined),
                  ),
                ),
              ],

              const SizedBox(height: AppConstants.paddingMD),

              // ── Advanced settings ──────────────────────────────────────
              if (_tokenType != 'steam') _buildAdvancedToggle(theme, l10n),
              if (_showAdvanced && _tokenType != 'steam') ...[
                const SizedBox(height: AppConstants.paddingMD),
                _buildAdvancedSettings(theme, l10n),
              ],

              const SizedBox(height: AppConstants.paddingLG),

              // ── Save button ────────────────────────────────────────────
              _buildSaveButton(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRScanButton(ThemeData theme, AppLocalizations l10n) {
    return Column(
      children: [
        // Camera scan
        _buildScanOption(
          theme: theme,
          icon: Icons.qr_code_scanner,
          title: l10n.scanQRCode,
          subtitle: l10n.useCamera,
          onTap: _scanQR,
        ),
        const SizedBox(height: AppConstants.paddingSM),
        // Image scan
        _buildScanOption(
          theme: theme,
          icon: Icons.image_search_outlined,
          title: l10n.scanFromImage,
          subtitle: l10n.pickImageToScan,
          onTap: _pickImageAndScan,
          secondary: true,
        ),
      ],
    );
  }

  Widget _buildScanOption({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool secondary = false,
  }) {
    final color =
        secondary ? theme.colorScheme.secondary : theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusLG),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(100), width: 1.5),
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          color: color.withAlpha(10),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: secondary
                      ? [theme.colorScheme.secondary, theme.colorScheme.primary]
                      : [theme.colorScheme.primary, theme.colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: AppConstants.paddingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(128),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: theme.colorScheme.onSurface.withAlpha(128)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrDivider(ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
          child: Text(
            l10n.or,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(128),
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildAdvancedToggle(ThemeData theme, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => setState(() => _showAdvanced = !_showAdvanced),
      child: Row(
        children: [
          Icon(
            _showAdvanced
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            'Gelişmiş ayarlar',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Algoritma',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
          const SizedBox(height: AppConstants.paddingSM),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'SHA1', label: Text('SHA-1')),
              ButtonSegment(value: 'SHA256', label: Text('SHA-256')),
              ButtonSegment(value: 'SHA512', label: Text('SHA-512')),
            ],
            selected: {_algorithm},
            onSelectionChanged: (s) => setState(() => _algorithm = s.first),
            style: ButtonStyle(
              textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMD),
          Text(
            'Kod uzunluğu',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
          const SizedBox(height: AppConstants.paddingSM),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 6, label: Text('6')),
              ButtonSegment(value: 7, label: Text('7')),
              ButtonSegment(value: 8, label: Text('8')),
            ],
            selected: {_digits},
            onSelectionChanged: (s) => setState(() => _digits = s.first),
          ),
          if (_tokenType == 'totp') ...[
            const SizedBox(height: AppConstants.paddingMD),
            Text(
              'Yenileme süresi',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
            const SizedBox(height: AppConstants.paddingSM),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 30, label: Text('30s')),
                ButtonSegment(value: 60, label: Text('60s')),
                ButtonSegment(value: 90, label: Text('90s')),
              ],
              selected: {_period},
              onSelectionChanged: (s) => setState(() => _period = s.first),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBanner(
      ThemeData theme, IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: AppConstants.paddingSM,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: _isLoading
            ? null
            : LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: _isLoading ? Colors.grey.shade400 : null,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        boxShadow: _isLoading
            ? null
            : [
                BoxShadow(
                  color: theme.colorScheme.primary.withAlpha(70),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _saveAccount,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppConstants.paddingMD,
              horizontal: AppConstants.paddingLG,
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.save_outlined,
                            size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          l10n.saveAccount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TokenTypeOption {
  final String type;
  final String label;
  final IconData icon;
  const _TokenTypeOption(this.type, this.label, this.icon);
}
