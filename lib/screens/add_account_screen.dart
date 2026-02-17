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
  bool _isLoading = false;

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
    }
  }

  Future<void> _saveAccount() async {
    if (_issuerController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _secretController.text.isEmpty) {
      _showError('Lütfen tüm alanları doldurun');
      return;
    }

    if (!widget.totpService.validateSecret(_secretController.text)) {
      _showError('Geçersiz secret key');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final account = AccountModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        issuer: _issuerController.text.trim(),
        secret: _secretController.text.trim().toUpperCase(),
        createdAt: DateTime.now(),
      );

      await widget.storageService.addAccount(account);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Hesap eklenirken hata: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesap Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomButton(
              text: 'QR Kod Tara',
              onPressed: _scanQR,
              icon: Icons.qr_code_scanner,
              isOutlined: true,
            ),
            const SizedBox(height: AppConstants.largePadding),
            const Divider(),
            const SizedBox(height: AppConstants.largePadding),
            Text(
              'veya manuel olarak girin',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            TextField(
              controller: _issuerController,
              decoration: const InputDecoration(
                labelText: 'Yayıncı (ör: Google, GitHub)',
                prefixIcon: Icon(Icons.business),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Hesap Adı (ör: user@example.com)',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            TextField(
              controller: _secretController,
              decoration: const InputDecoration(
                labelText: 'Secret Key',
                prefixIcon: Icon(Icons.key),
                hintText: 'JBSWY3DPEHPK3PXP',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: AppConstants.largePadding),
            CustomButton(
              text: 'Hesabı Kaydet',
              onPressed: _saveAccount,
              isLoading: _isLoading,
              icon: Icons.save,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    _secretController.dispose();
    super.dispose();
  }
}
