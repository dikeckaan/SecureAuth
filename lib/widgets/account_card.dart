import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/account_model.dart';
import '../services/totp_service.dart';
import '../utils/constants.dart';

class AccountCard extends StatefulWidget {
  final AccountModel account;
  final TOTPService totpService;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShowQR;

  const AccountCard({
    super.key,
    required this.account,
    required this.totpService,
    required this.onEdit,
    required this.onDelete,
    required this.onShowQR,
  });

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  late String _code;
  late int _remaining;
  late double _progress;

  @override
  void initState() {
    super.initState();
    _updateCode();
  }

  void _updateCode() {
    setState(() {
      _code = widget.totpService.generateTOTP(widget.account);
      _remaining = widget.totpService.getRemainingSeconds(widget.account.period);
      _progress = widget.totpService.getProgress(widget.account.period);
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _updateCode();
      }
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kod kopyalandı'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: _copyToClipboard,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.account.issuer,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.account.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'qr':
                          widget.onShowQR();
                          break;
                        case 'edit':
                          widget.onEdit();
                          break;
                        case 'delete':
                          widget.onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'qr',
                        child: Row(
                          children: [
                            Icon(Icons.qr_code),
                            SizedBox(width: 8),
                            Text('QR Kod Göster'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Düzenle'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Sil', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _code,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                  Column(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: _progress,
                              strokeWidth: 3,
                              color: _remaining <= 5 ? AppColors.error : AppColors.primary,
                              backgroundColor: theme.colorScheme.surface,
                            ),
                            Text(
                              '$_remaining',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
