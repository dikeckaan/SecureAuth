import 'package:flutter/material.dart';
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

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.authService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TOTPService _totpService = TOTPService();
  final QRService _qrService = QRService();
  List<AccountModel> _accounts = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAccounts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
    }
  }

  void _loadAccounts() {
    setState(() {
      _accounts = widget.storageService.getAllAccounts();
    });
  }

  List<AccountModel> get _filteredAccounts {
    if (_searchQuery.isEmpty) {
      return _accounts;
    }
    return _accounts.where((account) {
      return account.issuer.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          account.name.toLowerCase().contains(_searchQuery.toLowerCase());
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

    if (result == true) {
      _loadAccounts();
    }
  }

  Future<void> _editAccount(AccountModel account) async {
    final nameController = TextEditingController(text: account.name);
    final issuerController = TextEditingController(text: account.issuer);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: issuerController,
              decoration: const InputDecoration(labelText: 'Yayıncı'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Hesap Adı'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              account.issuer = issuerController.text;
              account.name = nameController.text;
              widget.storageService.updateAccount(account);
              Navigator.pop(context, true);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadAccounts();
    }
  }

  Future<void> _deleteAccount(AccountModel account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: Text('${account.issuer} hesabını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.storageService.deleteAccount(account.id);
      _loadAccounts();
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SecureAuth'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _goToSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                labelText: 'Hesap Ara',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _filteredAccounts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.security,
                          size: 80,
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: AppConstants.defaultPadding),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Henüz hesap eklemediniz'
                              : 'Hesap bulunamadı',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultPadding,
                    ),
                    itemCount: _filteredAccounts.length,
                    itemBuilder: (context, index) {
                      final account = _filteredAccounts[index];
                      return AccountCard(
                        account: account,
                        totpService: _totpService,
                        onEdit: () => _editAccount(account),
                        onDelete: () => _deleteAccount(account),
                        onShowQR: () => _showQRCode(account),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAccount,
        icon: const Icon(Icons.add),
        label: const Text('Hesap Ekle'),
      ),
    );
  }
}
