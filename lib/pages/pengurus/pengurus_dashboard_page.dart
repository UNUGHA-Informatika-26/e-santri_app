import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/dashboard_widgets.dart';

class PengurusDashboardPage extends StatelessWidget {
  final String namaLengkap;

  const PengurusDashboardPage({
    super.key,
    this.namaLengkap = 'Pengurus',
  });

  @override
  Widget build(BuildContext context) {
    // DATA CONTOH: nanti diganti data asli dari Supabase.
    const String kamarTugas = 'A-01';
    const int jumlahSantri = 25;

    return Scaffold(
      backgroundColor: krem,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DashboardHeader(
              judul: 'Assalamu\'alaikum, $namaLengkap',
              subjudul: 'Pengurus Kamar $kamarTugas',
              ikon: Icons.notifications_none,
              onIkon: () => tampilkanSegera(context, 'Notifikasi'),
            ),

            const SizedBox(height: 16),

            // KARTU PROFIL
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hijauTua,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: hijauMuda,
                    child: Icon(Icons.person, size: 30, color: hijauTua),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaLengkap,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Kamar Tugas • $kamarTugas',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '$jumlahSantri Santri',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const JudulBagian(judul: 'Presensi hari ini'),

            const SizedBox(height: 10),

            const BarisStatistik(
              hadir: '22',
              izin: '1',
              sakit: '1',
              alfa: '1',
            ),

            const SizedBox(height: 12),

            // PERSENTASE HADIR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hijauMuda.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
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
                            'PERSENTASE HADIR',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                              letterSpacing: 0.6,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '88%',
                            style: TextStyle(
                              color: hijauTua,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fact_check_outlined,
                          color: hijau,
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
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // SESI AKTIF
            KartuPutih(
              child: Row(
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
                        '04.30–05.30 • Belum disimpan',
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
                      color: const Color(0xFFFFE9A8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Isi sekarang',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => tampilkanSegera(context, 'Mulai Presensi'),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text(
                  'Mulai Presensi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hijau,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

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
        peran: 'Pengurus',
        menu: const [
          NavItem(Icons.dashboard_outlined, 'Dashboard'),
          NavItem(Icons.fact_check_outlined, 'Presensi'),
          NavItem(Icons.history, 'Riwayat'),
          NavItem(Icons.person_outline, 'Profil'),
        ],
      ),
    );
  }
}