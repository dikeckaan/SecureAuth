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

  /// Called with the new counter value when the user navigates HOTP codes.
  /// Only set for HOTP accounts.
  final Future<void> Function(int counter)? onSetCounter;

  const AccountCard({
    super.key,
    required this.account,
    required this.totpService,
    required this.onEdit,
    required this.onDelete,
    required this.onShowQR,
    required this.onCopy,
    this.onSetCounter,
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
    // HOTP has no time-based refresh; TOTP/Steam tick every second
    if (!widget.account.isHotp) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
    }
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

  /// Open a number-input dialog to jump to any counter value.
  Future<void> _showCounterPicker() async {
    final ctrl =
        TextEditingController(text: '${widget.account.counter}');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sayaç Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mevcut sayaç: ${widget.account.counter}',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurface
                        .withAlpha(153),
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Yeni sayaç değeri',
                prefixIcon: Icon(Icons.tag_outlined),
              ),
              onSubmitted: (v) {
                final val = int.tryParse(v);
                if (val != null && val >= 0) Navigator.pop(ctx, val);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text);
              if (val != null && val >= 0) Navigator.pop(ctx, val);
            },
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null && mounted) {
      widget.onSetCounter?.call(result);
    }
  }

  Color get _timerColor {
    if (_remaining <= 5) return AppColors.error;
    if (_remaining <= 10) return AppColors.warning;
    return AppColors.primary;
  }

  Color get _serviceColor => AppColors.getServiceColor(widget.account.issuer);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final formattedCode = widget.account.isSteam
        ? _code
        : widget.totpService.formatCode(_code);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _copyToClipboard,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left colour accent strip
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

              // Card body
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
                          _buildHeader(theme, l10n),
                          const SizedBox(height: AppConstants.paddingMD),
                          _buildCodeRow(theme, l10n, formattedCode),
                        ],
                      ),
                    ),
                    // Bottom progress bar — TOTP & Steam only
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

  // ── Header (avatar + issuer/name + type badge + menu) ────────────────────

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
                  _buildTypeBadge(),
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

  Widget _buildTypeBadge() {
    Color color;
    String label;
    if (widget.account.isHotp) {
      color = AppColors.secondary;
      label = 'HOTP';
    } else if (widget.account.isSteam) {
      color = AppColors.accent;
      label = 'Steam';
    } else {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // ── Code row ─────────────────────────────────────────────────────────────

  Widget _buildCodeRow(
      ThemeData theme, AppLocalizations l10n, String formattedCode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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
                        color: theme.colorScheme.onSurface.withAlpha(102),
                        size: 16),
              ),
            ],
          ),
        ),
        // Right side: timer (TOTP/Steam) or counter controls (HOTP)
        if (widget.account.isHotp)
          _buildCounterControls(theme)
        else
          _buildTimerWidget(theme),
      ],
    );
  }

  // ── TOTP/Steam circular timer ─────────────────────────────────────────────

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

  // ── HOTP counter controls [←] [counter] [→] ─────────────────────────────

  Widget _buildCounterControls(ThemeData theme) {
    final counter = widget.account.counter;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decrement button
        _CounterNavBtn(
          icon: Icons.chevron_left,
          enabled: counter > 0,
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onSetCounter?.call(counter - 1);
          },
        ),

        const SizedBox(width: 4),

        // Counter display — tappable to open picker
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _showCounterPicker();
          },
          child: Container(
            constraints: const BoxConstraints(minWidth: 40),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(20),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              border: Border.all(color: AppColors.secondary.withAlpha(70)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$counter',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '#',
                  style: TextStyle(
                    color: AppColors.secondary.withAlpha(150),
                    fontSize: 9,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 4),

        // Increment button
        _CounterNavBtn(
          icon: Icons.chevron_right,
          enabled: true,
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onSetCounter?.call(counter + 1);
          },
        ),
      ],
    );
  }
}

// ── Small reusable nav button ─────────────────────────────────────────────────

class _CounterNavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _CounterNavBtn({
    required this.icon,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.primaryGradient : null,
          color: enabled ? null : Colors.grey.withAlpha(60),
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.white : Colors.grey.withAlpha(130),
        ),
      ),
    );
  }
}
