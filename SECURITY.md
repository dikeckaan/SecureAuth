# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.0.x   | :white_check_mark: |
| < 2.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in SecureAuth, **please do not open a public issue.**

Instead, please report it responsibly via one of the following methods:

1. **Email:** Send a detailed report to **security@kaandikec.com**
2. **GitHub Private Advisory:** Use [GitHub's security advisory feature](https://github.com/kaandikec/SecureAuth/security/advisories/new)

### What to include in your report

- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Suggested fix (if any)

### Response timeline

- **Acknowledgment:** Within 48 hours
- **Initial assessment:** Within 7 days
- **Fix or mitigation:** Depends on severity (critical: ASAP, high: 14 days, medium: 30 days)
- **Public disclosure:** Coordinated with reporter after fix is released

## Security Architecture

SecureAuth is designed as a **100% offline** application. No data ever leaves the device.

### Cryptographic Primitives

| Component | Algorithm | Parameters |
|-----------|-----------|------------|
| Password hashing | Argon2id (RFC 9106) | m=32768 KB, t=3, p=1, 32-byte output |
| Database encryption | AES-256 (Hive cipher) | Key stored in OS keychain |
| Backup encryption | AES-256-GCM | Argon2id-derived key, 12-byte nonce |
| Key storage | OS-native | iOS Keychain, Android Keystore, macOS Keychain, Windows DPAPI |
| Legacy password hash | PBKDF2-HMAC-SHA512 | 100k iterations (migration only) |

### Brute-Force Protection

Exponential backoff lockout starting at the 3rd failed attempt:

| Attempt | Lockout Duration |
|---------|-----------------|
| 3 | 30 seconds |
| 4 | 1 minute |
| 5 | 2 minutes |
| 6 | 4 minutes |
| 7+ | 8+ minutes |

Optional data wipe after configurable maximum attempts (3-20, default: 10).

### Secure Defaults

- Screen protection (FLAG_SECURE on Android) enabled by default
- Clipboard auto-clear after 30 seconds
- Auto-lock after 60 seconds of inactivity
- Authentication required on launch
- Windows clipboard history exclusion via Win32 API

## Threat Model

### In Scope

- Local device compromise (stolen/lost device)
- Brute-force password attacks
- Clipboard sniffing
- Screen capture / shoulder surfing
- Backup file theft

### Out of Scope

- Compromised operating system with root/admin access
- Hardware-level attacks (cold boot, JTAG)
- Social engineering of the user
- Supply chain attacks on Flutter/Dart ecosystem

## Dependencies

All cryptographic operations use well-audited, maintained libraries:

- `hashlib` — Pure Dart Argon2id and PBKDF2 implementation
- `encrypt` — AES-256-GCM wrapper
- `crypto` — HMAC-SHA1/SHA256/SHA512 for OTP generation
- `flutter_secure_storage` — OS keychain abstraction
- `hive` — Encrypted local database

We regularly monitor dependencies for known vulnerabilities.
