# SAWIT PRO v2 — Build APK dari HP Android

Paket ini disiapkan agar source code dapat dibuild memakai GitHub Actions, sehingga HP tidak perlu memasang Flutter SDK dan Android SDK.

## Cara paling sederhana dari HP

1. Buat/login akun GitHub.
2. Buat repository baru, misalnya `sawit-pro-v2`.
3. Upload seluruh isi folder project ini ke repository tersebut.
4. Pastikan file `.github/workflows/build-apk.yml` ikut ter-upload.
5. Buka tab **Actions** pada repository.
6. Pilih workflow **Build SAWIT PRO v2 APK**.
7. Tekan **Run workflow** bila workflow belum berjalan otomatis.
8. Tunggu sampai status workflow hijau/berhasil.
9. Buka hasil workflow tersebut dan bagian **Artifacts**.
10. Download `SAWIT_PRO_v2_APK` lalu ekstrak ZIP-nya. Di dalamnya ada `app-release.apk`.
11. Instal APK di HP Android. Jika Android meminta izin pemasangan dari sumber tersebut, aktifkan izin untuk browser/file manager yang digunakan.

## Catatan

- Build release menggunakan `flutter build apk --release --no-shrink`.
- Android platform files akan dibuat otomatis oleh Flutter jika folder `android/` belum ada.
- File database SQLite tetap dibundel di `assets/db/sawit_pro_v2.db`.
- APK hasil workflow adalah build yang dihasilkan server GitHub, bukan APK yang sudah diuji di perangkat fisik.
- Untuk distribusi resmi/Play Store, aplikasi perlu signing/release key sendiri. Jangan menyimpan password/key pribadi di repository publik.
