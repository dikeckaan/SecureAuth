<div align="center">

# SecureAuth

**A production-grade, fully offline 2FA authenticator built with Flutter**

[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-lightgrey)](#platform-support)
[![Languages](https://img.shields.io/badge/Languages-12-orange)](#localization)

*No cloud. No telemetry. No bullshit.*

</div>

---

## Table of Contents

1. [Overview](#overview)
2. [Features at a Glance](#features-at-a-glance)
3. [Security Architecture](#security-architecture)
   - [Password Hashing](#password-hashing)
   - [Database Encryption](#database-encryption)
   - [Brute-Force Protection](#brute-force-protection)
   - [Backup Encryption](#backup-encryption)
   - [Clipboard Security](#clipboard-security)
   - [Screen Protection](#screen-protection)
   - [Auto-Lock & Inactivity](#auto-lock--inactivity)
   - [Clock Tamper Detection](#clock-tamper-detection)
   - [Security Audit Logging](#security-audit-logging)
4. [Token Types](#token-types)
   - [TOTP](#totp-time-based-one-time-password)
   - [HOTP](#hotp-counter-based-one-time-password)
   - [Steam Guard](#steam-guard)
5. [Backup System](#backup-system)
   - [Encrypted Backup (.saenc)](#encrypted-backup-saenc)
   - [Plain JSON Backup](#plain-json-backup)
   - [Import](#import)
   - [File Format Specification](#file-format-specification)
6. [Screens & UX](#screens--ux)
7. [Platform Support](#platform-support)
8. [Localization](#localization)
9. [Tech Stack](#tech-stack)
10. [Project Structure](#project-structure)
11. [Data Models](#data-models)
12. [Security Parameters Reference](#security-parameters-reference)
13. [Building from Source](#building-from-source)
14. [Contributing](#contributing)

---

## Overview

SecureAuth is a **privacy-first, fully offline** two-factor authentication (2FA) app. Every secret, every account, every setting lives exclusively on your device — nothing is ever transmitted over the network. There are no accounts, no sync servers, no analytics SDKs, and no ads.

Built with Flutter for cross-platform reach, SecureAuth uses **AES-256-encrypted Hive** for local storage, **Argon2id** for password hashing (the winner of the Password Hashing Competition, resistant to both GPU and side-channel attacks), and **AES-256-GCM** for backup encryption — the same cryptographic primitives used by password managers and secure messengers.

---

## Features at a Glance

| Category | Feature |
|---|---|
| **Token Types** | TOTP (RFC 6238), HOTP (RFC 4226), Steam Guard |
| **Account Management** | Add via QR scan or manual entry, edit issuer/name, delete with confirmation |
| **Algorithms** | SHA-1, SHA-256, SHA-512 |
| **Digits** | Configurable 4–8 (Steam Guard locked to 5) |
| **Period** | Configurable 15–60 s (Steam Guard locked to 30 s) |
| **HOTP Navigation** | ← / → counter buttons + tap-to-pick counter dialog |
| **Authentication** | Password (Argon2id) + optional biometric (Face ID / Touch ID / fingerprint) |
| **Auto-Lock** | Inactivity timer with configurable timeout |
| **Brute-Force** | Exponential-backoff lockout; optional full data-wipe on max attempts |
| **Clipboard** | Auto-clears after configurable delay (default 30 s) |
| **Screen Protection** | FLAG_SECURE blocks screenshots and hides app in task switcher (Android, toggleable) |
| **Backup** | AES-256-GCM + Argon2id encrypted `.saenc` **and** plain JSON export/import |
| **QR** | Scan `otpauth://` QR codes; display QR for any stored account |
| **Search** | Live filter by issuer or account name |
| **Audit Logging** | Structured security event log with in-memory ring buffer (500 entries), filterable viewer, export to text/JSON |
| **Clock Tamper Detection** | Detects system clock rollback; locks the app entirely until master password is entered |
| **Error Handling** | `Result<T>` sealed union for type-safe error propagation; `AppError` with categorized error types |
| **Dependency Injection** | `ServiceLocator` singleton with init-time wiring and test overrides |
| **CI/CD** | GitHub Actions: analyze, test, multi-platform build (Android, iOS, Windows, macOS, Linux) |
| **Pre-commit Hooks** | `dart format` + `dart analyze` enforced before every commit |
| **Themes** | Light, Dark, Pure Dark (AMOLED), follow-system or manual, custom accent colors |
| **Languages** | 12 languages, runtime switch, no restart needed |
| **Platforms** | iOS, Android, macOS, Windows, Linux |
| **Internet Access** | None — ever |
| **Analytics** | None |

---

## Security Architecture

### Password Hashing

User passwords are **never stored**. Instead, SecureAuth derives a hash using **Argon2id** — the algorithm recommended by OWASP, NIST, and the Password Hashing Competition for its memory-hardness, which makes GPU and ASIC-based brute-force attacks orders of magnitude more expensive than PBKDF2:

| Parameter | Value |
|---|---|
| Algorithm | Argon2id (RFC 9106) |
| Memory | **32 768 KB** (32 MB) per hash |
| Iterations (time cost) | **3** |
| Parallelism | **1** |
| Output length | **32 bytes** |
| Salt | **32 bytes**, cryptographically random, unique per password |
| Comparison | **Constant-time** — prevents timing side-channels |
| Storage | Hash + salt + version tag stored in the encrypted Hive `settings` box |

Computation runs in a background **Dart `Isolate`** so the UI thread is never blocked.

**Transparent migration:** Users who created their password before v2.0 continue to log in with their existing PBKDF2-HMAC-SHA512 hash. On first successful login, the hash is automatically re-derived using Argon2id and the old PBKDF2 record is replaced — no user action required.

The salt is generated fresh every time a password is set or changed, so rainbow tables are useless and identical passwords produce different hashes.

### Database Encryption

All data is stored across two **Hive boxes, both encrypted with AES-256**:

```
FlutterSecureStorage
    ├── 'encryption_key'      ←  256-bit key for the accounts box
    └── 'settings_enc_key'    ←  256-bit key for the settings box
            │
            ▼
    Hive.openBox('accounts',  encryptionCipher: HiveAesCipher(accountsKey))
    Hive.openBox('settings',  encryptionCipher: HiveAesCipher(settingsKey))
```

- Each 256-bit key is generated **once** on first launch using `Hive.generateSecureKey()` and immediately written to the platform's hardware-backed secure store (iOS Keychain / Android Keystore / macOS Keychain).
- Keys are never exposed in logs, files, or crash reports.
- The `settings` box encryption protects the Argon2id hash, salt, and all user preferences from offline file access.

### Brute-Force Protection

Failed password attempts trigger an **exponential-backoff lockout** stored in `FlutterSecureStorage`:

| Consecutive Failures | Lockout Duration |
|---|---|
| < 3 | None |
| 3 | 30 seconds |
| 4 | 1 minute |
| 5 | 2 minutes |
| 6 | 4 minutes |
| 7 | 8 minutes |
| n ≥ 3 | `30 × 2^(n−3)` seconds |

The lockout timestamp is checked on every login attempt. Expired lockouts are cleaned up automatically.

Additionally, users can enable **Wipe on Max Attempts**: if the configurable limit (default 10, range 3–20) is reached, all accounts and settings are destroyed with no recovery path. A prominent warning dialog must be acknowledged before enabling this feature.

### Backup Encryption

The `.saenc` format uses a **two-layer cryptographic design**:

**Layer 1 — Key Derivation (Argon2id)**

| Parameter | Value |
|---|---|
| Algorithm | Argon2id (RFC 9106) |
| Memory | **32 768 KB** |
| Iterations | **3** |
| Parallelism | **1** |
| Salt | **32 bytes**, cryptographically random, unique per export |
| Output | **32-byte AES-256 key** |

Computation runs in a dedicated **Dart `Isolate`** so the UI thread is never blocked during the expensive KDF phase.

**Layer 2 — Authenticated Encryption (AES-256-GCM)**

| Parameter | Value |
|---|---|
| Cipher | AES-256-GCM |
| Key | 32-byte key derived by Argon2id above |
| Nonce | **12 bytes**, cryptographically random, unique per export |
| Authentication tag | **16 bytes** (GCM) |

GCM provides **confidentiality and authenticity** in a single pass. A wrong password doesn't produce garbled output — it fails with an authentication error before a single byte of plaintext is returned. This is indistinguishable from a corrupted file to an attacker.

**Backward compatibility:** V1 backups (created before v2.0, using PBKDF2-HMAC-SHA256 key derivation) can still be decrypted and imported. The format version byte at offset 5 is used to select the correct decryption path.

### Clipboard Security

When an OTP code is copied:

1. The code is placed in the system clipboard via `Clipboard.setData`.
2. A `Future.delayed` is scheduled for the configured interval (default 30 s, user-configurable from 10 s to 2 min).
3. After the delay — or when the current TOTP period expires (whichever comes first) — `Clipboard.setData(ClipboardData(text: ''))` clears the clipboard.

The user sees a snackbar: *"Code copied (30s auto-clear)"* as a reminder.

### Screen Protection

On Android, SecureAuth sets the `FLAG_SECURE` window flag by default. This:

- Prevents the system from taking screenshots of the app.
- Hides the app content in the Recent Apps / task switcher (shows a blank/blurred preview instead).

The flag is applied in `MainActivity.onCreate` before Flutter renders anything, so it is always in effect at launch. Users can opt out via **Settings → Screen Protection** toggle; the change takes effect immediately via a `MethodChannel` call.

This setting has no effect on iOS, macOS, Windows, or Linux (where the OS provides equivalent or superior protections by default).

### Auto-Lock & Inactivity

A background timer fires every **15 seconds** and compares `DateTime.now()` against the last recorded activity timestamp stored in `FlutterSecureStorage`:

```
elapsed > autoLockSeconds  →  setState(_isLocked = true)  →  AuthScreen
```

Activity is recorded on every `HomeScreen` resume from background and on app lifecycle `paused` / `inactive` events.

The timeout is user-configurable (30 s / 1 min / 2 min / 5 min / 10 min / disabled).

### Clock Tamper Detection

SecureAuth detects system clock manipulation — a potential attack vector where someone rolls back the device clock to replay expired TOTP codes or confuse time-based security logs.

**How it works:**

1. **First launch:** Records `first_launch_timestamp` and `last_known_timestamp` in `FlutterSecureStorage`.
2. **Every app start and resume:** Compares current time against both timestamps.
3. **Every 15 seconds while running:** Updates `last_known_timestamp` via the inactivity timer.
4. **Detection logic:** If current time is more than **60 seconds** before either stored timestamp, tampering is flagged.

The 60-second tolerance accounts for NTP sync drift and DST transitions.

**When tampering is detected:**

- The app enters **full lockdown** — not even the login screen is shown.
- A dedicated `TamperLockdownScreen` displays a warning explaining what happened.
- **Only master password authentication can clear the flag.** Biometric unlock is explicitly disabled during lockdown.
- The tamper flag persists in `FlutterSecureStorage` and survives app restarts.

Users can disable tamper detection from Settings → Audit & Logs → Clock Tamper Detection.

### Security Audit Logging

SecureAuth maintains a structured security event log for transparency and forensics:

| Property | Value |
|---|---|
| **Storage** | In-memory ring buffer (500 entries max) |
| **Log levels** | debug, info, warning, error, security |
| **Categories** | auth, backup, storage, tamper, app |
| **Per entry** | Timestamp, level, category, message, metadata map |
| **Persistence** | Session-only (cleared on app restart for privacy) |
| **Toggle** | Enable/disable from Settings → Audit & Logs |
| **Export** | Text or JSON via native share sheet |
| **Viewer** | Full-featured log viewer with 7 filter chips (All, Security, Errors, Auth, Backup, Storage, Tamper) |

Events logged include: failed login attempts, lockout triggers, password changes, biometric toggles, backup encrypt/decrypt, account import/export, data wipes, tamper detection alerts, and service initialization.

---

## Token Types

### TOTP (Time-based One-Time Password)

Implements **RFC 6238** using the `otp` package.

```
TOTP(K, T) = HOTP(K, ⌊(T_current − T0) / X⌋)
```

| Setting | Default | Range |
|---|---|---|
| Algorithm | SHA-1 | SHA-1, SHA-256, SHA-512 |
| Digits | 6 | 4–8 |
| Period | 30 s | 15–60 s |

The `AccountCard` widget renders a circular countdown ring that transitions from primary → warning (≤ 10 s) → error (≤ 5 s) color, and the code turns red when expiry is imminent.

### HOTP (Counter-based One-Time Password)

Implements **RFC 4226** using the `otp` package.

```
HOTP(K, C) = Truncate(HMAC-SHA1(K, C))
```

| Setting | Default | Notes |
|---|---|---|
| Algorithm | SHA-1 | SHA-1, SHA-256, SHA-512 |
| Digits | 6 | 4–8 |
| Counter | 0 | Persisted to Hive on every change |

The counter is stored as a `HiveField` on `AccountModel` and persisted immediately after each navigation. The `AccountCard` widget includes **← / →** buttons and a tap-to-pick dialog for jumping to any counter value.

**Implementation detail:** Hive objects are mutable references, so changing `account.counter` mutates the object in place. `AccountCard` widgets use `ValueKey('${account.id}_${account.counter}')` to force a full widget rebuild (and a fresh `initState()` / code generation) whenever the counter changes.

### Steam Guard

A custom implementation of Valve's proprietary TOTP variant:

| Setting | Value |
|---|---|
| Algorithm | SHA-1 |
| Digits | 5 (enforced) |
| Period | 30 s (enforced) |
| Alphabet | `23456789BCDFGHJKMNPQRTVWXY` (26 chars, no ambiguous characters) |

Generation flow:
1. Decode Base32 secret → raw key bytes
2. Compute `counter = Unix timestamp ÷ 30` as 8-byte big-endian
3. `hmac = HMAC-SHA1(key, counter)`
4. Dynamic offset: `offset = hmac[19] & 0x0F`
5. Extract 4 bytes at offset, mask with `0x7FFFFFFF`
6. `for i in range(5): code[i] = STEAM_ALPHABET[value % 26]; value ÷= 26`

The 26-character alphabet deliberately omits characters that look similar (`0`, `1`, `I`, `O`, `L`, `A`, `U`, `S`, `E`) to minimise transcription errors.

---

## Backup System

### Encrypted Backup (.saenc)

The recommended export format. The resulting `.saenc` file can be safely stored anywhere — cloud drives, email, messaging apps — because it is cryptographically locked to a password you choose.

**Export flow:**

```
Tap "Export Accounts"
  └─► Bottom sheet: "Encrypted (Recommended)" | "Unencrypted"
        └─► [Encrypted] Password dialog
              ├── Password field (visibility toggle)
              ├── Confirm field
              ├── Real-time strength bar
              │     Weak / Medium / Good / Strong / Very Strong
              └── Warning: "Store this password safely"
                    └─► [Export]
                          ├── Loading dialog shown ("Encrypting backup...")
                          ├── Argon2id key derivation runs in background Isolate
                          ├── AES-256-GCM encrypts JSON payload
                          └── .saenc file shared via native share sheet
```

**Password strength scoring:**

| Condition | Score |
|---|---|
| Length ≥ 8 | +1 |
| Length ≥ 12 | +2 (total) |
| Length ≥ 16 | +3 (total) |
| Contains uppercase | +1 |
| Contains lowercase | +1 |
| Contains digit | +1 |
| Contains special character | +2 |

Score 0–2 → Weak · 3–4 → Medium · 5–6 → Good · 7 → Strong · 8–9 → Very Strong

### Plain JSON Backup

An unencrypted JSON file for use in trusted environments (local machine, encrypted volume, etc.).

```json
{
  "version": "2.0",
  "app": "SecureAuth",
  "exported_at": "2025-01-01T12:00:00.000Z",
  "count": 5,
  "accounts": [
    {
      "id": "1704067200000",
      "name": "user@example.com",
      "issuer": "GitHub",
      "secret": "JBSWY3DPEHPK3PXP",
      "digits": 6,
      "period": 30,
      "algorithm": "SHA1",
      "type": "totp",
      "counter": 0,
      "created_at": "2025-01-01T10:00:00.000Z"
    }
  ]
}
```

> **Warning:** This file contains your raw TOTP secrets in plaintext. Treat it with the same care as a private key.

### Import

SecureAuth auto-detects the file format using magic bytes — no file extension required.

```
Pick file (FileType.any — works for both .json and .saenc)
    │
    ├── First 5 bytes == "SAENC"?
    │     ├── YES → Encrypted backup
    │     │           ├── Read version byte
    │     │           ├── V2 (0x02) → Argon2id key derivation → AES-256-GCM decrypt
    │     │           └── V1 (0x01) → PBKDF2-SHA256 key derivation → AES-256-GCM decrypt
    │     │                All run in background Isolate → JSON parse
    │     └── NO  → Plain JSON
    │                 └─► UTF-8 decode → JSON parse
    │
    └── For each account: skip if ID already exists (no duplicates)
        └─► Show: "N accounts imported"
```

**Cloud file support:** `withData: true` is set on the `FilePicker` call, ensuring that files in iCloud Drive, Google Drive, and similar cloud providers are fully downloaded before processing — not just linked by path.

**iOS note:** `FileType.any` is used instead of `FileType.custom` because `.saenc` is not a registered UTI on iOS. Custom-extension filtering would make `.saenc` files invisible in the system picker. Format detection happens client-side via magic bytes after the file is loaded.

### File Format Specification

**V2 (current, Argon2id):**

```
SecureAuth Encrypted Backup (.saenc) V2 — Binary, All Fields Big-Endian
────────────────────────────────────────────────────────────────────────

Offset   Length   Field         Description
──────   ──────   ─────         ───────────
  0        5      Magic         ASCII "SAENC"  (53 41 45 4E 43)
  5        1      Version       0x02
  6       32      Salt          Cryptographically random bytes (Argon2id salt)
 38       12      Nonce         Cryptographically random bytes (AES-GCM nonce)
 50        n      Ciphertext    AES-256-GCM ciphertext
 50+n     16      GCM Auth Tag  Authentication tag (appended by GCM)

Minimum valid file size: 50 (header) + 16 (tag) = 66 bytes
KDF: Argon2id  m=32768 KB, t=3, p=1
```

**V1 (legacy, PBKDF2 — readable for backward compatibility):**

```
SecureAuth Encrypted Backup (.saenc) V1 — Binary, All Fields Big-Endian
────────────────────────────────────────────────────────────────────────

Offset   Length   Field             Description
──────   ──────   ─────             ───────────
  0        5      Magic             ASCII "SAENC"  (53 41 45 4E 43)
  5        1      Version           0x01
  6        4      KDF Iterations    uint32 (200000 = 00 03 0D 40)
 10       16      Salt              Cryptographically random bytes
 26       16      AES-GCM Nonce     Cryptographically random bytes
 42        n      Ciphertext        AES-256-GCM ciphertext
 42+n     16      GCM Auth Tag      Authentication tag (appended by GCM)

Minimum valid file size: 42 (header) + 16 (tag) = 58 bytes
KDF: PBKDF2-HMAC-SHA256  iterations=200000
```

**Integrity guarantees (both versions):**
- Any modification to the ciphertext or header causes a GCM tag mismatch before any data is returned
- The format is versioned to support future algorithm upgrades without breaking existing files

---

## Screens & UX

### SetupScreen
First-launch screen for configuring security. Requires setting a password (minimum 8 characters) with a visual strength indicator. Optional biometric enrollment. Password and confirm fields must match before setup completes.

### AuthScreen
The authentication gate rendered before `HomeScreen` when `requireAuthOnLaunch` is enabled. Supports:
- **Biometric-first**: Face ID / Touch ID prompt fires automatically on load
- **Password fallback**: Input with shake animation on failure
- **Lockout display**: Countdown timer updated every second during exponential-backoff lockout
- **Attempt counter**: "Wrong password (N attempt(s) left)"

### HomeScreen
The main interface. Shows all stored 2FA accounts as live-updating cards. Features:
- **Live codes**: Each card generates and displays the current OTP, auto-refreshing every second for TOTP/Steam
- **Search bar**: Filters by issuer or account name as you type
- **Account count badge**: Shows total count in the app bar
- **FAB**: Opens `AddAccountScreen`

### AccountCard
Each account renders as a card with:
- **Left accent strip**: Service-specific color gradient
- **Avatar**: Gradient circle with account initials
- **Type badge**: "HOTP" or "Steam" label (TOTP is default, no badge)
- **OTP code**: Large monospace font, split `123 456` style
- **Copy icon**: Animated checkmark on tap
- **Timer (TOTP/Steam)**: Circular progress ring with countdown number
- **Counter controls (HOTP)**: `[←] [3] [→]` — tap the counter to open a number-picker dialog
- **Bottom progress bar (TOTP/Steam)**: Linear indicator colour-synced with the ring
- **3-dot menu**: Edit / Show QR / Delete

### AddAccountScreen
Tabbed interface with three tabs: **TOTP**, **HOTP**, **Steam Guard**. Each tab:
- Scan QR button (opens camera)
- Manual entry: Issuer, Account Name, Secret (Base32, with visibility toggle)
- Advanced settings (collapsible): Algorithm, Digits, Period / Initial Counter
- Info banner for HOTP and Steam explaining behaviour
- Input validation with inline error messages

### SettingsScreen
Card-based settings grouped into sections:

| Section | Settings |
|---|---|
| **Language** | 12-language picker (bottom sheet) |
| **Appearance** | Dark mode toggle |
| **Security** | App lock toggle, Biometric toggle, Screen Protection toggle, Change/Set password |
| **Advanced Security** | Auto-lock timeout, Clipboard clear duration, Max failed attempts, Wipe on max attempts |
| **Audit & Logs** | Security logging toggle, Clock tamper detection toggle, View Security Logs (opens LogViewerScreen) |
| **Backup** | Export Accounts (encrypted or plain), Import Accounts |
| **Experimental** | Steam Guard toggle |
| **Danger Zone** | Delete All Data — wipes everything and navigates to SetupScreen |

### LogViewerScreen
Security audit log viewer accessible from Settings → Audit & Logs → View Security Logs. Features:
- **Filter chips**: All, Security, Errors, Auth, Backup, Storage, Tamper — tap to filter
- **Log cards**: Color-coded left edge by severity (green=info, amber=warning, red=error, purple=security)
- **Metadata display**: Expandable JSON metadata per entry
- **Export**: Share as text file via native share sheet
- **Clear**: Confirmation dialog before erasing all logs

### TamperLockdownScreen
Full-screen security lockdown displayed when clock manipulation is detected. This screen completely blocks the app — the normal login screen is not shown. Features:
- **Pulsing warning icon** with red gradient background
- **Explanation text** describing what clock tampering means
- **Password-only unlock** — biometric authentication explicitly disabled
- **Master password verification** to clear the tamper flag and restore normal access

### QRDisplayScreen
Displays a scannable `otpauth://` QR code for any stored account. Useful for migrating to another device or authenticator app. Uses error correction level H (30% data recovery).

---

## Platform Support

| Platform | Status | Notes |
|---|---|---|
| iOS | ✅ Supported | iOS 15.0+ |
| Android | ✅ Supported | Full support; FLAG_SECURE screen protection |
| macOS | ✅ Supported | Desktop layout |
| Windows | ✅ Supported | Desktop layout; Windows Hello biometric |
| Linux | ✅ Supported | Desktop layout |

SecureAuth requests **zero internet permissions** on all platforms. Biometric availability is platform-specific; the UI gracefully hides biometric options when the hardware is unavailable or has not been configured.

---

## Localization

12 languages with runtime switching (no app restart required):

| Language | Code | Native Name |
|---|---|---|
| English | `en` | English |
| Turkish | `tr` | Türkçe |
| Spanish | `es` | Español |
| German | `de` | Deutsch |
| French | `fr` | Français |
| Portuguese | `pt` | Português |
| Russian | `ru` | Русский |
| Azerbaijani | `az` | Azerbaycanca |
| Arabic | `ar` | العربية |
| Japanese | `ja` | 日本語 |
| Korean | `ko` | 한국어 |
| Chinese | `zh` | 中文 |

Implemented with Flutter's `gen-l10n` toolchain. ARB source files live in `lib/l10n/`. The English ARB (`app_en.arb`) is the canonical template. Fallback locale is English.

---

## Tech Stack

### Core

| Package | Version | Purpose |
|---|---|---|
| `flutter` | SDK 3.10+ | UI framework |
| `flutter_localizations` | SDK | i18n delegates |

### Storage & Security

| Package | Version | Purpose |
|---|---|---|
| `hive` | ^2.2.3 | Encrypted local NoSQL database |
| `hive_flutter` | ^1.1.0 | Hive Flutter integration |
| `flutter_secure_storage` | ^9.2.2 | Platform-native secure key storage |
| `hashlib` | ^1.20.0 | Argon2id, PBKDF2, HMAC — pure Dart, all platforms |
| `encrypt` | ^5.0.3 | AES-256-GCM for backup files |
| `local_auth` | ^2.3.0 | Biometric authentication |

### Token Generation

| Package | Version | Purpose |
|---|---|---|
| `otp` | ^3.1.4 | RFC 6238 TOTP / RFC 4226 HOTP |
| `base32` | ^2.1.3 | Base32 decode of OTP secrets |

### QR Codes

| Package | Version | Purpose |
|---|---|---|
| `qr_flutter` | ^4.1.0 | QR code widget (display) |
| `mobile_scanner` | ^5.2.3 | Camera-based QR scanning |
| `flutter_zxing` | — | Desktop QR scanning from image files |

### File & Share

| Package | Version | Purpose |
|---|---|---|
| `path_provider` | ^2.1.4 | App directory resolution |
| `file_picker` | ^8.1.4 | File picker (import) |
| `share_plus` | ^10.1.2 | Native OS share sheet (export) |
| `permission_handler` | ^11.3.1 | Camera permission |

### Utilities

| Package | Version | Purpose |
|---|---|---|
| `uuid` | ^4.5.1 | Unique account IDs |
| `intl` | ^0.20.1 | i18n number/date formatting |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |

### Dev

| Package | Version | Purpose |
|---|---|---|
| `hive_generator` | ^2.0.1 | Hive TypeAdapter code generation |
| `build_runner` | ^2.4.13 | Code generation runner |
| `flutter_lints` | ^6.0.0 | Lint rules |

---

## Project Structure

```
lib/
├── main.dart                          # App entry point, ServiceLocator init, routing, lifecycle
│
├── models/
│   ├── account_model.dart             # 2FA account entity (Hive TypeId 0)
│   ├── account_model.g.dart           # Generated Hive adapter
│   ├── app_settings.dart              # App configuration entity (Hive TypeId 1, 21 fields)
│   └── app_settings.g.dart            # Generated Hive adapter
│
├── services/
│   ├── service_locator.dart           # Singleton DI container, init-time wiring, test overrides
│   ├── auth_service.dart              # Auth facade: password + biometric + activity + Result<T>
│   ├── security_service.dart          # Argon2id, brute-force, clipboard, lockout
│   ├── storage_service.dart           # Hive CRUD + export/import (both boxes AES-256) + Result<T>
│   ├── totp_service.dart              # TOTP / HOTP / Steam token generation
│   ├── qr_service.dart                # QR code generation (PNG + widget)
│   ├── backup_encryption_service.dart # AES-256-GCM backup encrypt/decrypt (V1+V2) + Result<T>
│   ├── logger_service.dart            # Structured audit logger (ring buffer, export, filtering)
│   ├── tamper_detection_service.dart   # Clock rollback detection via FlutterSecureStorage
│   └── screen_protection_service.dart # Android FLAG_SECURE via MethodChannel
│
├── screens/
│   ├── setup_screen.dart              # First-launch password setup
│   ├── auth_screen.dart               # Login gate (password + biometric)
│   ├── home_screen.dart               # Account list with search
│   ├── add_account_screen.dart        # Add account (QR scan + manual, 3 types)
│   ├── settings_screen.dart           # Full settings + backup/restore + audit logs
│   ├── log_viewer_screen.dart         # Security audit log viewer with filters
│   ├── tamper_lockdown_screen.dart    # Clock tamper lockdown (password-only unlock)
│   ├── qr_scanner_screen.dart         # Camera QR scanner
│   └── qr_display_screen.dart         # Account QR display
│
├── widgets/
│   ├── account_card.dart              # Live OTP card (TOTP ring, HOTP controls)
│   └── color_picker_widget.dart       # Accent color picker
│
├── utils/
│   ├── constants.dart                 # Colors, spacing, radii, crypto params
│   ├── result.dart                    # Result<T> sealed union + AppError + ErrorCategory
│   └── theme.dart                     # Material 3 light/dark/AMOLED themes
│
└── l10n/
    ├── app_en.arb                     # English strings (source of truth)
    ├── app_tr.arb ... app_zh.arb      # 11 additional languages
    └── app_localizations*.dart        # Generated by flutter gen-l10n

test/
├── helpers/
│   └── fake_secure_storage.dart       # In-memory FlutterSecureStorage for testing
├── services/
│   ├── security_service_test.dart     # 70+ unit tests for crypto + brute-force
│   ├── totp_service_test.dart         # OTP generation + URI parsing tests
│   ├── backup_encryption_service_test.dart  # Encrypt/decrypt round-trip tests
│   ├── logger_service_test.dart       # Ring buffer, filtering, export tests
│   └── tamper_detection_service_test.dart   # Clock rollback detection tests
├── models/
│   └── account_model_test.dart        # JSON serialization + otpAuthUri tests
├── utils/
│   └── result_test.dart               # Result<T> pattern matching + map/flatMap tests
└── integration/
    ├── auth_flow_test.dart            # Full auth flow: setup → login → lockout → reset
    └── backup_roundtrip_test.dart     # Backup encrypt → decrypt → import round-trip

scripts/
└── setup-hooks.sh                     # Installs pre-commit hook (format + analyze)

.github/workflows/
├── ci.yml                             # Full CI: analyze, test, build (6 platforms)
└── release.yml                        # Release workflow: version tags → GitHub Release
```

---

## Data Models

### AccountModel

```dart
class AccountModel extends HiveObject {
  String id;          // Unique ID (timestamp-based)
  String name;        // Account name, e.g. "user@gmail.com"
  String issuer;      // Service name, e.g. "Google"
  String secret;      // Base32-encoded OTP secret
  int digits;         // OTP length: 4–8 (default 6)
  int period;         // TOTP period in seconds (default 30)
  String algorithm;   // "SHA1" | "SHA256" | "SHA512"
  DateTime createdAt; // Creation timestamp
  String type;        // "totp" | "hotp" | "steam"
  int counter;        // HOTP counter (incremented on each navigation)
}
```

Computed properties: `isTotp`, `isHotp`, `isSteam`, `initials`, `otpAuthUri`.

Serialization: `toJson()` / `AccountModel.fromJson()` — used for backup files.

**Backward compatibility:** `HiveField` indices are stable and never reordered. Fields 8 and 9 (`type` and `counter`) read as nullable with defaults (`'totp'` and `0`) so databases created before these fields were added upgrade silently without data loss.

### AppSettings

```dart
class AppSettings extends HiveObject {
  bool useBiometric;           // Biometric enabled (default: false)
  bool requireAuthOnLaunch;    // Show auth screen on open (default: true)
  String? passwordHash;        // Argon2id hash, null if no password set
  bool isDarkMode;             // Dark theme (default: false)
  int autoLockSeconds;         // Inactivity timeout seconds (default: 60)
  int clipboardClearSeconds;   // Clipboard clear delay (default: 30)
  int maxFailedAttempts;       // Lockout threshold (default: 10)
  bool wipeOnMaxAttempts;      // Data wipe on lockout (default: false)
  String? passwordSalt;        // Base64-encoded Argon2id salt
  String? languageCode;        // Locale override, null = system default
  bool clearClipboard;         // Auto-clear clipboard enabled (default: true)
  String? hashVersion;         // 'argon2id' | 'pbkdf2' | null (null = legacy)
  bool screenProtection;       // Android FLAG_SECURE (default: true)
  // ... theme/accent fields (13-18) ...
  bool auditLoggingEnabled;    // Security event logging (default: true)
  bool tamperDetectionEnabled; // Clock rollback detection (default: true)
}
```

**Hive field indices** (0–20) are stable and never reordered. New fields use nullable reads with fallback defaults for backward compatibility with existing databases.

---

## Security Parameters Reference

| Parameter | Value | Location |
|---|---|---|
| **Password KDF** | Argon2id (RFC 9106) | `SecurityService` |
| **Password memory** | 32 768 KB | `SecurityService._argon2id()` |
| **Password iterations** | 3 | `SecurityService._argon2id()` |
| **Password parallelism** | 1 | `SecurityService._argon2id()` |
| **Password salt** | 32 bytes, random | `AppConstants.saltLength` |
| **Password output** | 32 bytes | `SecurityService._argon2id()` |
| **Password thread** | Background Isolate | `Isolate.run()` |
| **Comparison** | Constant-time | hashlib built-in |
| **Legacy KDF** | PBKDF2-HMAC-SHA512, 100 000 iter | `SecurityService.verifyLegacyPbkdf2()` |
| **Accounts box cipher** | AES-256 (Hive) | `StorageService.init()` |
| **Settings box cipher** | AES-256 (Hive) | `StorageService.init()` |
| **DB key storage** | FlutterSecureStorage | `StorageService._getOrCreateKey()` |
| **Backup KDF (V2)** | Argon2id  m=32768, t=3, p=1 | `BackupEncryptionService` |
| **Backup KDF (V1)** | PBKDF2-HMAC-SHA256, 200 000 iter | `BackupEncryptionService._pbkdf2V1()` |
| **Backup salt (V2)** | 32 bytes, random | Per export |
| **Backup salt (V1)** | 16 bytes, random | Per export |
| **Backup cipher** | AES-256-GCM | `BackupEncryptionService` |
| **Backup nonce (V2)** | 12 bytes, random | Per export |
| **Backup nonce (V1)** | 16 bytes, random | Per export |
| **Backup auth tag** | 16 bytes (GCM) | Appended to ciphertext |
| **Backup KDF thread** | Background Isolate | `Isolate.run()` |
| **Min password length** | 8 characters | `AppConstants.minPasswordLength` |
| **Brute-force formula** | `30 × 2^(n−3)` s for n ≥ 3 | `SecurityService.recordFailedAttempt()` |
| **Default auto-lock** | 60 seconds | `AppConstants.defaultAutoLockSeconds` |
| **Default clipboard clear** | 30 seconds | `AppConstants.defaultClipboardClearSeconds` |
| **Default max attempts** | 10 | `AppConstants.defaultMaxFailedAttempts` |
| **Screen protection** | FLAG_SECURE (Android), toggleable | `ScreenProtectionService` |
| **Clock tamper tolerance** | 60 seconds | `TamperDetectionService` |
| **Clock tamper storage** | FlutterSecureStorage (4 keys) | `TamperDetectionService` |
| **Clock tamper unlock** | Password-only (biometric blocked) | `TamperLockdownScreen` |
| **Audit log buffer** | 500 entries, in-memory ring | `LoggerService` |
| **Audit log levels** | debug, info, warning, error, security | `LogLevel` enum |
| **Timestamp recording** | Every 15 seconds while running | `main.dart` timer |
| **TOTP default period** | 30 seconds | RFC 6238 |
| **Steam Guard period** | 30 seconds (enforced) | `TOTPService.generateSteam()` |
| **Steam Guard digits** | 5 (enforced) | Steam spec |
| **Steam Guard alphabet** | `23456789BCDFGHJKMNPQRTVWXY` | 26 unambiguous characters |

---

## Building from Source

**Prerequisites:**
- Flutter 3.10+ (`flutter --version`)
- Dart 3.10+
- Xcode 15+ (iOS / macOS)
- Android Studio with NDK (Android)

```bash
# Clone the repository
git clone https://github.com/dikeckaan/SecureAuth.git
cd SecureAuth

# Install dependencies
flutter pub get

# Install pre-commit hooks (format + analyze checks)
./scripts/setup-hooks.sh

# Regenerate Hive adapters (only needed if you modify models)
dart run build_runner build --delete-conflicting-outputs

# Regenerate localization (only needed if you modify .arb files)
flutter gen-l10n

# Run tests
flutter test

# Run on a connected device in debug mode
flutter run

# Build release APK (Android)
flutter build apk --release

# Build release App Bundle (Android — recommended for Play Store)
flutter build appbundle --release

# Build release IPA (iOS — requires Xcode signing config)
flutter build ios --release
```

---

## Contributing

Contributions are welcome. A few notes:

- **Security issues:** Please open a GitHub issue marked `[SECURITY]` rather than a public PR. Include reproduction steps and impact assessment.
- **New features:** Open an issue to discuss before implementing. Large PRs without prior discussion may not be merged.
- **Localization:** New languages or corrections to existing translations are always appreciated. Edit the relevant `lib/l10n/app_XX.arb` file and run `flutter gen-l10n`.
- **Code style:** This project uses `flutter_lints` with pre-commit hooks. Run `./scripts/setup-hooks.sh` once after cloning — it installs `dart format` + `dart analyze` checks that run automatically before every commit.
- **Testing:** New features should include unit tests. Run `flutter test` to verify. See `test/helpers/fake_secure_storage.dart` for the testing pattern used across the project.

---

<div align="center">

**SecureAuth** — Because your 2FA secrets deserve the same protection as your bank password.

*Built with Flutter · Secured with Argon2id + AES-256-GCM · Trusted by zero cloud servers*

</div>
