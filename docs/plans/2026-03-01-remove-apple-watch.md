# Apple Watch Kaldırma ve iPhone Release Build

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Apple Watch ile ilgili tüm commit'leri yeni bir branch'te kaldırıp, iOS-only temiz bir release build'i iPhone'a kurmak.

**Architecture:** `7ff33e1` (watch eklenmeden önceki commit) üzerine yeni bir branch açılıp, watch içermeyen commit'ler cherry-pick ile alınacak. Deployment target commit'inin sadece iOS kısmı manuel uygulanacak.

**Tech Stack:** Flutter, Xcode, iOS, git

---

## Commit Analizi

Watch'la ilgili commit'ler (GEÇMİYORUZ):
- `aa3e68e` – feat: add Apple Watch app (watch dosyalarını ekleyen asıl commit)
- `c90ddb7` – fix: remove unnecessary #if os(watchOS) guard (watch fix)
- `c2bb838` – chore: set deployment target (hem iOS 26.3 hem watchOS 26.3 — iOS kısmını manuel alacağız)

Watch'sız commit'ler (ALACAĞIZ — cherry-pick):
- `91698a2` – ci: add GitHub Actions workflow for Windows build
- `cb3a73c` – fix: resolve Windows-specific issues
- `b5f8c4e` – feat: Windows features + UX fixes
- `b9bad8a` – fix: auto-detect connected iOS device

Temel nokta: `7ff33e1` → cherry-pick `91698a2 cb3a73c b5f8c4e b9bad8a` → iOS deployment target güncelle

---

### Task 1: Yeni Branch Oluştur

**Files:**
- Git history (no files)

**Step 1: `no-watch` branch'ini `7ff33e1` üzerinde oluştur**

```bash
git checkout -b no-watch 7ff33e1
```

Expected: `Switched to a new branch 'no-watch'`

**Step 2: Branch'in doğru commit'te olduğunu doğrula**

```bash
git log --oneline -3
```

Expected: En üstte `7ff33e1` görünmeli.

**Step 3: Commit**

Bu adımda commit yok (branch sadece oluşturuldu).

---

### Task 2: Watch İçermeyen Commit'leri Cherry-Pick Et

**Step 1: Windows ve iOS commit'lerini sırayla cherry-pick et**

```bash
git cherry-pick 91698a2 cb3a73c b5f8c4e b9bad8a
```

Expected: 4 commit başarıyla uygulanır, conflict olmamalı.

**Step 2: Conflict olursa resolve et**

Eğer conflict çıkarsa:
```bash
git cherry-pick --continue
```
ya da iptal için:
```bash
git cherry-pick --abort
```

**Step 3: Sonucu doğrula**

```bash
git log --oneline -6
```

Expected: `b9bad8a`, `b5f8c4e`, `cb3a73c`, `91698a2`, `7ff33e1` sırasıyla görünmeli.

---

### Task 3: iOS Deployment Target'ı Güncelle (Manuel)

`c2bb838` commit'inin sadece iOS kısmı alınacak (watchOS target'ı yok çünkü watch kaldırıldı).

**Files:**
- Modify: `ios/Podfile`
- Modify: `ios/Runner.xcodeproj/project.pbxproj`

**Step 1: Podfile'da iOS deployment target'ı güncelle**

`ios/Podfile` dosyasında:
```
platform :ios, '15.0'  →  platform :ios, '26.3'
IPHONEOS_DEPLOYMENT_TARGET = '15.0'  →  IPHONEOS_DEPLOYMENT_TARGET = '26.3'
```

**Step 2: xcodeproj'da iOS deployment target'ı güncelle**

`ios/Runner.xcodeproj/project.pbxproj` dosyasında tüm Runner target build configuration'larında:
```
IPHONEOS_DEPLOYMENT_TARGET = 13.0;  →  IPHONEOS_DEPLOYMENT_TARGET = 26.3;
```

NOT: `WATCHOS_DEPLOYMENT_TARGET` satırları artık yoktur (watch kaldırıldı), bunları değiştirmeye gerek yok.

**Step 3: Değişiklikleri commit et**

```bash
git add ios/Podfile ios/Runner.xcodeproj/project.pbxproj
git commit -m "chore: set iOS deployment target to 26.3"
```

---

### Task 4: Watch Dosyalarının Temizlendiğini Doğrula

**Step 1: Watch klasörünün olmadığını kontrol et**

```bash
ls ios/ | grep -i watch
```

Expected: Çıktı boş olmalı (hiç watch klasörü görünmemeli).

**Step 2: Flutter dart kodunda watch servisinin olmadığını kontrol et**

```bash
ls lib/services/ | grep watch
```

Expected: Çıktı boş olmalı.

**Step 3: home_screen.dart'ta watch referansı olmadığını doğrula**

```bash
grep -i "watch" lib/screens/home_screen.dart
```

Expected: Hiçbir sonuç çıkmamalı.

**Step 4: Flutter pub get çalıştır**

```bash
flutter pub get
```

Expected: Hatasız tamamlanmalı.

---

### Task 5: Release Build ve iPhone'a Kurulum

**Step 1: iPhone'un bağlı olduğunu doğrula**

```bash
flutter devices
```

Expected: Fiziksel iPhone listede görünmeli.

**Step 2: Release build al ve iPhone'a kur**

```bash
cd /Users/kaandikec/Desktop/SecureAuth
flutter run --release
```

Cihaz ID ile çalıştırmak için:
```bash
DEVICE_ID=$(flutter devices 2>/dev/null \
  | grep " ios " | grep -iv "simulator" \
  | awk -F'•' '{gsub(/ /,"",$2); print $2}' \
  | head -1)
echo "Cihaz: $DEVICE_ID"
flutter run --device-id "$DEVICE_ID" --release
```

Expected: Build başarılı, uygulama iPhone'a yükleniyor.

---

## Hızlı Referans

| Commit | Durum |
|--------|-------|
| `7ff33e1` | Base (watch öncesi) |
| `aa3e68e` | ATLANDI (watch ekleme) |
| `91698a2` | ALINDI (Windows CI) |
| `cb3a73c` | ALINDI (Windows fix) |
| `b5f8c4e` | ALINDI (Windows features + UX) |
| `c90ddb7` | ATLANDI (watch fix) |
| `b9bad8a` | ALINDI (iOS device detect) |
| `c2bb838` | KISMI (sadece iOS target alındı) |
