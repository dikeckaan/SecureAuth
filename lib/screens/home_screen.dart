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
  List<AccountModel> _accounts = [];
  String _searchQuery = '';
  bool _isSearching = false;
  final _searchController = TextEditingController();

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

  List<AccountModel> get _filteredAccounts {
    if (_searchQuery.isEmpty) return _accounts;
    final query = _searchQuery.toLowerCase();
    return _accounts.where((account) {
      return account.issuer.toLowerCase().contains(query) ||
          account.name.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _addAccount() async {
    final result = await Navigator.push(
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
    final nameController = TextEditingController(text: account.name);
    final issuerController = TextEditingController(text: account.issuer);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: issuerController,
              decoration: InputDecoration(
                labelText: l10n.serviceName,
                prefixIcon: const Icon(Icons.business_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppConstants.paddingMD),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.accountName,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (issuerController.text.trim().isEmpty ||
                  nameController.text.trim().isEmpty) {
                return;
              }
              account.issuer = issuerController.text.trim();
              account.name = nameController.text.trim();
              widget.storageService.updateAccount(account);
              Navigator.pop(context, true);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    nameController.dispose();
    issuerController.dispose();

    if (result == true) _loadAccounts();
  }

  Future<void> _deleteAccount(AccountModel account) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
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
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
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
        builder: (context) => QRDisplayScreen(
          account: account,
          qrService: _qrService,
        ),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final filtered = _filteredAccounts;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) => setState(() => _searchQuery = value),
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
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSM),
                    ),
                    child: const Icon(Icons.shield,
                        size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(l10n.appName),
                ],
              ),
        actions: [
          if (_accounts.isNotEmpty)
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchQuery = '';
                    _searchController.clear();
                  }
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _goToSettings,
          ),
        ],
      ),
      body: _accounts.isEmpty
          ? _buildEmptyState(theme, l10n)
          : filtered.isEmpty
              ? _buildNoResults(theme, l10n)
              : _buildAccountList(filtered),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAccount,
        icon: const Icon(Icons.add),
        label: Text(l10n.addAccount),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.security,
                size: 48,
                color: theme.colorScheme.primary.withAlpha(128),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLG),
            Text(
              l10n.noAccountsYet,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withAlpha(179),
              ),
            ),
            const SizedBox(height: AppConstants.paddingSM),
            Text(
              l10n.addAccountsToImprove,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(102),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: theme.colorScheme.onSurface.withAlpha(102),
          ),
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

  Widget _buildAccountList(List<AccountModel> accounts) {
    return ListView.builder(
      padding: const EdgeInsets.only(
        top: AppConstants.paddingSM,
        bottom: 100,
      ),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        return AccountCard(
          account: account,
          totpService: _totpService,
          onEdit: () => _editAccount(account),
          onDelete: () => _deleteAccount(account),
          onShowQR: () => _showQRCode(account),
          onCopy: _copyCode,
        );
      },
    );
  }
}
