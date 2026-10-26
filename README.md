# E-Santri

Aplikasi mobile berbasis Flutter untuk **presensi dan monitoring santri** pondok pesantren (putra dan putri). Backend memakai **Supabase**. Platform: Android.

## Peran Pengguna

| Peran | Fungsi utama |
|---|---|
| **Admin** | Mengelola data (santri, kamar, pengurus, kegiatan), menyetujui akun, melihat hasil presensi, rekap, dan monitoring pengurus |
| **Pengurus** | Mengisi presensi santri di kamar tugasnya, melihat riwayat, dan mengirim laporan ke WhatsApp |
| **Pengasuh / Kyai** | Melihat dashboard dan monitoring kepatuhan presensi pengurus (hanya melihat) |

Pendaftaran publik hanya untuk Pengurus dan Pengasuh. Akun baru berstatus `pending` sampai disetujui Admin. Akun Admin dibuat langsung lewat Supabase.

## Fitur

- Login dengan username atau email, dengan pengecekan status akun dan peran
- Manajemen akun (setujui atau tolak pendaftar)
- Data Santri, Kamar, Pengurus, dan Kegiatan
- Presensi per kamar, kegiatan, dan tanggal (Hadir, Izin, Sakit, Alfa) beserta keterangan
- Pratinjau dan kirim laporan presensi ke WhatsApp
- Riwayat presensi Pengurus
- Presensi Admin: filter, daftar laporan, detail, dan rekap
- Monitoring Admin dan Pengasuh: persentase kepatuhan, tren 7 hari, dan detail per pengurus
- Dashboard untuk tiga peran dengan data asli dari database

## Teknologi

- Flutter dan Dart
- State management: `flutter_bloc`
- Backend: Supabase (`supabase_flutter`) dengan Row Level Security
- Lainnya: `url_launcher`, `hive_ce`, `connectivity_plus`

## Struktur Folder

```
lib/
  blocs/      logika (Bloc) per fitur
  core/       konstanta warna, konfigurasi Supabase, utilitas
  pages/
    admin/    layar Admin
    pengurus/ layar Pengurus
    pengasuh/ layar Pengasuh
    auth/     login, daftar, lupa dan reset password, splash
  widgets/    komponen bersama
  main.dart
```

Pola tiap fitur: **Service** mengambil data dari Supabase, **Bloc** mengatur event dan state, **Page** hanya menampilkan.

## Menjalankan Proyek

Prasyarat: Flutter SDK, Android SDK, dan proyek Supabase.

```bash
git clone https://github.com/UNUGHA-Informatika-26/e-santri_app.git
cd e-santri_app
flutter pub get
flutter run
```

Isi URL dan **anon key** proyek Supabase Anda di `lib/core/supabase/supabase_config.dart`.

> **Penting:** jangan pernah memasukkan `service_role` key ke aplikasi atau ke repo. Hanya anon key yang boleh dipakai di sisi aplikasi.

## Database

Tabel utama: `profiles`, `kamar`, `pengurus`, `santri`, `kegiatan`, `presensi`, dan `whatsapp_settings`. Hak akses diatur lewat Row Level Security dan fungsi `is_admin()`, `is_pengurus()`, `is_pengasuh()`. Fungsi `daftar_nama_pengurus()` memungkinkan Pengasuh membaca nama pengurus.

Data presensi disimpan dengan `upsert` (kunci unik: santri, kegiatan, tanggal), sehingga aman dikirim ulang.

## Build APK

```bash
flutter build apk --release
```

Hasil: `build/app/outputs/flutter-apk/app-release.apk`. APK siap pakai tersedia di halaman [Releases](https://github.com/UNUGHA-Informatika-26/e-santri_app/releases).

## Status Pengembangan

- [x] Login, manajemen akun, dan data master
- [x] Presensi Pengurus, riwayat, dan pratinjau WhatsApp
- [x] Monitoring dan Presensi Admin
- [x] Dashboard tiga peran
- [ ] Presensi offline dengan sinkronisasi otomatis
- [ ] Integrasi WhatsApp Admin (pengaturan grup)
- [ ] Edit profil dan data Pengasuh

## Pengembang

**Uswatun Hasanah**
Mahasiswa Informatika UNUGHA, proyek semester 7.