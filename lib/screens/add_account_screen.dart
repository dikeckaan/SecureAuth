import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/account_model.dart';
import '../services/storage_service.dart';
import '../services/totp_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
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

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _nameController = TextEditingController();
  final _issuerController = TextEditingController();
  final _secretController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _scanQR() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(totpService: widget.totpService),
      ),
    );

    if (result != null && result is AccountModel) {
      _nameController.text = result.name;
      _issuerController.text = result.issuer;
      _secretController.text = result.secret;
      setState(() {});
    }
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    final secret = _secretController.text.trim().toUpperCase();
    if (!widget.totpService.validateSecret(secret)) {
      _showError('Gecersiz secret key');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final account = AccountModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        issuer: _issuerController.text.trim(),
        secret: secret,
        createdAt: DateTime.now(),
      );

      await widget.storageService.addAccount(account);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showError('Hesap eklenirken hata olustu');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesap Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLG),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // QR Scan button
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _scanQR,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusLG),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingLG),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(
                                  AppConstants.radiusMD),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingMD),
                          Text(
                            'QR Kod Tara',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kameranizi kullanarak QR kodu okutun',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withAlpha(128),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingLG),
              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingMD),
                    child: Text(
                      'veya',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withAlpha(128),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: AppConstants.paddingLG),
              // Manual entry header
              Text(
                'Manuel Giris',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.paddingMD),
              // Issuer
              TextFormField(
                controller: _issuerController,
                decoration: const InputDecoration(
                  labelText: 'Servis Adi',
                  hintText: 'Google, GitHub, Discord...',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Servis adi gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingMD),
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Hesap Adi',
                  hintText: 'kullanici@ornek.com',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Hesap adi gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingMD),
              // Secret
              TextFormField(
                controller: _secretController,
                decoration: const InputDecoration(
                  labelText: 'Secret Key',
                  hintText: 'JBSWY3DPEHPK3PXP',
                  prefixIcon: Icon(Icons.key_outlined),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Secret key gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingLG),
              // Save button
              GradientButton(
                text: 'Hesabi Kaydet',
                onPressed: _saveAccount,
                isLoading: _isLoading,
                icon: Icons.save_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
