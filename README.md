# 🎬 CineRate Movie Trailer App 📱

Flutter ile geliştirdiğim **Movie Trailer App**, kullanıcıların popüler filmleri keşfedip, favori listesi oluşturabileceği ve kendi profillerini yönetebileceği bir mobil uygulamadır.  
Uygulama, **The Movie Database (TMDB)** API’si ile güncel film bilgilerini kullanıcıya sunar.

---

## 📌 Proje Özeti

Bu uygulamanın amacı; kullanıcıların dilediği filmleri kolayca keşfetmesi, favorilerine eklemesi ve profilini yönetebilmesini sağlamaktır.  
Modern UI tasarımı ve açık/koyu tema desteği ile kullanıcı deneyimi üst seviyede tutulmuştur. Offline çalışması gereken favori filmler listesi ise **SQLite** ile saklanmaktadır.

---

## 🛠️ Kullanılan Teknolojiler

- **Flutter**: Mobil uygulama geliştirme  
- **Dart**: Programlama dili  
- **Provider**: State management  
- **SQLite**: Lokal veritabanı  
- **HTTP**: API veri çekme  
- **Shared Preferences**: Lokal veri saklama  
- **Material Design**: Modern UI prensipleri  

---

## 📷 Ekran Görüntüleri

### 🖥️ Main Menu
![Main Menu](https://github.com/AbdulmecidNasir/Cine_Rate_Movie_App/blob/1cc3fa4d69af65746d015cefbce85aba89f922e5/screenshots/Screenshot%202025-06-23%20232204.png)  ### 🖥️ Main Menu (Dark Mode)
![Main Menu (Dark Mode)](https://github.com/AbdulmecidNasir/Cine_Rate_Movie_App/blob/1cc3fa4d69af65746d015cefbce85aba89f922e5/screenshots/Screenshot%202025-06-24%20085557.png)



### 🖥️ Searching Page
![Searching Page](https://github.com/AbdulmecidNasir/Cine_Rate_Movie_App/blob/1cc3fa4d69af65746d015cefbce85aba89f922e5/screenshots/Screenshot%202025-06-23%20232256.png)

### 🖥️ Movie Detail Page
![Movie Detail Page](https://github.com/AbdulmecidNasir/Cine_Rate_Movie_App/blob/1cc3fa4d69af65746d015cefbce85aba89f922e5/screenshots/Screenshot%202025-06-23%20232348.png)

### 🖥️ Movie Detail Page 2 (Trailer)
![Movie Detail Page 2 (Trailer)](https://github.com/AbdulmecidNasir/Cine_Rate_Movie_App/blob/1cc3fa4d69af65746d015cefbce85aba89f922e5/screenshots/Screenshot%202025-06-23%20233124.png)

### 🖥️ Movie Category Page
![Movie Category Page](https://github.com/AbdulmecidNasir/Cine_Rate_Movie_App/blob/1cc3fa4d69af65746d015cefbce85aba89f922e5/screenshots/Screenshot%202025-06-23%20233234.png)

### 🖥️ Movie Category Page (Korku)
![Movie Category Page (Korku)](https://github.com/AbdulmecidNasir/Cine_Rate_Movie_App/blob/1cc3fa4d69af65746d015cefbce85aba89f922e5/screenshots/Screenshot%202025-06-23%20233306.png)

### 🖥️ Favourite Page
![Favourite Page](https://github.com/AbdulmecidNasir/Cine_Rate_Movie_App/blob/1cc3fa4d69af65746d015cefbce85aba89f922e5/screenshots/Screenshot%202025-06-24%20090608.png)

### 🖥️ Profile Page
![Profile Page](https://github.com/AbdulmecidNasir/Cine_Rate_Movie_App/blob/1cc3fa4d69af65746d015cefbce85aba89f922e5/screenshots/Screenshot%202025-06-24%20085505.png)

### 🖥️ Movie Category Page (Animasyon)
![Movie Category Page (Animasyon)](https://github.com/AbdulmecidNasir/Cine_Rate_Movie_App/blob/1cc3fa4d69af65746d015cefbce85aba89f922e5/screenshots/Screenshot%202025-06-24%20085648.png)

### 🖥️ Sign In/Sign Up page
![Sign In/Sign Up page](https://github.com/AbdulmecidNasir/Cine_Rate_Movie_App/blob/1cc3fa4d69af65746d015cefbce85aba89f922e5/screenshots/Screenshot%202025-06-24%20090134.png)


## 📂 Proje Yapısı ve Mimarisi

```plaintext
lib/
├── api/               → API işlemleri
├── database/          → SQLite işlemleri
├── models/            → Veri modelleri
├── pages/             → Uygulama sayfaları
├── providers/         → State management
├── theme/             → Tema yönetimi
├── widgets/           → Ortak kullanılan widgetlar
├── main.dart          → Uygulama giriş noktası

🛢️ Veritabanı Yapısı
SQLite kullanılarak local bir veritabanı oluşturulmuştur.
Bu veritabanında:

📌 Kullanıcı bilgileri

📌 Favori filmler

📌 Profil fotoğrafı ve kişisel bilgiler

saklanmaktadır. Tüm işlemler database/ klasörü altındaki servis dosyalarıyla yönetilmektedir.

🌐 API Entegrasyonu
TMDB (The Movie Database) API kullanılarak;

🎞️ Popüler filmler

📁 Kategorilere göre filmler

📖 Film detay bilgileri

çekilmektedir. API işlemleri HTTP paketiyle yapılmakta ve hata kontrolü sağlanmaktadır.

🎨 UI / UX Tasarımı
Modern Material Design prensiplerine uygun, kullanıcı dostu ve responsive bir tasarım uygulanmıştır.

Uygulama arayüzünde:

🌗 Açık / Koyu tema desteği

🎞️ Animasyonlar ve geçiş efektleri

📱 Responsive yapılar

bulunmaktadır.

💡 Öne Çıkan Özellikler
✅ Popüler filmleri keşfetme
✅ Kategorilere göre film listeleme
✅ Favorilere film ekleme ve yönetme
✅ Kişisel profil oluşturma ve düzenleme
✅ Açık / Koyu tema desteği
✅ SQLite ile offline veri saklama
✅ Shared Preferences ile kullanıcı bilgisi saklama

🔐 Güvenlik ve Performans
Veri Güvenliği: Local SQLite ve Shared Preferences kullanımı

Performans: API isteklerinde cache ve lazy loading yapısı

Hata Yönetimi: API ve veri işlemlerinde try-catch yapısı

