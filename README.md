# Telefon ve Saat için NFC Emülatör

Flutter ile geliştirilmiş gelişmiş NFC emülatör uygulaması. Mifare Classic kartlarını emüle edebilir, okuyabilir ve yazabilir.

## 🎯 Özellikler

### 📱 Çalışma Modları
- **Emülatör**: Telefonu NFC kartı gibi gösterir
- **Okuyucu**: NFC kartlarını okur
- **Yazıcı**: NFC kartlarına yazar

### 🃏 Desteklenen Kart Tipleri
- **Mifare Classic** (1K/4K) - Ana odak
- **Mifare Ultralight**
- **ISO-DEP** (Banka/Kredi Kartları)
- **NDEF** (Text/URI)
- **FeliCa** (Sony)
- **ISO15693** (Vicinity)

### 🔧 Teknik Özellikler
- 16 sektör, 64 blok Mifare Classic yapısı
- UID, BCC, SAK, ATQA desteği
- Trailer blokları (Key A/B + Access Bits)
- Gerçek Mifare veri yapısı
- Host Card Emulation (HCE) desteği
- Akıllı saat optimizasyonu

## 📋 Gereksinimler

- Flutter 3.0+
- Android SDK 26+
- Android NDK 27.0.12077973+
- NFC destekli Android cihaz

## 🚀 Kurulum


2. **Bağımlılıkları yükleyin:**
```bash
flutter pub get
```

3. **Android ayarlarını kontrol edin:**
- `android/app/build.gradle.kts` dosyasında minSdk = 26 olduğundan emin olun
- NFC izinlerinin `AndroidManifest.xml`'de tanımlı olduğunu kontrol edin

4. **Uygulamayı çalıştırın:**
```bash
flutter run
```

## 📦 APK Oluşturma

Release APK oluşturmak için:
```bash
flutter build apk --release
```

APK dosyası `build/app/outputs/flutter-apk/app-release.apk` konumunda oluşturulur.

## 🔧 Kullanım

### Emülatör Modu
1. "Çalışma Modu" dropdown'ından "Emülatör" seçin
2. "Kart Tipi" dropdown'ından "Mifare Classic" seçin
3. "Başlat" butonuna basın
4. Telefonu NFC okuyucuya yaklaştırın

### Okuyucu Modu
1. "Çalışma Modu" dropdown'ından "Okuyucu" seçin
2. "Başlat" butonuna basın
3. NFC kartını telefona yaklaştırın
4. Loglar bölümünde kart bilgilerini görün

### Yazıcı Modu
1. "Çalışma Modu" dropdown'ından "Yazıcı" seçin
2. "Başlat" butonuna basın
3. Yazılacak NFC kartını telefona yaklaştırın
4. Kart numarası kartın üzerine yazılır

### Ana Ekran
- Durum kartı (NFC hazır/değil)
- Çalışma modu seçimi
- Kart tipi seçimi
- Kart numarası gösterimi
- Başlat/Durdur butonları
- Gerçek zamanlı loglar

### Akıllı Saat Optimizasyonu
- Kompakt ve sade arayüz
- Kolay dokunma hedefleri
- Minimal bilgi gösterimi
- Hızlı erişim

## 🔒 Güvenlik

- NFC işlemleri sadece uygulama açıkken çalışır
- Kart numarası güvenli şekilde saklanır
- HCE sadece gerekli durumlarda aktif olur

## 🛠️ Teknik Detaylar

### Kullanılan Paketler
- `flutter_nfc_kit: ^3.6.0` - Gelişmiş NFC işlevleri
- `nfc_manager: ^3.3.0` - Temel NFC yönetimi
- `permission_handler: ^11.3.1` - İzin yönetimi

### Mifare Classic Yapısı
```
Sektör 0: UID + BCC + SAK + ATQA + Data
Sektör 1-15: Data Blokları + Trailer
Trailer: Key A (6B) + Access Bits (4B) + Key B (6B)
```

### NFC Protokolleri
- ISO 14443 Type A (Mifare Classic)
- NDEF (NFC Data Exchange Format)
- Host Card Emulation (HCE)


## ⚠️ Uyarılar

- Mifare Classic tam emülasyonu donanım kısıtlamaları nedeniyle sınırlıdır
- Android HCE ile sadece ISO-DEP protokolü tam desteklenir
- Bazı NFC okuyucular tüm kart tiplerini desteklemeyebilir
- Test etmeden önce güvenli kartlar kullanın



## 🔄 Güncellemeler

### v1.0.0
- İlk sürüm
- Mifare Classic emülasyonu
- 3 çalışma modu
- Akıllı saat optimizasyonu

**Not**: Bu uygulama eğitim ve test amaçlıdır. Gerçek kart sistemlerinde kullanmadan önce gerekli testleri yapın.


## 📱 Ekran Görüntüleri

- Gelişmiş NFC kit entegrasyonu

---
![image](https://github.com/user-attachments/assets/cfb77217-f245-4af9-8f90-e853ec92a626) 
![image](https://github.com/user-attachments/assets/e6aed3cb-b05c-4328-b6c7-4799039dc4c3)
![image](https://github.com/user-attachments/assets/97c21217-7262-4cb7-b424-622da24d6cfd) ![image](https://github.com/user-attachments/assets/b1457c43-27c1-4acd-8b03-2c6288050603)
![image](https://github.com/user-attachments/assets/8ee41bd1-9925-4433-95bf-9d7c86fa68c7) ![image](https://github.com/user-attachments/assets/cb3ed530-a18a-4796-886e-777f5fe7cff4)


<img width="100" alt="Image" src="https://github.com/user-attachments/assets/17ff9202-39b1-42c1-9eac-b694799d7eb2" />

![Image](https://github.com/user-attachments/assets/46ef043f-d347-4b2f-bccc-111806bba2a0)

![Image](https://github.com/user-attachments/assets/419281a7-cbb2-4ab0-bd7c-cb3d6060e310)

![Image](https://github.com/user-attachments/assets/8b421c98-7dc9-4d74-8799-f2bdffcae420)

![Image](https://github.com/user-attachments/assets/37283011-ae6f-478c-bfd4-ff9f688d0703)







