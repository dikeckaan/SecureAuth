import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.authService,
    required this.onThemeChanged,
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
    final nameController = TextEditingController(text: account.name);
    final issuerController = TextEditingController(text: account.issuer);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabi Duzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: issuerController,
              decoration: const InputDecoration(
                labelText: 'Servis Adi',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppConstants.paddingMD),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Hesap Adi',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Iptal'),
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
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    nameController.dispose();
    issuerController.dispose();

    if (result == true) _loadAccounts();
  }

  Future<void> _deleteAccount(AccountModel account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabi Sil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${account.issuer} hesabini silmek istediginizden emin misiniz?'),
            const SizedBox(height: AppConstants.paddingSM),
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingSM),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bu islem geri alinamaz',
                      style: TextStyle(
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
            child: const Text('Iptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.storageService.deleteAccount(account.id);
      _loadAccounts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hesap silindi'),
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
        ),
      ),
    );
    _loadAccounts();
  }

  Future<void> _copyCode(String code) async {
    HapticFeedback.lightImpact();
    await widget.authService.secureCopy(code);

    if (mounted) {
      final settings = widget.storageService.getSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                  'Kod kopyalandi (${settings.clipboardClearSeconds}sn sonra silinecek)'),
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
                  hintText: 'Hesap ara...',
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
                  const Text('SecureAuth'),
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
          ? _buildEmptyState(theme)
          : filtered.isEmpty
              ? _buildNoResults(theme)
              : _buildAccountList(filtered),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAccount,
        icon: const Icon(Icons.add),
        label: const Text('Hesap Ekle'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
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
              'Henuz hesap eklemediniz',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withAlpha(179),
              ),
            ),
            const SizedBox(height: AppConstants.paddingSM),
            Text(
              '2FA hesaplarinizi ekleyerek\nguvenliginizi artirin',
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

  Widget _buildNoResults(ThemeData theme) {
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
            'Hesap bulunamadi',
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
