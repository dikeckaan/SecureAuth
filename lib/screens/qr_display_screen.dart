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
    final serviceColor = AppColors.getServiceColor(account.issuer);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Kod'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLG),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Account info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLG),
                  child: Column(
                    children: [
                      // Service avatar
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [serviceColor, serviceColor.withAlpha(179)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMD),
                        ),
                        child: Center(
                          child: Text(
                            account.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingMD),
                      Text(
                        account.issuer,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingLG),
                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(AppConstants.paddingMD),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMD),
                          border: Border.all(
                            color: theme.colorScheme.outline.withAlpha(51),
                          ),
                        ),
                        child: qrService.buildQRWidget(
                          account.otpAuthUri,
                          size: 240,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingLG),
              // Info
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMD),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(51),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: AppConstants.paddingSM),
                    Expanded(
                      child: Text(
                        'Bu QR kodu baska bir cihazda tarayarak hesabi aktarabilirsiniz',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
