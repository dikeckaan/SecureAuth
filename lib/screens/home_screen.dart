import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:secure_auth/l10n/app_localizations.dart';

import '../models/account_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/totp_service.dart';
import '../services/qr_service.dart';
import '../utils/constants.dart';
import '../widgets/account_card.dart';
import 'add_account_screen.dart';
import 'settings_screen.dart';
import 'qr_display_screen.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;
  final AuthService authService;
  final VoidCallback onThemeChanged;
  final VoidCallback onLocaleChanged;

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.authService,
    required this.onThemeChanged,
    required this.onLocaleChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TOTPService _totpService = TOTPService();
  final QRService _qrService = QRService();
  final _searchController = TextEditingController();

  List<AccountModel> _accounts = [];
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAccounts();
    widget.authService.recordActivity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.authService.recordActivity();
    }
  }

  void _loadAccounts() {
    setState(() {
      _accounts = widget.storageService.getAllAccounts();
    });
  }

  List<AccountModel> get _filtered {
    if (_searchQuery.isEmpty) return _accounts;
    final q = _searchQuery.toLowerCase();
    return _accounts.where((a) {
      return a.issuer.toLowerCase().contains(q) ||
          a.name.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _addAccount() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddAccountScreen(
          storageService: widget.storageService,
          totpService: _totpService,
        ),
      ),
    );
    if (result == true) _loadAccounts();
  }

  Future<void> _editAccount(AccountModel account) async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: account.name);
    final issuerCtrl = TextEditingController(text: account.issuer);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: issuerCtrl,
              decoration: InputDecoration(
                labelText: l10n.serviceName,
                prefixIcon: const Icon(Icons.business_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppConstants.paddingMD),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.accountName,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (issuerCtrl.text.trim().isEmpty ||
                  nameCtrl.text.trim().isEmpty) {
                return;
              }
              account.issuer = issuerCtrl.text.trim();
              account.name = nameCtrl.text.trim();
              widget.storageService.updateAccount(account);
              Navigator.pop(ctx, true);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    issuerCtrl.dispose();
    if (result == true) _loadAccounts();
  }

  Future<void> _deleteAccount(AccountModel account) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteAccountConfirm(account.issuer)),
            const SizedBox(height: AppConstants.paddingSM),
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingSM),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusSM),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.actionIrreversible,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.storageService.deleteAccount(account.id);
      _loadAccounts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.accountDeleted),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showQRCode(AccountModel account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            QRDisplayScreen(account: account, qrService: _qrService),
      ),
    );
  }

  Future<void> _goToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          storageService: widget.storageService,
          authService: widget.authService,
          onThemeChanged: widget.onThemeChanged,
          onLocaleChanged: widget.onLocaleChanged,
        ),
      ),
    );
    _loadAccounts();
  }

  Future<void> _copyCode(String code) async {
    HapticFeedback.lightImpact();
    await widget.authService.secureCopy(code);
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      final settings = widget.storageService.getSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(l10n.codeCopied(settings.clipboardClearSeconds)),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _setHOTPCounter(AccountModel account, int counter) async {
    await widget.storageService.setHOTPCounter(account, counter);
    // Reload so the card gets a new key (includes counter) → full rebuild
    _loadAccounts();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppConstants.paddingMD,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: l10n.searchAccounts,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withAlpha(102),
                  ),
                ),
              )
            : _buildAppBarTitle(theme, l10n),
        actions: [
          if (_accounts.isNotEmpty)
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: _toggleSearch,
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _goToSettings,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _accounts.isEmpty
          ? _buildEmptyState(theme, l10n)
          : filtered.isEmpty
              ? _buildNoResults(theme, l10n)
              : _buildAccountList(filtered, l10n),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAccount,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildAppBarTitle(ThemeData theme, AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          child: Image.asset(
            'assets/icon/app_icon.png',
            width: 28,
            height: 28,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Text(l10n.appName),
        if (_accounts.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            ),
            child: Text(
              '${_accounts.length}',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusXL),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 96,
                height: 96,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLG),
            Text(
              l10n.noAccountsYet,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withAlpha(200),
              ),
            ),
            const SizedBox(height: AppConstants.paddingSM),
            Text(
              l10n.addAccountsToImprove,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(102),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingXL),
            // Quick-start type chips
            Wrap(
              spacing: AppConstants.paddingSM,
              children: [
                _buildTypeChip('TOTP', Icons.access_time_outlined,
                    theme.colorScheme.primary),
                _buildTypeChip(
                    'HOTP', Icons.tag_outlined, theme.colorScheme.secondary),
                _buildTypeChip('Steam',
                    Icons.videogame_asset_outlined, AppColors.accent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 48,
              color: theme.colorScheme.onSurface.withAlpha(102)),
          const SizedBox(height: AppConstants.paddingMD),
          Text(
            l10n.accountNotFound,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountList(
      List<AccountModel> accounts, AppLocalizations l10n) {
    return ListView.builder(
      padding: const EdgeInsets.only(
        top: AppConstants.paddingSM,
        bottom: 100,
      ),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        return AccountCard(
          // Key includes counter so Flutter destroys & recreates the card
          // whenever the HOTP counter changes → initState() reruns → new code
          key: ValueKey('${account.id}_${account.counter}'),
          account: account,
          totpService: _totpService,
          onEdit: () => _editAccount(account),
          onDelete: () => _deleteAccount(account),
          onShowQR: () => _showQRCode(account),
          onCopy: _copyCode,
          onSetCounter:
              account.isHotp ? (c) => _setHOTPCounter(account, c) : null,
        );
      },
    );
  }
}
