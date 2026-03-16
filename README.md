# SmartExpense AI 📱💰

SmartExpense AI adalah aplikasi pencatat keuangan pribadi berbasis iOS (SwiftUI) yang dilengkapi dengan fitur kecerdasan buatan (AI) untuk memindai struk belanja secara otomatis. Aplikasi ini dirancang dengan antarmuka *Glassmorphism* yang modern, premium, dan intuitif.

## Fitur Utama ✨

*   **Pindai Struk Otomatis (AI OCR)**: Gunakan kamera untuk memindai struk belanja. Aplikasi akan secara otomatis mengekstrak informasi seperti nama toko, total belanja, dan tanggal menggunakan Apple Vision Framework dan menyimpannya sebagai transaksi.
*   **Manajemen Anggaran (Budgeting)**: Tetapkan batas pengeluaran bulanan untuk setiap kategori. 
*   **Peringatan Cerdas (Smart Alerts)**: Dapatkan notifikasi lokal saat pengeluaran Anda mencapai 80% atau 100% dari batas anggaran yang telah ditentukan.
*   **Dashboard Interaktif**: Pantau ringkasan keuangan, pendapatan, pengeluaran bulanan, dan sisa saldo Anda dalam satu tampilan komprehensif.
*   **Analitik & Wawasan AI**: Lihat tren pengeluaran bulanan dan dapatkan wawasan (*insights*) cerdas tentang kebiasaan finansial Anda.
*   **Penyimpanan Data Lokal (Offline First)**: Semua data transaksi, kategori, dan anggaran disimpan secara aman di perangkat Anda menggunakan teknologi **SwiftData**, sehingga aplikasi dapat digunakan tanpa koneksi internet.
*   **Format Rupiah (IDR)**: Sepenuhnya mendukung lokalisasi ke format mata uang Rupiah.

## Teknologi yang Digunakan 🛠️

*   **SwiftUI**: Framework UI deklaratif dari Apple untuk antarmuka pengguna yang responsif.
*   **SwiftData**: Solusi persistensi data modern untuk ekosistem Apple.
*   **Vision & VisionKit**: Digunakan untuk pemindaian dokumen (kamera) dan pengenalan teks (OCR).
*   **UserNotifications**: Untuk menjadwalkan dan mengirimkan peringatan anggaran ke pengguna.
*   **Clean Architecture**: Struktur kode yang terorganisir dengan pemisahan antara Data, Application, dan Presentation layer.

## Cara Menjalankan Proyek 🚀

1.  Pastikan Anda memiliki **Xcode** versi terbaru terinstal di Mac Anda (minimal mendukung iOS 17 & SwiftData).
2.  *Clone* repositori ini:
    ```bash
    git clone https://github.com/Irs622/flutter-pencatat-keuangan.git
    ```
3.  Buka terminal dan masuk ke direktori proyek.
4.  Buka file proyek `SmartExpenseAI.xcodeproj` dengan Xcode.
5.  Pilih simulator atau perangkat fisik iOS Anda yang menjalankan iOS 17 ke atas.
6.  Tekan **Cmd + R** (Run) untuk membangun dan menjalankan aplikasi.

---
*Catatan: Meskipun nama repository ini mengandung kata "flutter", proyek ini dikembangkan secara native menggunakan Swift dan SwiftUI.* 
