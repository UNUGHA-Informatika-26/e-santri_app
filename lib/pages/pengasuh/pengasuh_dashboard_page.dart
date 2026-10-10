import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/dashboard_widgets.dart';

class PengasuhDashboardPage extends StatelessWidget {
  final String namaLengkap;

  const PengasuhDashboardPage({
    super.key,
    this.namaLengkap = 'Pengasuh',
  });

  Widget _kartuAngka({
    required String label,
    required String nilai,
    required IconData ikon,
  }) {
    return Expanded(
      child: KartuPutih(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                Icon(ikon, color: hijau, size: 18),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              nilai,
              style: const TextStyle(
                color: hijauTua,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kartuPeringkat({
    required String label,
    required String nama,
    required String nilai,
    required Color latar,
    required Color warnaNilai,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: latar,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              nama,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              nilai,
              style: TextStyle(
                color: warnaNilai,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // DATA CONTOH untuk grafik 7 hari (tinggi batang relatif).
    const List<double> tren7Hari = [40, 55, 38, 72, 58, 82, 48];

    return Scaffold(
      backgroundColor: krem,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DashboardHeader(
              judul: 'Dashboard Monitoring',
              subjudul: 'Assalamu\'alaikum, $namaLengkap',
              ikon: Icons.calendar_month_outlined,
              onIkon: () => tampilkanSegera(context, 'Kalender'),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PENGASUH / KYAI • READ-ONLY',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _kartuAngka(
                  label: 'Total Pengurus',
                  nilai: '20',
                  ikon: Icons.groups_outlined,
                ),
                const SizedBox(width: 10),
                _kartuAngka(
                  label: 'Rata-rata Presensi',
                  nilai: '91%',
                  ikon: Icons.trending_up,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // KONSISTENSI PENGURUS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hijauMuda.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: hijau,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '91%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'rata-rata',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konsistensi Pengurus',
                          style: TextStyle(
                            color: hijauTua,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '18 dari 20 pengurus berada di atas target 85%.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          child: LinearProgressIndicator(
                            value: 0.9,
                            minHeight: 6,
                            color: hijau,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _kartuPeringkat(
                  label: 'TERTINGGI',
                  nama: 'Siti Aminah',
                  nilai: '98%',
                  latar: hijauMuda.withValues(alpha: 0.2),
                  warnaNilai: hijau,
                ),
                const SizedBox(width: 10),
                _kartuPeringkat(
                  label: 'TERENDAH',
                  nama: 'Fikri Ramadhan',
                  nilai: '78%',
                  latar: const Color(0xFFFDE8E8),
                  warnaNilai: Colors.red.shade600,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // TREN 7 HARI
            KartuPutih(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tren 7 hari',
                        style: TextStyle(
                          color: hijauTua,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Minggu Ini',
                        style: TextStyle(
                          color: hijau,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 90,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (int i = 0; i < tren7Hari.length; i++) ...[
                          Expanded(
                            child: Container(
                              height: tren7Hari[i],
                              decoration: BoxDecoration(
                                color: i == 5
                                    ? hijau
                                    : hijauMuda.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          if (i != tren7Hari.length - 1)
                            const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Persentase laporan pengurus per hari',
                    style: TextStyle(color: Colors.black45, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // TREN BULANAN
            KartuPutih(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Konsistensi bulanan',
                    style: TextStyle(
                      color: hijauTua,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 90,
                    width: double.infinity,
                    child: CustomPaint(painter: _GarisBulananPainter()),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                'Angka dan grafik di atas masih data contoh.',
                style: TextStyle(color: Colors.black38, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DashboardBottomNav(
        nama: namaLengkap,
        peran: 'Pengasuh / Kyai',
        menu: const [
          NavItem(Icons.dashboard_outlined, 'Dashboard'),
          NavItem(Icons.show_chart, 'Monitoring'),
          NavItem(Icons.person_outline, 'Profil'),
        ],
      ),
    );
  }
}

class _GarisBulananPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const data = [0.2, 0.35, 0.3, 0.5, 0.45, 0.6, 0.7, 0.65, 0.8];

    final paint = Paint()
      ..color = hijau
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    for (int i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final y = size.height * (1 - data[i]);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}