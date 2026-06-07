# 🥦 NutriTrack App 🍓
> **"Teman Hidup Sehatmu yang Super Imut & Penuh Nutrisi! 🐾✨"**

NutriTrack adalah aplikasi asisten kesehatan dan pelacak gizi harian (*calorie & macro tracker*) berbasis Flutter yang dirancang dengan antarmuka yang sangat manis (*kawaii aesthetics*), mikro-animasi yang gemas, dan integrasi kecerdasan buatan (AI) untuk menemani perjalanan dietmu menjadi menyenangkan! 🎉

---

## 🌟 Fitur Unggulan (Features)

### 1. 🧠 AI Food Scanner (Gemini) 📸
*   **Free Plan**: Batasan **2 kali scan per hari**. Pada scan kedua, kamu akan disuguhi **Iklan Animasi Lucu selama 15 detik** sebelum hasil analisis keluar! 📺🐾
*   **Premium Plan**: **Scan tanpa batas** dan **BEBAS IKLAN selamanya!** 🚀
*   **Cara Kerja**: Cukup foto piring makanmu, AI Gemini akan mendeteksi jenis makanan dan mengestimasikan kalori, karbohidrat, protein, serta lemak secara instan!

### 2. 🔍 Pencarian AI Pintar (Groq) 📝
*   **Free Plan**: Batasan **5 kali pencarian per hari**. Pada pencarian ke-3 dan ke-5, kamu akan ditemani oleh iklan animasi 15 detik yang menggemaskan.
*   **Premium Plan**: **Pencarian tanpa batas** dengan respon secepat kilat!
*   **Cara Kerja**: Tulis nama makanan (misal: "sate ayam lontong bumbu kacang"), AI Groq akan langsung mencari dan menjabarkan rincian gizinya untukmu.

### 3. 🎯 Calorie & Macro Target Tracker 📊
*   Penghitungan kebutuhan kalori harian (*TDEE*) otomatis berdasarkan berat badan, tinggi badan, usia, jenis kelamin, dan tingkat aktivitas fisikmu.
*   Visualisasi grafik target nutrisi harian yang interaktif berbentuk baterai air yang lucu (jika kalori berlebih, baterainya akan memicu animasi meluap! 🌊🔋).

### 4. 👨‍👩‍👧‍👦 Fitur Pemantauan Orang Tua (Parental Control) 🤝
*   Orang tua dapat memantau catatan makanan, grafik kalori, dan riwayat berat badan anak secara real-time dari jarak jauh.

### 5. ⌚ Smartwatch Sync (Detak Jantung) 💓
*   Sinkronisasi detak jantung (*BPM*) harian langsung ke dasbor profil untuk memantau kesehatan jantung secara menyeluruh.

### 6. 👑 Premium Upgrade (Midtrans Snap Integration) 💳
*   Buka semua batasan AI dan matikan iklan hanya dengan **Rp 20.000/bulan**!
*   Terintegrasi dengan payment gateway **Midtrans Snap Sandbox** yang membuka browser secara otomatis, serta dilengkapi **Background Auto-Polling** (aplikasi langsung mendeteksi kesuksesan transaksi dan merubah akun menjadi premium secara otomatis tanpa harus klik apa-apa! 🎩✨).

### 7. 🛡️ Admin Dashboard (Kelola Pengguna) 👑
*   Dashboard khusus untuk administrator untuk memantau daftar pengguna.
*   Tampilan visual yang unik: Pengguna **Free** memiliki border kartu **biru lembut** 🟦, sedangkan pengguna **Premium** bersinar dengan border **emas mewah** 🟨.
*   Admin dapat mengedit plan pengguna secara manual serta mengatur masa aktif langganan.

---

## 🛠️ Tech Stack & Library yang Digunakan

*   **Core**: Flutter (Dart) 🚀
*   **State Management**: Provider 🧩
*   **Local Database / Cache**: Hive 🐝 *(sangat cepat dan ringan untuk penyimpanan offline)*
*   **Backend & Cloud Database**: Cloudflare Workers (Hono API Wrapper) & Firebase Firestore + Authentication 🔥
*   **HTTP Client**: `http` & `url_launcher`
*   **Design & UI**: Google Fonts (Poppins), Custom Painters (Kawaii Apple Loading & Water Battery), HSL tailored color palette.

---

## 🚀 Cara Menjalankan Aplikasi di Lokal (How to Run)

### Prerequisites:
*   Flutter SDK terinstal (versi `>=3.0.0`)
*   Perangkat Android/iOS atau Emulator yang terhubung.

### Langkah-langkah:
1.  **Clone Project** ke komputer lokalmu.
2.  Masuk ke direktori aplikasi:
    ```bash
    cd NutriTrack_app
    ```
3.  Jalankan perintah untuk mengunduh semua dependency:
    ```bash
    flutter pub get
    ```
4.  Buat file `.env` di root folder aplikasi (`NutriTrack_app/.env`) dan isi konfigurasinya:
    ```env
    BACKEND_URL=https://nutritrack-backend.YOUR_SUBDOMAIN.workers.dev
    APP_SECRET_TOKEN=YOUR_APP_SECRET_TOKEN
    ```
5.  Jalankan aplikasi di perangkatmu:
    ```bash
    flutter run
    ```

---

## 📁 Struktur Folder Utama (Strict MVC)
NutriTrack dirancang dengan arsitektur **MVC (Model-View-Controller)** yang sangat ketat dan rapi:
*   📂 `lib/features/`: Berisi fitur-fitur aplikasi (Auth, Dashboard, Profile, Scan, dsb) dipisahkan secara modular.
    *   📂 `models/`: Khusus representasi data (seperti `user_model.dart`). *No UI / business logic!*
    *   📂 `views/`: Widget visual, layout, dan UI. *No API calls!*
    *   📂 `controllers/`: Otak fitur, state management, dan aksi interaksi pengguna.
*   📂 `lib/services/`: Berisi service komunikasi eksternal (Firebase, Gemini Scanner, Groq Service).
*   📂 `lib/helpers/`: Kumpulan utility murni (*pure functions* seperti `calorie_helper.dart`, `app_colors.dart`).

---

> 🍏 **"Sehat itu mudah, diet itu menyenangkan! Yuk catat makanmu hari ini bersama NutriTrack!"** 🐱💕
