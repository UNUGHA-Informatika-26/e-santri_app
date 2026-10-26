import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../pages/admin/data_hub_page.dart';
import '../pages/admin/monitoring/monitoring_admin_page.dart';
import '../pages/admin/presensi/presensi_admin_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/pengasuh/monitoring/monitoring_pengasuh_page.dart';
import '../services/auth_service.dart';

// ============================================================
// AKSI UMUM
// ============================================================

void tampilkanSegera(BuildContext context, String menu) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$menu akan kita buat pada tahap berikutnya.'),
      backgroundColor: hijau,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<void> keluarDariAplikasi(BuildContext context) async {
  final navigator = Navigator.of(context);

  try {
    await AuthService().logout();
  } catch (_) {
    // Tetap kembali ke halaman login walaupun signOut gagal.
  }

  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}

void tampilkanMenuProfil(
  BuildContext context, {
  required String nama,
  required String peran,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: hijauMuda,
                child: Icon(Icons.person, size: 36, color: hijauTua),
              ),
              const SizedBox(height: 12),
              Text(
                nama,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: hijauTua,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                peran,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    keluarDariAplikasi(context);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Keluar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hijauTua,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ============================================================
// HEADER
// ============================================================

class DashboardHeader extends StatelessWidget {
  final String judul;
  final String subjudul;
  final IconData ikon;
  final VoidCallback onIkon;

  const DashboardHeader({
    super.key,
    required this.judul,
    required this.subjudul,
    required this.ikon,
    required this.onIkon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/logo.png',
            width: 44,
            height: 44,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.mosque, color: hijauTua),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                judul,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: hijauTua,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subjudul,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onIkon,
          icon: Icon(ikon, color: hijau),
        ),
      ],
    );
  }
}

// ============================================================
// KARTU & JUDUL BAGIAN
// ============================================================

class KartuPutih extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const KartuPutih({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

class JudulBagian extends StatelessWidget {
  final String judul;
  final String? aksi;
  final VoidCallback? onAksi;

  const JudulBagian({
    super.key,
    required this.judul,
    this.aksi,
    this.onAksi,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          judul,
          style: const TextStyle(
            color: hijauTua,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (aksi != null)
          GestureDetector(
            onTap: onAksi,
            child: Text(
              aksi!,
              style: const TextStyle(
                color: hijau,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// STATISTIK HADIR / IZIN / SAKIT / ALFA
// ============================================================

class KotakStatistik extends StatelessWidget {
  final String label;
  final String nilai;
  final Color warna;

  const KotakStatistik({
    super.key,
    required this.label,
    required this.nilai,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            nilai,
            style: TextStyle(
              color: warna,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class BarisStatistik extends StatelessWidget {
  final String hadir;
  final String izin;
  final String sakit;
  final String alfa;

  const BarisStatistik({
    super.key,
    required this.hadir,
    required this.izin,
    required this.sakit,
    required this.alfa,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: KotakStatistik(label: 'Hadir', nilai: hadir, warna: hijau),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: KotakStatistik(
            label: 'Izin',
            nilai: izin,
            warna: Colors.blue.shade600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: KotakStatistik(
            label: 'Sakit',
            nilai: sakit,
            warna: Colors.amber.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: KotakStatistik(
            label: 'Alfa',
            nilai: alfa,
            warna: Colors.red.shade600,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// BOTTOM NAVIGATION
// ============================================================

class NavItem {
  final IconData ikon;
  final String label;

  const NavItem(this.ikon, this.label);
}

class DashboardBottomNav extends StatelessWidget {
  final List<NavItem> menu;
  final String nama;
  final String peran;

  /// Tab yang sedang aktif (0 = Dashboard).
  final int currentIndex;

  /// Dipanggil saat tab Dashboard ditekan dari halaman lain.
  final VoidCallback? onDashboard;

  /// Dipanggil saat tab Presensi ditekan (dipakai Pengurus).
  /// Kalau kosong, Admin tetap ke PresensiAdminPage, lainnya tampil "segera".
  final VoidCallback? onPresensi;

  /// Dipanggil saat tab Riwayat ditekan. Kalau kosong, tampil "segera".
  final VoidCallback? onRiwayat;

  const DashboardBottomNav({
    super.key,
    required this.menu,
    required this.nama,
    required this.peran,
    this.currentIndex = 0,
    this.onDashboard,
    this.onPresensi,
    this.onRiwayat,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: hijau,
      unselectedItemColor: Colors.black45,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: (index) {
        if (index == currentIndex) {
          return;
        }

        final item = menu[index];

        if (item.label == 'Dashboard' && onDashboard != null) {
          onDashboard!();
        } else if (item.label == 'Riwayat' && onRiwayat != null) {
          onRiwayat!();
        } else if (item.label == 'Presensi' && onPresensi != null) {
          onPresensi!();
        } else if (item.label == 'Presensi' && peran == 'Admin') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PresensiAdminPage(namaLengkap: nama),
            ),
          );
        } else if (item.label == 'Monitoring' && peran == 'Admin') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MonitoringAdminPage(namaLengkap: nama),
            ),
          );
        } else if (item.label == 'Monitoring' &&
            peran.startsWith('Pengasuh')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MonitoringPengasuhPage(namaLengkap: nama),
            ),
          );
        } else if (item.label == 'Profil') {
          tampilkanMenuProfil(context, nama: nama, peran: peran);
        } else if (item.label == 'Data') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DataHubPage()),
          );
        } else {
          tampilkanSegera(context, item.label);
        }
      },
      items: [
        for (final item in menu)
          BottomNavigationBarItem(
            icon: Icon(item.ikon),
            label: item.label,
          ),
      ],
    );
  }
}