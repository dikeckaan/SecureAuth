import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:secure_auth/l10n/app_localizations.dart';

import '../models/account_model.dart';
import '../services/totp_service.dart';
import '../utils/constants.dart';

class AccountCard extends StatefulWidget {
  final AccountModel account;
  final TOTPService totpService;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShowQR;
  final Future<void> Function(String code) onCopy;

  const AccountCard({
    super.key,
    required this.account,
    required this.totpService,
    required this.onEdit,
    required this.onDelete,
    required this.onShowQR,
    required this.onCopy,
  });

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard>
    with SingleTickerProviderStateMixin {
  late String _code;
  late int _remaining;
  late double _progress;
  Timer? _timer;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _updateCode();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCode());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateCode() {
    if (!mounted) return;
    final newCode = widget.totpService.generateTOTP(widget.account);
    final newRemaining =
        widget.totpService.getRemainingSeconds(widget.account.period);
    final newProgress = widget.totpService.getProgress(widget.account.period);

    setState(() {
      _code = newCode;
      _remaining = newRemaining;
      _progress = newProgress;
    });
  }

  Future<void> _copyToClipboard() async {
    HapticFeedback.lightImpact();
    await widget.onCopy(_code);

    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Color get _timerColor {
    if (_remaining <= 5) return AppColors.error;
    if (_remaining <= 10) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final serviceColor = AppColors.getServiceColor(widget.account.issuer);
    final formattedCode = widget.totpService.formatCode(_code);

    return Card(
      child: InkWell(
        onTap: _copyToClipboard,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMD),
          child: Column(
            children: [
              // Header row: avatar + info + menu
              Row(
                children: [
                  // Service avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          serviceColor,
                          serviceColor.withAlpha(179),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMD),
                    ),
                    child: Center(
                      child: Text(
                        widget.account.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMD),
                  // Name and issuer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.account.issuer,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.account.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(153),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurface.withAlpha(128),
                      size: 20,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'qr':
                          widget.onShowQR();
                        case 'edit':
                          widget.onEdit();
                        case 'delete':
                          widget.onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'qr',
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code_2, size: 20),
                            const SizedBox(width: 12),
                            Text(l10n.qrCode),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 20),
                            const SizedBox(width: 12),
                            Text(l10n.edit),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline,
                                size: 20, color: AppColors.error),
                            const SizedBox(width: 12),
                            Text(l10n.delete,
                                style: const TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingMD),
              // OTP code row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Code
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          formattedCode,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: _remaining <= 5
                                ? AppColors.error
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingSM),
                        AnimatedSwitcher(
                          duration: AppConstants.animFast,
                          child: _copied
                              ? Icon(
                                  Icons.check_circle,
                                  key: const ValueKey('check'),
                                  color: AppColors.success,
                                  size: 20,
                                )
                              : Icon(
                                  Icons.copy,
                                  key: const ValueKey('copy'),
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(102),
                                  size: 18,
                                ),
                        ),
                      ],
                    ),
                  ),
                  // Timer
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 3,
                            strokeCap: StrokeCap.round,
                            color: _timerColor,
                            backgroundColor:
                                theme.colorScheme.outline.withAlpha(51),
                          ),
                        ),
                        Text(
                          '$_remaining',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _timerColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
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
