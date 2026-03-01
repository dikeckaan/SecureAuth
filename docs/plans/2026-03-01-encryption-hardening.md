# Encryption Hardening + Security Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Upgrade SecureAuth's entire security stack — PBKDF2 → Argon2id, encrypt the settings Hive box, fix TextEditingController disposal bugs in backup dialogs, add Android screen-capture protection, and raise the minimum password length.

**Architecture:** Add `hashlib` (pure-Dart, all platforms) for Argon2id KDF. Replace PBKDF2 in `SecurityService` and `BackupEncryptionService`. On first successful login with an old PBKDF2 hash, transparently re-hash with Argon2id and save. Encrypt `_settingsBox` with a separate AES-256 key stored in OS keychain alongside the existing accounts key.

**Tech Stack:** Flutter/Dart, hashlib (Argon2id), Hive + HiveAesCipher, flutter_secure_storage, dart:isolate

---

## Context for implementer

### Key files
- `lib/services/security_service.dart` — app-lock password hashing (PBKDF2-SHA512 today)
- `lib/services/backup_encryption_service.dart` — backup file KDF + AES-256-GCM
- `lib/services/storage_service.dart` — Hive box init; settings box is currently **unencrypted**
- `lib/models/app_settings.dart` — Hive model; needs `hashVersion` field added
- `lib/models/app_settings.g.dart` — auto-generated adapter (must regenerate after model change)
- `lib/utils/constants.dart` — `AppConstants.minPasswordLength` (currently 6)
- `lib/screens/settings_screen.dart` — two dialogs with TextEditingController disposal bugs
- `android/app/src/main/kotlin/.../MainActivity.kt` — FLAG_SECURE goes here
- `pubspec.yaml` — add `hashlib`
- `README.md` — rewrite from scratch at the end

### Current state
- `SecurityService.hashPassword` / `verifyPassword` are **synchronous** and run on the main thread.
- `BackupEncryptionService._deriveKey` already runs in `Isolate.run(...)`.
- `AppSettings` has `passwordHash` (String?) and `passwordSalt` (String?) fields.
  No field records which algorithm produced the hash → migration needs to detect by trying.
- `_showSetPasswordDialog` and `_showDecryptPasswordDialog` in `settings_screen.dart` have the same
  `TextEditingController.dispose()` race we already fixed for `_changePassword`.

### Argon2id parameters (hashlib)
```dart
import 'package:hashlib/hashlib.dart';

final hash = await Argon2id(
  memory: 32768,   // 32 MB
  iterations: 3,
  parallelism: 1,
  hashLength: 32,
).convert(utf8.encode(password), salt: salt);
```
These are above OWASP "interactive" minimum (m=19456, t=2, p=1) while staying fast enough on mid-range phones (~300 ms in Isolate).

### Algorithm version strategy
Add `String? hashVersion` to `AppSettings`:
- `null` or `'pbkdf2'` → legacy hash, re-hash on next successful login
- `'argon2id'` → new hash

`SecurityService.verifyPassword` already receives `storedHash` + `salt` from the caller (`AuthService`).
`AuthService.verifyPassword` is the right place to trigger the transparent migration:
```dart
if (isValid && needsMigration) {
  await setPassword(password);  // re-hashes with Argon2id, updates hashVersion
}
```

### Settings box encryption
Same pattern as accounts box. New key name: `'settings_encryption_key'`.
```dart
_settingsBoxInstance = await Hive.openBox<AppSettings>(
  _settingsBox,
  encryptionCipher: HiveAesCipher(settingsKeyBytes),
);
```
⚠️ This is a **breaking change** for existing users: opening an unencrypted box with a cipher throws.
Mitigation: try/catch — if open with cipher fails, delete and recreate the box (settings are non-critical preferences; password hash is re-derivable at next login).

### Android FLAG_SECURE
`MainActivity.kt` is at `android/app/src/main/kotlin/com/example/secure_auth/MainActivity.kt`
(verify the exact path below). Add one line in `onCreate`:
```kotlin
window.setFlags(
    WindowManager.LayoutParams.FLAG_SECURE,
    WindowManager.LayoutParams.FLAG_SECURE
)
```

---

## Task 1: Add `hashlib` dependency

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Add the dependency**

In `pubspec.yaml`, under `dependencies:`, add after the `crypto` line:
```yaml
  hashlib: ^1.20.0
```

**Step 2: Install**

```bash
flutter pub get
```
Expected: resolves without conflict (hashlib is pure Dart, no native code).

**Step 3: Smoke-test import**

Add a temporary `import 'package:hashlib/hashlib.dart';` to any dart file, run `flutter analyze`, then remove it. Expected: no errors.

**Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add hashlib for Argon2id support"
```

---

## Task 2: Add `hashVersion` field to `AppSettings`

**Files:**
- Modify: `lib/models/app_settings.dart`
- Regenerate: `lib/models/app_settings.g.dart`

**Step 1: Add fields to model**

In `app_settings.dart`, add after the last `@HiveField` (currently field 16):
```dart
/// KDF algorithm used for passwordHash.
/// null or 'pbkdf2' = legacy PBKDF2-SHA512.
/// 'argon2id' = Argon2id (m=32768, t=3, p=1).
@HiveField(17)
String? hashVersion;

/// Whether to block screenshots and app-switcher preview (Android FLAG_SECURE).
@HiveField(18)
bool screenProtection;
```
Also add to the constructor:
- `this.hashVersion,` (no default — null = legacy)
- `this.screenProtection = true,` (default on — safer)

**Step 2: Regenerate the adapter**

```bash
cd /Users/kaandikec/Desktop/SecureAuth
dart run build_runner build --delete-conflicting-outputs
```
Expected: `app_settings.g.dart` regenerated, no errors.

**Step 3: Verify**

```bash
flutter analyze lib/models/
```
Expected: No issues found.

**Step 4: Commit**

```bash
git add lib/models/app_settings.dart lib/models/app_settings.g.dart
git commit -m "feat: add hashVersion field to AppSettings for KDF migration"
```

---

## Task 3: Rewrite `SecurityService` to use Argon2id

**Files:**
- Modify: `lib/services/security_service.dart`

### What changes
- Replace the `_pbkdf2(...)` private method with an Argon2id derivation.
- Make `hashPassword` and `verifyPassword` **async** (they now run in `Isolate.run`).
- Keep `generateSalt()` as-is (already uses `Random.secure()`).
- Keep `_constantTimeEquals` as-is.
- Remove `AppConstants.pbkdf2Iterations` / `AppConstants.derivedKeyLength` usage (these become unused in this file; leave the constants for BackupEncryptionService migration reference — they'll be removed in Task 4).

### Argon2id parameters
```
memory:      32768  (32 MB)
iterations:  3
parallelism: 1
hashLength:  32     (256 bits — enough for a stored hash)
```

**Step 1: Update imports**

Replace:
```dart
import 'package:crypto/crypto.dart';
```
With:
```dart
import 'package:hashlib/hashlib.dart';
```
Keep all other imports.

**Step 2: Replace `hashPassword` with async version**

Old signature: `String hashPassword(String password, Uint8List salt)`
New signature: `Future<String> hashPassword(String password, Uint8List salt)`

New implementation:
```dart
Future<String> hashPassword(String password, Uint8List salt) async {
  final derived = await Isolate.run(
    () => _argon2id(password: password, salt: salt),
  );
  return base64Url.encode(derived);
}
```

**Step 3: Replace `verifyPassword` with async version**

Old signature: `bool verifyPassword(String password, String storedHash, Uint8List salt)`
New signature: `Future<bool> verifyPassword(String password, String storedHash, Uint8List salt)`

New implementation:
```dart
Future<bool> verifyPassword(
    String password, String storedHash, Uint8List salt) async {
  final computedHash = await hashPassword(password, salt);
  return _constantTimeEquals(computedHash, storedHash);
}
```

**Step 4: Replace `_pbkdf2` with `_argon2id`**

Remove the entire `_pbkdf2` method. Add:
```dart
/// Derives a 256-bit key using Argon2id.
/// Safe to run inside a Dart Isolate (pure Dart via hashlib).
static Uint8List _argon2id({
  required String password,
  required Uint8List salt,
}) {
  final hash = Argon2id(
    memory: 32768,
    iterations: 3,
    parallelism: 1,
    hashLength: 32,
  ).convert(utf8.encode(password), salt: salt);
  return Uint8List.fromList(hash.bytes);
}
```

**Step 5: Remove now-unused imports**

Check if `dart:math` is still needed (it is — `Random.secure()` uses it). Keep it.
`crypto` is no longer needed in this file. Remove that import.

**Step 6: Analyze**

```bash
flutter analyze lib/services/security_service.dart
```
Expected: No issues found.

**Step 7: Commit**

```bash
git add lib/services/security_service.dart
git commit -m "feat: replace PBKDF2 with Argon2id in SecurityService"
```

---

## Task 4: Update `AuthService` for async hashing + transparent migration

**Files:**
- Modify: `lib/services/auth_service.dart`

### What changes
- `setPassword` and `verifyPassword` in `AuthService` call `SecurityService` — those are now async.
- `verifyPassword` must detect legacy PBKDF2 hashes and transparently re-hash.
- `AuthService.verifyPassword` must also handle the case where `hashVersion` is `'pbkdf2'` by calling the old PBKDF2 path first, then re-hashing on success.

### How to verify legacy vs new
- Check `settings.hashVersion`: if `null` or `'pbkdf2'` → use legacy path (keep old PBKDF2 verifier as a private static in `AuthService` or `SecurityService`).
- After successful legacy verify → call `setPassword(password)` which will use the new Argon2id path and set `hashVersion = 'argon2id'`.

**Step 1: Add legacy PBKDF2 verifier to `SecurityService`**

We need to keep the old PBKDF2 code **only** for migration. Add a private static method to `SecurityService`:

```dart
/// Legacy PBKDF2-SHA512 verifier — used only during migration.
/// Returns true if [password] matches the PBKDF2-derived [storedHash].
static Future<bool> verifyLegacyPbkdf2(
    String password, String storedHash, Uint8List salt) async {
  final derived = await Isolate.run(
    () => _pbkdf2Legacy(password: password, salt: salt),
  );
  final computed = base64Url.encode(derived);
  // Constant-time compare
  if (computed.length != storedHash.length) return false;
  var result = 0;
  for (var i = 0; i < computed.length; i++) {
    result |= computed.codeUnitAt(i) ^ storedHash.codeUnitAt(i);
  }
  return result == 0;
}

static Uint8List _pbkdf2Legacy({
  required String password,
  required Uint8List salt,
}) {
  // Original parameters: SHA512, 100000 iterations, 64-byte output
  final passwordBytes = utf8.encode(password);
  const hashLength = 64;
  final iterations = AppConstants.pbkdf2Iterations; // 100000
  final keyLength = AppConstants.derivedKeyLength;   // 64
  final numBlocks = (keyLength + hashLength - 1) ~/ hashLength;
  final dk = <int>[];

  for (var blockNum = 1; blockNum <= numBlocks; blockNum++) {
    final blockBytes = ByteData(4)..setUint32(0, blockNum, Endian.big);
    final saltBlock = Uint8List.fromList([
      ...salt,
      ...blockBytes.buffer.asUint8List(),
    ]);
    // Need crypto package re-imported locally or use hashlib's Hmac
    // Use hashlib: HmacSha512
    final hmacKey = HmacSha512.of(passwordBytes);
    var u = Uint8List.fromList(hmacKey.convert(saltBlock).bytes);
    final t = List<int>.from(u);
    for (var i = 1; i < iterations; i++) {
      u = Uint8List.fromList(hmacKey.convert(u).bytes);
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    dk.addAll(t);
  }
  return Uint8List.fromList(dk.sublist(0, keyLength));
}
```

Note: `hashlib` provides `HmacSha512` so `crypto` package is not re-needed.

**Step 2: Update `AuthService.setPassword`**

Old:
```dart
Future<void> setPassword(String password) async {
  final salt = _securityService.generateSalt();
  final hash = _securityService.hashPassword(password, salt);
  ...
```

New (hashPassword is now async, also save hashVersion):
```dart
Future<void> setPassword(String password) async {
  final salt = _securityService.generateSalt();
  final hash = await _securityService.hashPassword(password, salt);
  final saltBase64 = base64Url.encode(salt);

  final settings = _storageService.getSettings();
  settings.passwordHash = hash;
  settings.passwordSalt = saltBase64;
  settings.hashVersion = 'argon2id';
  await _storageService.updateSettings(settings);
}
```

**Step 3: Update `AuthService.verifyPassword`**

Replace the body with:
```dart
Future<bool> verifyPassword(String password) async {
  final settings = _storageService.getSettings();
  if (settings.passwordHash == null || settings.passwordSalt == null) {
    return false;
  }

  if (await _securityService.isLockedOut()) return false;

  final salt = base64Url.decode(settings.passwordSalt!);
  final isLegacy =
      settings.hashVersion == null || settings.hashVersion == 'pbkdf2';

  bool isValid;
  if (isLegacy) {
    isValid = await SecurityService.verifyLegacyPbkdf2(
        password, settings.passwordHash!, salt);
  } else {
    isValid = await _securityService.verifyPassword(
        password, settings.passwordHash!, salt);
  }

  if (isValid) {
    await _securityService.resetFailedAttempts();
    await _securityService.recordActivity();
    // Transparent migration: re-hash with Argon2id if still on legacy
    if (isLegacy) {
      await setPassword(password);
    }
  } else {
    await _securityService.recordFailedAttempt();

    final failedAttempts = await _securityService.getFailedAttempts();
    if (settings.wipeOnMaxAttempts &&
        failedAttempts >= settings.maxFailedAttempts) {
      await _storageService.clearAllData();
      await _securityService.clearSecurityState();
    }
  }

  return isValid;
}
```

**Step 4: Analyze**

```bash
flutter analyze lib/services/auth_service.dart lib/services/security_service.dart
```
Expected: No issues found.

**Step 5: Commit**

```bash
git add lib/services/auth_service.dart lib/services/security_service.dart
git commit -m "feat: transparent PBKDF2→Argon2id migration on successful login"
```

---

## Task 5: Rewrite `BackupEncryptionService` to use Argon2id

**Files:**
- Modify: `lib/services/backup_encryption_service.dart`

### What changes
- KDF: PBKDF2-HMAC-SHA256 (200k iter, 16-byte salt) → **Argon2id** (m=32768, t=3, p=1, 32-byte salt)
- File format version: bump from `0x01` to `0x02`
- Old format (`0x01`) still readable for backward compatibility
- New binary layout:
  ```
  Offset  Len  Field
     0     5   Magic: "SAENC"
     5     1   Version: 0x02
     6    32   Salt (was 16)
    38    12   AES-GCM nonce (standard 12 bytes; was 16)
    50     *   AES-256-GCM ciphertext ∥ 16-byte tag
  ```
  Note: Argon2id with the parameters above produces a 32-byte key → AES-256 key directly. No iterations field needed (Argon2id params are hard-coded in the binary).

**Step 1: Update constants**

```dart
static const List<int> _magic = [0x53, 0x41, 0x45, 0x4E, 0x43]; // "SAENC"
static const int _versionV1 = 0x01;
static const int _versionV2 = 0x02;
static const int _saltLenV1 = 16;
static const int _saltLenV2 = 32;
static const int _nonceLenV1 = 16;
static const int _nonceLenV2 = 12;  // standard GCM nonce
static const int _tagLen = 16;
static const int _keyLen = 32;      // AES-256
// V2 header: 5 magic + 1 version + 32 salt + 12 nonce = 50 bytes
static const int _headerLenV2 = 5 + 1 + _saltLenV2 + _nonceLenV2;
static const int _minFileLenV2 = _headerLenV2 + _tagLen; // 66 bytes
```

**Step 2: Replace `encryptBackup`**

```dart
static Future<Uint8List> encryptBackup(
    String jsonData, String password) async {
  final salt = _secureRandom(_saltLenV2);
  final nonce = _secureRandom(_nonceLenV2);
  final keyBytes = await Isolate.run(
    () => _argon2idKey(password: password, salt: salt),
  );

  final encrypter =
      enc.Encrypter(enc.AES(enc.Key(keyBytes), mode: enc.AESMode.gcm));
  final encrypted = encrypter.encrypt(jsonData, iv: enc.IV(nonce));

  final out = BytesBuilder(copy: false)
    ..add(_magic)
    ..addByte(_versionV2)
    ..add(salt)
    ..add(nonce)
    ..add(encrypted.bytes);
  return out.toBytes();
}
```

**Step 3: Replace `decryptBackup` — support both V1 and V2**

```dart
static Future<String> decryptBackup(
    Uint8List data, String password) async {
  if (data.length < _magic.length + 1) {
    throw const FormatException('File too small to be a valid backup');
  }
  for (var i = 0; i < _magic.length; i++) {
    if (data[i] != _magic[i]) {
      throw const FormatException('Not a SecureAuth encrypted backup');
    }
  }

  final version = data[_magic.length];

  if (version == _versionV2) {
    return _decryptV2(data, password);
  } else if (version == _versionV1) {
    return _decryptV1(data, password);
  } else {
    throw FormatException('Unknown backup format version: $version');
  }
}
```

**Step 4: Add `_decryptV2`**

```dart
static Future<String> _decryptV2(
    Uint8List data, String password) async {
  if (data.length < _minFileLenV2) {
    throw const FormatException('File too small to be a valid V2 backup');
  }
  int off = _magic.length + 1; // skip magic + version
  final salt = Uint8List.fromList(data.sublist(off, off + _saltLenV2));
  off += _saltLenV2;
  final nonce = Uint8List.fromList(data.sublist(off, off + _nonceLenV2));
  off += _nonceLenV2;
  final ciphertext = Uint8List.fromList(data.sublist(off));

  if (ciphertext.length < _tagLen) {
    throw const FormatException('Ciphertext too short');
  }

  final keyBytes = await Isolate.run(
    () => _argon2idKey(password: password, salt: salt),
  );
  final encrypter =
      enc.Encrypter(enc.AES(enc.Key(keyBytes), mode: enc.AESMode.gcm));
  try {
    return encrypter.decrypt(enc.Encrypted(ciphertext), iv: enc.IV(nonce));
  } catch (_) {
    throw const FormatException('Wrong password or corrupted backup file');
  }
}
```

**Step 5: Move old V1 logic into `_decryptV1`**

Extract the existing `decryptBackup` body (the PBKDF2 path) into a private `_decryptV1` static method. Keep all V1 constants (`_saltLen`, `_nonceLen` as V1 variants) so old backups remain decryptable.

```dart
static Future<String> _decryptV1(
    Uint8List data, String password) async {
  // V1 layout: 5 magic + 1 version + 4 iterations + 16 salt + 16 nonce + ciphertext
  const headerLen = 5 + 1 + 4 + 16 + 16; // 42
  if (data.length < headerLen + _tagLen) {
    throw const FormatException('File too small to be a valid V1 backup');
  }
  int off = _magic.length + 1;
  final iterations = _rd32(data, off); off += 4;
  if (iterations < 1000 || iterations > 5000000) {
    throw const FormatException('Invalid KDF parameters in backup file');
  }
  final salt = Uint8List.fromList(data.sublist(off, off + 16)); off += 16;
  final nonce = Uint8List.fromList(data.sublist(off, off + 16)); off += 16;
  final ciphertext = Uint8List.fromList(data.sublist(off));
  if (ciphertext.length < _tagLen) {
    throw const FormatException('Ciphertext too short');
  }
  final keyBytes = await Isolate.run(
    () => _pbkdf2V1(password: password, salt: salt, iterations: iterations),
  );
  final encrypter =
      enc.Encrypter(enc.AES(enc.Key(keyBytes), mode: enc.AESMode.gcm));
  try {
    return encrypter.decrypt(enc.Encrypted(ciphertext), iv: enc.IV(nonce));
  } catch (_) {
    throw const FormatException('Wrong password or corrupted backup file');
  }
}
```

**Step 6: Add `_argon2idKey` and keep `_pbkdf2V1`**

```dart
/// Argon2id key derivation for V2 backups.
static Uint8List _argon2idKey({
  required String password,
  required Uint8List salt,
}) {
  final hash = Argon2id(
    memory: 32768,
    iterations: 3,
    parallelism: 1,
    hashLength: _keyLen,
  ).convert(utf8.encode(password), salt: salt);
  return Uint8List.fromList(hash.bytes);
}

/// Legacy PBKDF2-SHA256 key derivation for V1 backup decryption only.
static Uint8List _pbkdf2V1({
  required String password,
  required Uint8List salt,
  required int iterations,
}) {
  // Original pure-Dart PBKDF2-HMAC-SHA256 implementation (unchanged from V1)
  final pw = utf8.encode(password);
  final hmac = HmacSha256.of(pw); // hashlib provides this
  const blockSize = 32;
  final blocks = (_keyLen / blockSize).ceil();
  final result = Uint8List(blocks * blockSize);
  for (var b = 1; b <= blocks; b++) {
    final sb = Uint8List(salt.length + 4)
      ..setRange(0, salt.length, salt)
      ..[salt.length] = (b >> 24) & 0xFF
      ..[salt.length + 1] = (b >> 16) & 0xFF
      ..[salt.length + 2] = (b >> 8) & 0xFF
      ..[salt.length + 3] = b & 0xFF;
    var u = Uint8List.fromList(hmac.convert(sb).bytes);
    final t = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (var j = 0; j < u.length; j++) {
        t[j] ^= u[j];
      }
    }
    result.setRange((b - 1) * blockSize, b * blockSize, t);
  }
  return result.sublist(0, _keyLen);
}
```

**Step 7: Add import for hashlib**

Add to the top of `backup_encryption_service.dart`:
```dart
import 'package:hashlib/hashlib.dart';
```
Remove `import 'package:crypto/crypto.dart';` (no longer needed).

**Step 8: Update `isEncryptedBackup`**

It checks `data.length < _magic.length` — still valid because V2 magic is same 5 bytes. No change needed.

**Step 9: Analyze**

```bash
flutter analyze lib/services/backup_encryption_service.dart
```
Expected: No issues found.

**Step 10: Commit**

```bash
git add lib/services/backup_encryption_service.dart
git commit -m "feat: upgrade backup encryption to Argon2id V2 format, keep V1 read support"
```

---

## Task 6: Encrypt the settings Hive box

**Files:**
- Modify: `lib/services/storage_service.dart`

### What changes
- Open `_settingsBox` with `HiveAesCipher`, same pattern as `_accountsBox`.
- New secure storage key: `'settings_encryption_key'`.
- Migration: if open-with-cipher throws (existing unencrypted box), delete the box file and reopen encrypted.

**Step 1: Add a helper `_getOrCreateKey`**

Currently `_getEncryptionKey()` creates/retrieves the accounts key. Generalize it:
```dart
Future<String> _getOrCreateKey(String keyName) async {
  var key = await _secureStorage.read(key: keyName);
  if (key == null) {
    final newKey = Hive.generateSecureKey();
    key = base64Url.encode(newKey);
    await _secureStorage.write(key: keyName, value: key);
  }
  return key;
}
```
Replace the `_getEncryptionKey()` call in `init()` with `_getOrCreateKey(_encryptionKeyName)`.

**Step 2: Add the settings key constant**

```dart
static const String _settingsEncryptionKeyName = 'settings_encryption_key';
```

**Step 3: Update `init()` to encrypt settings box**

Replace:
```dart
_settingsBoxInstance = await Hive.openBox<AppSettings>(_settingsBox);
```
With:
```dart
final settingsKey = await _getOrCreateKey(_settingsEncryptionKeyName);
final settingsKeyBytes = base64Url.decode(settingsKey);

try {
  _settingsBoxInstance = await Hive.openBox<AppSettings>(
    _settingsBox,
    encryptionCipher: HiveAesCipher(settingsKeyBytes),
  );
} catch (_) {
  // Box existed unencrypted — delete and recreate encrypted.
  // Settings are recoverable: password hash/salt will be re-set on next login.
  await Hive.deleteBoxFromDisk(_settingsBox);
  _settingsBoxInstance = await Hive.openBox<AppSettings>(
    _settingsBox,
    encryptionCipher: HiveAesCipher(settingsKeyBytes),
  );
}

if (_settingsBoxInstance!.isEmpty) {
  await _settingsBoxInstance!.put('settings', AppSettings());
}
```

**Step 4: Analyze**

```bash
flutter analyze lib/services/storage_service.dart
```
Expected: No issues found.

**Step 5: Commit**

```bash
git add lib/services/storage_service.dart
git commit -m "feat: encrypt settings Hive box with AES-256 key in OS keychain"
```

---

## Task 7: Fix TextEditingController disposal bugs in backup dialogs

**Files:**
- Modify: `lib/screens/settings_screen.dart`

### What changes
`_showSetPasswordDialog` and `_showDecryptPasswordDialog` both create local `TextEditingController`s and dispose them immediately after `showDialog` returns — same race condition we fixed for `_changePassword` in a previous session.

Extract each into a `StatefulWidget`. Same pattern as `_ChangePasswordDialog`.

**Step 1: Extract `_showSetPasswordDialog` into `_SetBackupPasswordDialog`**

At the bottom of `settings_screen.dart` (after `_ChangePasswordDialog`), add:

```dart
// ── Set backup password dialog ──────────────────────────────────────────────

class _SetBackupPasswordDialog extends StatefulWidget {
  const _SetBackupPasswordDialog();

  @override
  State<_SetBackupPasswordDialog> createState() =>
      _SetBackupPasswordDialogState();
}

class _SetBackupPasswordDialogState extends State<_SetBackupPasswordDialog> {
  late final TextEditingController _pwCtrl;
  late final TextEditingController _confirmCtrl;
  bool _pwVisible = false;
  bool _confirmVisible = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pwCtrl = TextEditingController();
    _confirmCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _pwCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.setBackupPassword),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _pwCtrl,
              obscureText: !_pwVisible,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.backupPassword,
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_pwVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _pwVisible = !_pwVisible),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              obscureText: !_confirmVisible,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.confirmBackupPassword,
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_confirmVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _confirmVisible = !_confirmVisible),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _PasswordStrengthBar(password: _pwCtrl.text),
            // (keep warning container from original — copy from old code)
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(
                      color: AppColors.error, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final pw = _pwCtrl.text;
            final confirm = _confirmCtrl.text;
            if (pw.length < AppConstants.minPasswordLength) {
              setState(() => _error =
                  AppLocalizations.of(context)!
                      .passwordMinLength(AppConstants.minPasswordLength));
              return;
            }
            if (pw != confirm) {
              setState(() => _error =
                  AppLocalizations.of(context)!.passwordsDoNotMatch);
              return;
            }
            Navigator.pop(context, pw);
          },
          child: Text(l10n.exportAccounts),
        ),
      ],
    );
  }
}
```

Note: Copy the warning container (the yellow "you won't be able to recover" box) from the original `_showSetPasswordDialog` into the `build` method.

**Step 2: Replace `_showSetPasswordDialog` call site**

Find where `_showSetPasswordDialog` is called (around line 615):
```dart
final password = await _showSetPasswordDialog(l10n);
```
Replace with:
```dart
final password = await showDialog<String>(
  context: context,
  barrierDismissible: false,
  builder: (_) => const _SetBackupPasswordDialog(),
);
```
Delete the `_showSetPasswordDialog` method entirely.

**Step 3: Extract `_showDecryptPasswordDialog` into `_DecryptBackupDialog`**

```dart
// ── Decrypt backup dialog ───────────────────────────────────────────────────

class _DecryptBackupDialog extends StatefulWidget {
  const _DecryptBackupDialog();

  @override
  State<_DecryptBackupDialog> createState() => _DecryptBackupDialogState();
}

class _DecryptBackupDialogState extends State<_DecryptBackupDialog> {
  late final TextEditingController _ctrl;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.decryptBackup),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.enterBackupPassword,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(153),
                  )),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            obscureText: !_visible,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.backupPassword,
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_visible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(() => _visible = !_visible),
              ),
            ),
            onSubmitted: (v) {
              if (v.isNotEmpty) Navigator.pop(context, v);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_ctrl.text.isNotEmpty) Navigator.pop(context, _ctrl.text);
          },
          child: Text(l10n.decryptBackup),
        ),
      ],
    );
  }
}
```

**Step 4: Replace `_showDecryptPasswordDialog` call site**

Find (around line 739):
```dart
final password = await _showDecryptPasswordDialog(l10n);
```
Replace with:
```dart
final password = await showDialog<String>(
  context: context,
  barrierDismissible: false,
  builder: (_) => const _DecryptBackupDialog(),
);
```
Delete the `_showDecryptPasswordDialog` method entirely.

**Step 5: Analyze**

```bash
flutter analyze lib/screens/settings_screen.dart
```
Expected: No issues found.

**Step 6: Commit**

```bash
git add lib/screens/settings_screen.dart
git commit -m "fix: extract backup password dialogs to StatefulWidgets to fix controller disposal race"
```

---

## Task 8: Increase minimum password length

**Files:**
- Modify: `lib/utils/constants.dart`

**Step 1: Update constant**

Change:
```dart
static const int minPasswordLength = 6;
```
To:
```dart
static const int minPasswordLength = 8;
```

**Step 2: Analyze**

```bash
flutter analyze lib/utils/constants.dart
```
Expected: No issues found.

**Step 3: Commit**

```bash
git add lib/utils/constants.dart
git commit -m "chore: raise minimum password length from 6 to 8 characters"
```

---

## Task 9: Android screen capture protection — toggleable from Settings

FLAG_SECURE is controllable via a MethodChannel so the Flutter side can turn it on/off at runtime. Default: on.

**Files:**
- Modify: `android/app/src/main/kotlin/com/kaandikec/secure_auth/MainActivity.kt`
- Create: `lib/services/screen_protection_service.dart`
- Modify: `lib/main.dart` (apply on startup)
- Modify: `lib/screens/settings_screen.dart` (add toggle)

### Step 1: Update `MainActivity.kt`

Full replacement (package name is already correct):
```kotlin
package com.kaandikec.secure_auth

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "com.kaandikec.secureauth/window"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        val secure = call.argument<Boolean>("secure") ?: true
                        if (secure) {
                            window.setFlags(
                                WindowManager.LayoutParams.FLAG_SECURE,
                                WindowManager.LayoutParams.FLAG_SECURE,
                            )
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Default to secure; Flutter will call setSecure(false) if user disabled it.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
    }
}
```

### Step 2: Create `lib/services/screen_protection_service.dart`

```dart
import 'dart:io';
import 'package:flutter/services.dart';

class ScreenProtectionService {
  static const _channel =
      MethodChannel('com.kaandikec.secureauth/window');

  /// Sets or clears Android FLAG_SECURE. No-op on non-Android platforms.
  static Future<void> setSecure(bool secure) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setSecure', {'secure': secure});
  }
}
```

### Step 3: Apply on startup in `main.dart`

After `storageService.init()` and before `runApp(...)`, add:
```dart
final settings = storageService.getSettings();
await ScreenProtectionService.setSecure(settings.screenProtection);
```
Also add the import:
```dart
import 'services/screen_protection_service.dart';
```

### Step 4: Add toggle to Settings screen

In `settings_screen.dart`:

1. Add `_screenProtection` state variable (load from settings in `initState`, same pattern as other booleans).

2. Add a handler method:
```dart
Future<void> _setScreenProtection(bool value) async {
  await _updateSetting((s) => s.screenProtection = value);
  setState(() => _screenProtection = value);
  await ScreenProtectionService.setSecure(value);
}
```

3. In the Security section of the settings list, add a `SwitchListTile` for screen protection after the existing biometric/password tiles:
```dart
SwitchListTile(
  value: _screenProtection,
  onChanged: _setScreenProtection,
  title: Text(l10n.screenProtection),        // add to all l10n files
  subtitle: Text(l10n.screenProtectionDesc), // add to all l10n files
  secondary: const Icon(Icons.screenshot_monitor_outlined),
),
```

4. Add localisation strings to all ARB/l10n files:
   - `screenProtection`: "Screen Protection" / "Ekran Koruması" / etc.
   - `screenProtectionDesc`: "Prevent screenshots and hide app from recents" / etc.

### Step 5: Analyze

```bash
flutter analyze lib/services/screen_protection_service.dart lib/main.dart lib/screens/settings_screen.dart
```
Expected: No issues found.

### Step 6: Commit

```bash
git add android/app/src/main/kotlin/ lib/services/screen_protection_service.dart lib/main.dart lib/screens/settings_screen.dart lib/l10n/
git commit -m "feat: toggleable Android screen capture protection via Settings"
```

---

## Task 10: Run full analysis and final checks

**Step 1: Full project analyze**

```bash
flutter analyze
```
Expected: No issues found (or only pre-existing infos unrelated to our changes).

**Step 2: Verify build on release mode**

```bash
flutter build apk --release 2>&1 | tail -10
```
Expected: Build succeeds.

**Step 3: Commit if any lint fixes were needed**

```bash
git add -p
git commit -m "fix: lint cleanup after security hardening"
```

---

## Task 11: Rewrite README.md

**Files:**
- Modify: `README.md`

Write a new `README.md` from scratch that documents:
1. What the app is
2. Key security features (lead with the Argon2id/AES-256-GCM stack)
3. Supported platforms
4. How to build / run
5. Backup file format (V1 legacy + V2 Argon2id)
6. Privacy policy summary (offline-only, no telemetry)

See the final task below for the actual content.

**Step 1: Overwrite README.md with new content**

(Full content produced in the implementation step — do not write it here to keep the plan DRY.)

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: rewrite README to reflect Argon2id security stack"
```

---

## Commit summary (in order)

| # | Commit message |
|---|----------------|
| 1 | `chore: add hashlib for Argon2id support` |
| 2 | `feat: add hashVersion field to AppSettings for KDF migration` |
| 3 | `feat: replace PBKDF2 with Argon2id in SecurityService` |
| 4 | `feat: transparent PBKDF2→Argon2id migration on successful login` |
| 5 | `feat: upgrade backup encryption to Argon2id V2 format, keep V1 read support` |
| 6 | `feat: encrypt settings Hive box with AES-256 key in OS keychain` |
| 7 | `fix: extract backup password dialogs to StatefulWidgets to fix controller disposal race` |
| 8 | `chore: raise minimum password length from 6 to 8 characters` |
| 9 | `feat: add FLAG_SECURE to prevent screen capture on Android` |
| 10 | `fix: lint cleanup after security hardening` |
| 11 | `docs: rewrite README to reflect Argon2id security stack` |
