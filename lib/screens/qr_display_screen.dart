import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../services/qr_service.dart';
import '../utils/constants.dart';

class QRDisplayScreen extends StatelessWidget {
  final AccountModel account;
  final QRService qrService;

  const QRDisplayScreen({
    super.key,
    required this.account,
    required this.qrService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesap QR Kodu'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.largePadding),
                  child: Column(
                    children: [
                      Text(
                        account.issuer,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        account.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: AppConstants.largePadding),
                      Container(
                        padding: const EdgeInsets.all(AppConstants.defaultPadding),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        ),
                        child: qrService.buildQRWidget(
                          account.otpAuthUri,
                          size: 250,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.largePadding),
              Text(
                'Bu QR kodu başka bir cihazda tarayarak hesabı aktarabilirsiniz',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
