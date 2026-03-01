# Biometric+AppLock Sync, Clipboard Token Expiry, Steam Experimental Flag

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Biometrik açılınca App Lock da açılsın; pano token süresi dolunca temizlensin; Steam Guard ayarlardan açılıp kapanabilen deneysel flag arkasına alınsın.

**Architecture:**
- `AppSettings` (Hive) modeline `steamGuardEnabled` (HiveField 16) eklenir; `app_settings.g.dart` yeniden üretilir.
- `SecurityService.copyToClipboardSecure` imzasına opsiyonel `period` parametresi eklenir; delay formülü `period - (now_seconds % period)` olur.
- `AuthService.secureCopy` imzası da `period` alacak şekilde genişler; `HomeScreen` account.period'ü iletir.
- Settings ekranında biometrik toggle açılınca `requireAuthOnLaunch` da true yapılır (ve tam tersi).

**Tech Stack:** Flutter/Dart, Hive, local_auth

---

## Kritik Dosyalar

| Dosya | Neden |
|-------|-------|
| `lib/models/app_settings.dart` | steamGuardEnabled alanı |
| `lib/models/app_settings.g.dart` | Hive adapter (yeniden üretilecek) |
| `lib/services/security_service.dart` | Clipboard period-aware timer |
| `lib/services/auth_service.dart` | secureCopy imzası |
| `lib/screens/home_screen.dart` | secureCopy çağrısı account.period ile |
| `lib/screens/settings_screen.dart` | Biometrik-AppLock sync + Steam flag toggle |
| `lib/screens/add_account_screen.dart` | Steam sekmesi flag'e bağlanır |

---

### Task 1: AppSettings'e steamGuardEnabled ekle

**Files:**
- Modify: `lib/models/app_settings.dart`
- Modify: `lib/models/app_settings.g.dart` (build_runner ile yeniden üret)

**Step 1: app_settings.dart'a yeni field ekle**

`lib/models/app_settings.dart` dosyasında `accountOrder` alanından sonra:

```dart
  /// Whether Steam Guard token type is visible in Add Account (experimental)
  @HiveField(16)
  bool steamGuardEnabled;
```

Constructor'a da default değer ekle:
```dart
    this.steamGuardEnabled = false,
```

**Step 2: Hive adapter'ı yeniden üret**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: `lib/models/app_settings.g.dart` güncellendi, hata yok.

**Step 3: Analiz**

```bash
flutter analyze lib/models/
```

Expected: No issues found.

**Step 4: Commit YOK** — Sonraki task ile birlikte commit edilecek.

---

### Task 2: Settings'e Steam Guard toggle ekle

**Files:**
- Modify: `lib/screens/settings_screen.dart`

**Step 1: State değişkeni ekle**

`_SettingsScreenState` sınıfında diğer late değişkenlerin yanına:

```dart
late bool _steamGuardEnabled;
```

**Step 2: initState'de yükle**

`initState`'deki settings yükleme bloğuna:

```dart
_steamGuardEnabled = settings.steamGuardEnabled;
```

**Step 3: Toggle güncelleme metodu ekle**

```dart
Future<void> _toggleSteamGuard(bool value) async {
  await _updateSetting((s) => s.steamGuardEnabled = value);
  setState(() => _steamGuardEnabled = value);
}
```

**Step 4: Ayarlar ekranına "Deneysel" bölümü ve toggle ekle**

Ayarlar ekranında uygun bir yere (güvenlik bölümünden sonra, en alta) yeni bir kart/bölüm ekle:

```dart
_buildSectionHeader(l10n, Icons.science_outlined, 'Deneysel'),
Card(
  child: Column(
    children: [
      SwitchListTile(
        title: const Text('Steam Guard'),
        subtitle: const Text(
          'Hesap eklerken Steam Guard sekmesini göster. '
          'Steam Guard QR kodları standart otpauth:// formatını kullanmaz.',
        ),
        value: _steamGuardEnabled,
        onChanged: _toggleSteamGuard,
        secondary: const Icon(Icons.videogame_asset_outlined),
      ),
    ],
  ),
),
```

**Step 5: Analiz**

```bash
flutter analyze lib/screens/settings_screen.dart
```

Expected: No issues found.

---

### Task 3: Add Account'ta Steam sekmesini flag'e bağla

**Files:**
- Modify: `lib/screens/add_account_screen.dart`

**Step 1: storageService parametresini ekle**

`AddAccountScreen` widget'ının constructor'ına `StorageService storageService` zaten var mı kontrol et. Yoksa ekle.

**Step 2: Steam sekmesini koşullu yap**

`_tokenTypes` sabit listesi yerine, `initState`'de settings'e göre dinamik liste oluştur:

```dart
late List<_TokenTypeOption> _tokenTypes;

@override
void initState() {
  super.initState();
  final settings = widget.storageService.getSettings();
  _tokenTypes = [
    const _TokenTypeOption('totp', 'TOTP', Icons.access_time_outlined),
    const _TokenTypeOption('hotp', 'HOTP', Icons.tag_outlined),
    if (settings.steamGuardEnabled)
      const _TokenTypeOption('steam', 'Steam', Icons.videogame_asset_outlined),
  ];
  _tabController = TabController(length: _tokenTypes.length, vsync: this);
  // ... geri kalan initState kodu
}
```

NOT: `_tokenTypes` artık `static const` değil, `late` instance variable.

**Step 3: Analiz**

```bash
flutter analyze lib/screens/add_account_screen.dart
```

Expected: No issues found.

**Step 4: Commit (Task 1+2+3)**

```bash
git add lib/models/app_settings.dart lib/models/app_settings.g.dart \
        lib/screens/settings_screen.dart lib/screens/add_account_screen.dart
git commit -m "feat: add Steam Guard experimental flag in settings"
```

---

### Task 4: Biometrik ↔ App Lock senkronizasyonu

**Files:**
- Modify: `lib/screens/settings_screen.dart`

**Step 1: Mevcut _toggleBiometric metodunu bul**

`settings_screen.dart` içinde `_toggleBiometric` (veya biometric toggle'ın onChanged callback'i) metodunu bul.

**Step 2: Biometrik açılınca App Lock'u da aç**

```dart
Future<void> _toggleBiometric(bool value) async {
  if (value) {
    // Biometrik açılırken password zorunlu — mevcut kontrol devam eder
    // Ayrıca App Lock'u da aktif et
    if (!_requireAuthOnLaunch) {
      await _updateSetting((s) => s.requireAuthOnLaunch = true);
      setState(() => _requireAuthOnLaunch = true);
    }
  }
  // ... mevcut biometrik toggle kodu devam eder
}
```

**Step 3: App Lock kapatılınca biometriği de kapat**

`requireAuthOnLaunch` toggle'ının `onChanged` callback'inde, değer `false` olduğunda:

```dart
onChanged: (value) async {
  await _updateSetting((s) => s.requireAuthOnLaunch = value);
  setState(() => _requireAuthOnLaunch = value);
  if (!value && _isBiometricEnabled) {
    // App Lock kapatılırsa biometriği de kapat
    await widget.authService.enableBiometric(false);
    setState(() => _isBiometricEnabled = false);
  }
},
```

NOT: `_isBiometricEnabled` state değişkeninin adını settings_screen.dart içinde doğrula.

**Step 4: Analiz**

```bash
flutter analyze lib/screens/settings_screen.dart
```

**Step 5: Commit**

```bash
git add lib/screens/settings_screen.dart
git commit -m "feat: sync biometric and app lock toggles"
```

---

### Task 5: Clipboard'ı token süresi dolunca temizle

**Files:**
- Modify: `lib/services/security_service.dart`
- Modify: `lib/services/auth_service.dart`
- Modify: `lib/screens/home_screen.dart`

**Step 1: security_service.dart — period parametresi ekle**

`copyToClipboardSecure` imzasını güncelle:

```dart
Future<void> copyToClipboardSecure(
  String text,
  int clearAfterSeconds, {
  bool clearEnabled = true,
  int? period,
}) async {
```

Timer delay hesabını güncelle:

```dart
  if (!clearEnabled) return;

  final int delaySeconds;
  if (period != null && period > 0) {
    // Token'ın kalan süresi: period sonuna kadar bekle
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = period - (nowSeconds % period);
    delaySeconds = remaining > 0 ? remaining : period;
  } else {
    delaySeconds = clearAfterSeconds;
  }

  Future.delayed(Duration(seconds: delaySeconds), () {
    // ... mevcut temizleme kodu
  });
```

**Step 2: auth_service.dart — secureCopy imzasını genişlet**

```dart
Future<void> secureCopy(String text, {int? period}) async {
  final settings = _storageService.getSettings();
  await _securityService.copyToClipboardSecure(
    text,
    settings.clipboardClearSeconds,
    clearEnabled: settings.clearClipboard,
    period: period,
  );
}
```

**Step 3: home_screen.dart — account.period'ü ilet**

`secureCopy` çağrısını bul ve account bilgisini ekle. TOTP ve Steam için period'ü ilet, HOTP için null bırak (counter-based, expiry yok):

```dart
// Mevcut: await widget.authService.secureCopy(code);
// Yeni:
final periodOrNull = account.isHotp ? null : account.period;
await widget.authService.secureCopy(code, period: periodOrNull);
```

**Step 4: Analiz**

```bash
flutter analyze lib/services/security_service.dart \
               lib/services/auth_service.dart \
               lib/screens/home_screen.dart
```

Expected: No issues found.

**Step 5: Commit**

```bash
git add lib/services/security_service.dart \
        lib/services/auth_service.dart \
        lib/screens/home_screen.dart
git commit -m "feat: clear clipboard on token period expiry instead of fixed 30s"
```

---

### Task 6: Release build al ve iPhone'a kur

**Step 1: Build**

```bash
flutter build ios --release
```

Expected: `✓ Built build/ios/iphoneos/Runner.app`

**Step 2: Kur**

```bash
xcrun devicectl device install app \
  --device 00008120-000E19AC3603C01E \
  build/ios/iphoneos/Runner.app
```

Expected: `App installed:`

**Step 3: Final backup commit**

```bash
git add -A
git commit -m "chore: backup — biometric+applock sync, clipboard token expiry, steam experimental flag"
```

---

## Test Senaryoları

| Senaryo | Beklenen |
|---------|---------|
| Ayarlar → Biometrik AÇ | App Lock otomatik AÇ |
| Ayarlar → App Lock KAPAT | Biometrik otomatik KAPAT |
| TOTP kodu kopyala | Clipboard, period sonu gelince temizlenir |
| HOTP kodu kopyala | Clipboard 30s sonra temizlenir (period yok) |
| Steam Guard flag KAPALI | Hesap ekle'de Steam sekmesi gözükmez |
| Steam Guard flag AÇIK | Hesap ekle'de Steam sekmesi gözükür |
