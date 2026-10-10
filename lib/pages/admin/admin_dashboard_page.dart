import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/format_tanggal.dart';
import '../../widgets/dashboard_widgets.dart';
import 'manajemen_akun_page.dart';

class AdminDashboardPage extends StatelessWidget {
  final String namaLengkap;

  const AdminDashboardPage({
    super.key,
    this.namaLengkap = 'Admin',
  });

  Widget _aksesCepat(
    BuildContext context,
    IconData ikon,
    String label,
  ) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => tampilkanSegera(context, label),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(ikon, color: hijau),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  color: hijauTua,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: krem,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DashboardHeader(
              judul: 'Assalamu\'alaikum, $namaLengkap',
              subjudul: formatTanggalIndonesia(DateTime.now()),
              ikon: Icons.notifications_none,
              onIkon: () => tampilkanSegera(context, 'Notifikasi'),
            ),

            const SizedBox(height: 16),

            // RINGKASAN (DATA CONTOH)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: hijauTua,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RINGKASAN PESANTREN',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '128 santri aktif',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '8 kamar • 20 pengurus',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.home_work_outlined,
                      color: Colors.white70,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            const BarisStatistik(
              hadir: '112',
              izin: '7',
              sakit: '5',
              alfa: '4',
            ),

            const SizedBox(height: 20),

            JudulBagian(
              judul: 'Presensi hari ini',
              aksi: 'Lihat rekap',
              onAksi: () => tampilkanSegera(context, 'Rekap presensi'),
            ),

            const SizedBox(height: 10),

            KartuPutih(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sholat Subuh',
                            style: TextStyle(
                              color: hijauTua,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '04.30–05.30 • 8 kamar',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: hijauMuda.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '88% selesai',
                          style: TextStyle(
                            color: hijauTua,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      value: 0.88,
                      minHeight: 8,
                      color: hijau,
                      backgroundColor: Color(0xFFE5E7E5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const JudulBagian(judul: 'Akses cepat'),

            const SizedBox(height: 10),

            Row(
              children: [
                _aksesCepat(context, Icons.person_add_alt, 'Tambah Santri'),
                const SizedBox(width: 8),
                _aksesCepat(context, Icons.fact_check_outlined, 'Buat Presensi'),
                const SizedBox(width: 8),
                _aksesCepat(context, Icons.bed_outlined, 'Data Kamar'),
              ],
            ),

            const SizedBox(height: 10),

            // TOMBOL MANAJEMEN AKUN
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManajemenAkunPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.manage_accounts_outlined, color: hijau),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manajemen Akun',
                            style: TextStyle(
                              color: hijauTua,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Setujui pendaftaran dan kelola pengguna',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: hijau),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '2 kamar belum mengirim presensi',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Kamar B-03 dan C-01 • Sholat Subuh',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            const Center(
              child: Text(
                'Angka di atas masih data contoh.',
                style: TextStyle(color: Colors.black38, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DashboardBottomNav(
        nama: namaLengkap,
        peran: 'Admin',
        menu: const [
          NavItem(Icons.dashboard_outlined, 'Dashboard'),
          NavItem(Icons.storage_outlined, 'Data'),
          NavItem(Icons.fact_check_outlined, 'Presensi'),
          NavItem(Icons.show_chart, 'Monitoring'),
          NavItem(Icons.person_outline, 'Profil'),
        ],
      ),
    );
  }
}