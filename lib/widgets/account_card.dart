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
  final Future<void> Function()? onNextHOTP; // HOTP counter increment

  const AccountCard({
    super.key,
    required this.account,
    required this.totpService,
    required this.onEdit,
    required this.onDelete,
    required this.onShowQR,
    required this.onCopy,
    this.onNextHOTP,
  });

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  late String _code;
  late int _remaining;
  late double _progress;
  Timer? _timer;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    if (!widget.account.isHotp) {
      _timer =
          Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
    }
  }

  @override
  void didUpdateWidget(AccountCard old) {
    super.didUpdateWidget(old);
    // Refresh when HOTP counter changes
    if (old.account.counter != widget.account.counter) _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _code = widget.totpService.generateCode(widget.account);
      _remaining =
          widget.totpService.getRemainingSeconds(widget.account.period);
      _progress = widget.totpService.getProgress(widget.account.period);
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

  // Service-brand color for the left accent strip
  Color get _serviceColor =>
      AppColors.getServiceColor(widget.account.issuer);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final formattedCode = widget.account.isSteam
        ? _code // Steam: no split
        : widget.totpService.formatCode(_code);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _copyToClipboard,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left colour accent strip ──────────────────────────────
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_serviceColor, _serviceColor.withAlpha(160)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // ── Card body ─────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppConstants.paddingMD,
                        AppConstants.paddingMD,
                        AppConstants.paddingSM,
                        AppConstants.paddingMD,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row
                          _buildHeader(theme, l10n),
                          const SizedBox(height: AppConstants.paddingMD),
                          // Code row
                          _buildCodeRow(theme, l10n, formattedCode),
                        ],
                      ),
                    ),
                    // Bottom progress bar (TOTP / Steam only)
                    if (!widget.account.isHotp)
                      LinearProgressIndicator(
                        value: _progress,
                        minHeight: 3,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _timerColor.withAlpha(140),
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

  Widget _buildHeader(ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_serviceColor, _serviceColor.withAlpha(179)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          child: Center(
            child: Text(
              widget.account.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.paddingSM + 4),

        // Issuer + name + type badge
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.account.issuer,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Type badge
                  _buildTypeBadge(theme),
                ],
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

        // Context menu
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
              child: Row(children: [
                const Icon(Icons.qr_code_2, size: 20),
                const SizedBox(width: 12),
                Text(l10n.qrCode),
              ]),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Row(children: [
                const Icon(Icons.edit_outlined, size: 20),
                const SizedBox(width: 12),
                Text(l10n.edit),
              ]),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                const Icon(Icons.delete_outline,
                    size: 20, color: AppColors.error),
                const SizedBox(width: 12),
                Text(l10n.delete,
                    style: const TextStyle(color: AppColors.error)),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeBadge(ThemeData theme) {
    Color badgeColor;
    String label;
    if (widget.account.isHotp) {
      badgeColor = AppColors.secondary;
      label = 'HOTP';
    } else if (widget.account.isSteam) {
      badgeColor = AppColors.accent;
      label = 'Steam';
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(26),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: badgeColor.withAlpha(77)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildCodeRow(
      ThemeData theme, AppLocalizations l10n, String formattedCode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // OTP code
        Expanded(
          child: Row(
            children: [
              Text(
                formattedCode,
                style: TextStyle(
                  fontSize: widget.account.isSteam ? 22 : 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: widget.account.isSteam ? 4 : 3,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: (!widget.account.isHotp && _remaining <= 5)
                      ? AppColors.error
                      : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: AppConstants.paddingSM),
              AnimatedSwitcher(
                duration: AppConstants.animFast,
                child: _copied
                    ? const Icon(Icons.check_circle,
                        key: ValueKey('check'),
                        color: AppColors.success,
                        size: 18)
                    : Icon(Icons.copy,
                        key: const ValueKey('copy'),
                        color:
                            theme.colorScheme.onSurface.withAlpha(102),
                        size: 16),
              ),
            ],
          ),
        ),

        // Right side: timer (TOTP/Steam) or next-code button (HOTP)
        if (widget.account.isHotp)
          _buildNextButton(theme, l10n)
        else
          _buildTimerWidget(theme),
      ],
    );
  }

  Widget _buildTimerWidget(ThemeData theme) {
    return SizedBox(
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
              backgroundColor: theme.colorScheme.outline.withAlpha(51),
            ),
          ),
          Text(
            '$_remaining',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _timerColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(ThemeData theme, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        if (widget.onNextHOTP != null) {
          await widget.onNextHOTP!();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'Sonraki',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
