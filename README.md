# SecureAuth - Offline 2FA Authenticator

Gizliliğe önem veren, tamamen offline çalışan güvenli iki faktörlü kimlik doğrulama (2FA) uygulaması.

## 🔐 Özellikler

### Güvenlik
- ✅ **Tamamen Offline**: İnternet erişimi yok, tüm veriler cihazda kalır
- ✅ **Şifreli Depolama**: Hive AES şifrelemesi ile güvenli local storage
- ✅ **Biyometrik Kimlik Doğrulama**: Parmak izi / Face ID desteği
- ✅ **Şifre Koruması**: İsteğe bağlı şifre ile uygulama kilidi

### Fonksiyonlar
- ✅ **TOTP Token Üretimi**: Standart 6 haneli, 30 saniyelik kodlar
- ✅ **QR Kod Tarama**: İsteğe bağlı kamera erişimi ile QR kod okuma
- ✅ **QR Kod Oluşturma**: Hesapları QR kod olarak dışa aktarma
- ✅ **JSON Import/Export**: Hesapları yedekleme ve geri yükleme
- ✅ **Karanlık Mod**: Göz dostu karanlık tema
- ✅ **Hesap Yönetimi**: Düzenleme, silme, arama özellikleri

## 📱 Desteklenen Platformlar

- iOS
- Android
- macOS
- Linux
- Windows

## 🚀 Kurulum ve Çalıştırma

### Gereksinimler

- Flutter SDK (3.10.3 veya üzeri)
- Dart SDK
- iOS için Xcode (macOS üzerinde)
- Android için Android Studio

### Adımlar

1. **Bağımlılıkları yükleyin:**
   ```bash
   flutter pub get
   ```

2. **Uygulamayı çalıştırın:**
   ```bash
   flutter run
   ```

### Platformlara Özgü Notlar

#### iOS
- iOS 11.0 veya üzeri gereklidir
- Face ID kullanmak için Info.plist'te `NSFaceIDUsageDescription` eklenmiştir
- QR tarama için kamera izni isteğe bağlıdır

#### Android
- Android API 21 (Lollipop) veya üzeri
- Kamera izni isteğe bağlıdır (QR tarama için)
- Biyometrik izinler otomatik olarak yapılandırılmıştır

## 📖 Kullanım

### İlk Kurulum

1. Uygulamayı ilk kez açtığınızda güvenlik kurulumu ekranı gelir
2. Bir şifre belirleyin (en az 6 karakter)
3. İsteğe bağlı: Biyometrik kimlik doğrulamayı etkinleştirin
4. Veya "Şifresiz Devam Et" ile koruma olmadan devam edin

### Hesap Ekleme

**Yöntem 1: QR Kod Tarama**
1. Ana ekranda "Hesap Ekle" butonuna tıklayın
2. "QR Kod Tara" seçeneğini seçin
3. Kamera izni verin (isteğe bağlı)
4. Servis sağlayıcının QR kodunu tarayın

**Yöntem 2: Manuel Girdi**
1. "Hesap Ekle" butonuna tıklayın
2. Yayıncı adını girin (ör: Google, GitHub)
3. Hesap adını girin (ör: kullanici@ornek.com)
4. Secret key'i girin
5. "Hesabı Kaydet" butonuna tıklayın

### Hesap Yönetimi

- **Kodu Kopyalama**: Hesap kartına tıklayarak kodu panoya kopyalayın
- **QR Kod Gösterme**: Hesap menüsünden "QR Kod Göster" seçeneği
- **Düzenleme**: Hesap ismini veya yayıncıyı değiştirin
- **Silme**: Hesabı kalıcı olarak silin
- **Arama**: Üstteki arama çubuğu ile hesapları filtreleyin

### Yedekleme ve Geri Yükleme

**Dışa Aktarma:**
1. Ayarlar > Hesapları Dışa Aktar
2. JSON dosyası oluşturulur ve paylaşma menüsü açılır
3. Dosyayı güvenli bir yere kaydedin

**İçe Aktarma:**
1. Ayarlar > Hesapları İçe Aktar
2. JSON dosyasını seçin
3. Hesaplar otomatik olarak eklenir (mevcut hesaplar korunur)

## 🏗️ Proje Yapısı

```
lib/
├── main.dart              # Uygulama giriş noktası
├── models/                # Veri modelleri
│   ├── account_model.dart
│   └── app_settings.dart
├── services/              # İş mantığı servisleri
│   ├── storage_service.dart    # Hive encrypted storage
│   ├── auth_service.dart       # Kimlik doğrulama
│   ├── totp_service.dart       # TOTP kod üretimi
│   └── qr_service.dart         # QR kod işlemleri
├── screens/               # UI ekranları
│   ├── setup_screen.dart       # İlk kurulum
│   ├── auth_screen.dart        # Giriş ekranı
│   ├── home_screen.dart        # Ana sayfa
│   ├── add_account_screen.dart # Hesap ekleme
│   ├── qr_scanner_screen.dart  # QR tarayıcı
│   ├── qr_display_screen.dart  # QR gösterme
│   └── settings_screen.dart    # Ayarlar
├── widgets/               # Tekrar kullanılabilir UI bileşenleri
│   ├── account_card.dart
│   └── custom_button.dart
└── utils/                 # Yardımcı dosyalar
    ├── constants.dart
    └── theme.dart
```

## 🔒 Güvenlik Özellikleri

### Veri Şifreleme
- Tüm hesap verileri Hive AES şifrelemesi ile korunur
- Şifreleme anahtarı Flutter Secure Storage ile saklanır
- Şifreler SHA-256 hash algoritması ile saklanır

### İzinler
- **Kamera**: Sadece QR kod tarama için kullanılır (isteğe bağlı)
- **Biyometrik**: Kimlik doğrulama için kullanılır (isteğe bağlı)
- **İnternet**: ASLA kullanılmaz - tamamen offline

### Gizlilik
- Hiçbir analitik veya tracking yok
- Hiçbir veri dışarı gönderilmez
- Tüm veriler cihazda kalır

## 📦 Kullanılan Paketler

| Paket | Amaç |
|-------|------|
| `hive` & `hive_flutter` | Şifreli local storage |
| `flutter_secure_storage` | Güvenli anahtar saklama |
| `local_auth` | Biyometrik kimlik doğrulama |
| `otp` | TOTP kod üretimi |
| `qr_flutter` | QR kod oluşturma |
| `mobile_scanner` | QR kod tarama |
| `crypto` | Şifreleme işlemleri |
| `share_plus` | Dosya paylaşma |
| `file_picker` | Dosya seçme |

## 🛡️ Güvenlik Notları

1. **Secret Key'leri Güvende Tutun**: Secret key'ler hesaplarınızın anahtarıdır
2. **Düzenli Yedekleme**: JSON export ile düzenli yedek alın
3. **Güçlü Şifre Kullanın**: En az 6 karakter, karmaşık bir şifre seçin
4. **Yedekleri Güvenli Saklayın**: JSON export dosyalarını şifreli bir yerde tutun

## 🤝 Katkıda Bulunma

Bu proje açık kaynaklıdır. Katkılarınızı bekliyoruz!

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## ⚠️ Sorumluluk Reddi

Bu uygulama eğitim amaçlıdır. Üretim ortamında kullanmadan önce kapsamlı güvenlik testleri yapılmalıdır.

## 🐛 Sorun Bildirme

Bir hata bulduysanız veya öneriniz varsa lütfen GitHub Issues üzerinden bildirin.

---

**Not**: Bu uygulama tamamen offline çalışır ve hiçbir veriyi dışarıya göndermez. Tüm verileriniz cihazınızda güvenli bir şekilde şifrelenerek saklanır.
