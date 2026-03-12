# SecureAuth Roadmap

This document outlines planned features and improvements. Items are organized by priority and approximate timeline. Community feedback is welcome — open an issue or discussion to suggest changes.

---

## v2.1 — Quality & Reliability (Next)

**Focus:** Testing, stability, and developer experience.

- [ ] Achieve 80%+ unit test coverage for all services
- [ ] Integration tests for full auth flow (setup → login → lockout → reset)
- [ ] Backup round-trip integration test (export → encrypt → decrypt → import)
- [ ] Adopt Result type across service layer for explicit error handling
- [ ] Wire ServiceLocator into main.dart and all screens
- [ ] Add `dart format` and `flutter analyze` as pre-commit hooks
- [ ] Fix TextEditingController disposal race in backup dialogs

## v2.2 — Migration & Import

**Focus:** Make it easy to switch from other authenticators.

- [ ] Import from Google Authenticator (QR-based migration)
- [ ] Import from Aegis (JSON/encrypted backup)
- [ ] Import from 2FAS (JSON backup)
- [ ] Import from Authy (if technically feasible)
- [ ] Bulk QR scan for multi-account migration

## v2.3 — Cloud Backup (Encrypted)

**Focus:** Optional encrypted backup sync — zero-knowledge design.

- [ ] iCloud backup integration (iOS/macOS) — encrypted blob only
- [ ] Google Drive backup integration (Android) — encrypted blob only
- [ ] Auto-backup on account changes (opt-in)
- [ ] Backup versioning and conflict resolution
- [ ] Backup verification prompt (test restore after export)

## v2.4 — UX Enhancements

**Focus:** Polish and power-user features.

- [ ] Account grouping / folders (Work, Personal, Finance)
- [ ] Search and filter by issuer, name, or tag
- [ ] Account icons (auto-fetched favicon or custom upload)
- [ ] Password strength meter on setup (zxcvbn-style)
- [ ] Onboarding tour for first-time users
- [ ] Accessibility audit (screen reader, contrast, font scaling)

## v3.0 — Advanced Security (Future)

**Focus:** Hardware key support and enterprise features.

- [ ] FIDO2 / WebAuthn hardware key support (YubiKey, etc.)
- [ ] Multi-device sync with end-to-end encryption
- [ ] Organizational/team vault (shared secrets with access control)
- [ ] Secure enclave key derivation where available (iOS Secure Enclave, Android StrongBox)
- [ ] Independent security audit engagement

---

## Completed (v2.0)

- [x] Argon2id password hashing (migration from PBKDF2)
- [x] Encrypted settings box (AES-256)
- [x] Backup format V2 (Argon2id + AES-256-GCM)
- [x] Backward-compatible V1 backup decryption
- [x] Screen protection (Android FLAG_SECURE, iOS blur overlay)
- [x] Windows clipboard history exclusion
- [x] 12-language localization
- [x] Steam Guard token support
- [x] Drag-to-reorder accounts
- [x] Theme customization (light/dark/AMOLED + accent colors)
- [x] Structured logging framework
- [x] CI/CD pipeline (analyze, test, multi-platform build)
- [x] Result type for error handling
- [x] Service locator for dependency injection
