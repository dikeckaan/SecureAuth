import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:secure_auth/l10n/app_localizations.dart';

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
        createdAt: DateTime.now(),
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
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addAccount),
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
                            l10n.scanQRCode,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.useCamera,
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
                      l10n.or,
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
                l10n.manualEntry,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.serviceNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingMD),
              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.accountName,
                  hintText: l10n.accountNameHint,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.accountNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingMD),
              // Secret
              TextFormField(
                controller: _secretController,
                decoration: InputDecoration(
                  labelText: l10n.secretKey,
                  hintText: l10n.secretKeyHint,
                  prefixIcon: const Icon(Icons.key_outlined),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.secretKeyRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingLG),
              // Save button
              GradientButton(
                text: l10n.saveAccount,
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
