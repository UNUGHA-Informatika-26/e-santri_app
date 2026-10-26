import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/dashboard_pengasuh_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/dashboard_widgets.dart';

class PengasuhDashboardPage extends StatelessWidget {
  final String namaLengkap;

  const PengasuhDashboardPage({
    super.key,
    this.namaLengkap = 'Pengasuh',
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardPengasuhBloc>(
      create: (_) => DashboardPengasuhBloc(service: DashboardPengasuhService())
        ..add(const DashboardPengasuhDimuat()),
      child: _Tampilan(namaLengkap: namaLengkap),
    );
  }
}

class _Tampilan extends StatelessWidget {
  final String namaLengkap;

  const _Tampilan({required this.namaLengkap});

  static const int _targetPersen = DashboardPengasuhService.targetPersen;

  Future<void> _muatUlang(BuildContext context) async {
    final bloc = context.read<DashboardPengasuhBloc>();
    bloc.add(const DashboardPengasuhDimuat());
    await bloc.stream.firstWhere((s) => !s.memuat);
  }

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
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
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
    required List<String> nama,
    required String nilai,
    required Color latar,
    required Color warnaNilai,
  }) {
    final teks = nama.length > 2 ? '${nama.length} pengurus' : nama.join(', ');

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
              teks,
              maxLines: 2,
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

  Widget _kartuKonsistensi(DataPengasuh d) {
    final nilai = (d.rataRata / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hijauMuda.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: nilai,
                    strokeWidth: 8,
                    color: hijau,
                    backgroundColor: Colors.white,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${d.rataRata}%',
                      style: const TextStyle(
                        color: hijauTua,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'rata-rata',
                      style: TextStyle(color: Colors.black54, fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Konsistensi Pengurus',
                  style: TextStyle(
                    color: hijauTua,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${d.diAtasTarget} dari ${d.totalPengurus} pengurus berada di atas target $_targetPersen%.',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: d.totalPengurus == 0
                        ? 0
                        : d.diAtasTarget / d.totalPengurus,
                    minHeight: 8,
                    color: hijau,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuTren7(DataPengasuh d) {
    return KartuPutih(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tren 7 hari',
                style: TextStyle(color: hijauTua, fontWeight: FontWeight.bold),
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
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < d.tren7.length; i++) ...[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 4 + (d.tren7[i] * 70),
                          decoration: BoxDecoration(
                            color: i == d.tren7.length - 1
                                ? hijau
                                : hijauMuda.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d.label7[i],
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i != d.tren7.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Rata-rata kegiatan terlapor per hari',
            style: TextStyle(color: Colors.black45, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _kartuBulanan(DataPengasuh d) {
    return KartuPutih(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konsistensi bulanan',
            style: TextStyle(color: hijauTua, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 90,
            width: double.infinity,
            child: CustomPaint(painter: _GarisPainter(d.bulanan)),
          ),
          const SizedBox(height: 8),
          const Text(
            '30 hari terakhir',
            style: TextStyle(color: Colors.black45, fontSize: 11),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardPengasuhBloc, DashboardPengasuhState>(
      builder: (context, s) {
        final d = s.data;
        final adaPengurus = d.totalPengurus > 0;

        return Scaffold(
          backgroundColor: krem,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _muatUlang(context),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
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

                  if (s.memuat)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: hijau),
                      ),
                    )
                  else if (s.error != null)
                    KartuPutih(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data gagal dimuat.',
                            style: TextStyle(
                              color: hijauTua,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.error!,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => context
                                .read<DashboardPengasuhBloc>()
                                .add(const DashboardPengasuhDimuat()),
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    )
                  else if (!adaPengurus) ...[
                    Row(
                      children: [
                        _kartuAngka(
                          label: 'Total Santri',
                          nilai: '${d.totalSantri}',
                          ikon: Icons.school_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const KartuPutih(
                      child: Text(
                        'Belum ada pengurus yang ditugaskan ke kamar.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        _kartuAngka(
                          label: 'Total Pengurus',
                          nilai: '${d.totalPengurus}',
                          ikon: Icons.groups_outlined,
                        ),
                        const SizedBox(width: 10),
                        _kartuAngka(
                          label: 'Total Santri',
                          nilai: '${d.totalSantri}',
                          ikon: Icons.school_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _kartuAngka(
                          label: 'Rata-rata Presensi',
                          nilai: '${d.rataRata}%',
                          ikon: Icons.trending_up,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _kartuKonsistensi(d),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _kartuPeringkat(
                          label: 'TERTINGGI',
                          nama: d.tertinggi,
                          nilai: '${d.persenTertinggi}%',
                          latar: hijauMuda.withValues(alpha: 0.2),
                          warnaNilai: hijau,
                        ),
                        const SizedBox(width: 10),
                        _kartuPeringkat(
                          label: 'TERENDAH',
                          nama: d.terendah,
                          nilai: '${d.persenTerendah}%',
                          latar: const Color(0xFFFDE8E8),
                          warnaNilai: Colors.red.shade600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _kartuTren7(d),
                    const SizedBox(height: 12),
                    _kartuBulanan(d),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Angka atas: hari ini, dari ${d.totalKegiatan} kegiatan aktif. '
                        'Grafik: rata-rata semua kamar.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
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
      },
    );
  }
}

class _GarisPainter extends CustomPainter {
  final List<double> data;

  const _GarisPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final garisDasar = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      garisDasar,
    );

    if (data.length < 2) return;

    final paint = Paint()
      ..color = hijau
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    for (int i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final y = size.height * (1 - data[i].clamp(0.0, 1.0));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GarisPainter oldDelegate) =>
      oldDelegate.data != data;
}