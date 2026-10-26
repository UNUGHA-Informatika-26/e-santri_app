import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/monitoring_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/dashboard_widgets.dart';
import '../../pengasuh/monitoring/detail_monitoring_page.dart';
import '../../pengasuh/monitoring/monitoring_pengasuh_page.dart';
import '../../pengasuh/monitoring/monitoring_service.dart';

class MonitoringAdminPage extends StatelessWidget {
  final String namaLengkap;

  const MonitoringAdminPage({super.key, this.namaLengkap = 'Admin'});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MonitoringBloc>(
      create: (_) => MonitoringBloc(
        service: MonitoringService(),
        daftarJenis: const ['bulan'],
        denganTren: true,
      )..add(const MonitoringDimuat()),
      child: _Tampilan(namaLengkap: namaLengkap),
    );
  }
}

class _Tampilan extends StatelessWidget {
  final String namaLengkap;

  const _Tampilan({required this.namaLengkap});

  Future<void> _muatUlang(BuildContext context) async {
    final bloc = context.read<MonitoringBloc>();
    bloc.add(const MonitoringDimuat());
    await bloc.stream.firstWhere((s) => !s.memuat);
  }

  void _lihatSemua(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MonitoringPengasuhPage(
          namaLengkap: namaLengkap,
          untukAdmin: true,
        ),
      ),
    );
  }

  void _bukaDetail(BuildContext context, RingkasanKamar k) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailMonitoringPage(
          kamarId: k.kamarId,
          namaKamar: k.namaKamar,
          judul: k.judul,
          untukAdmin: true,
        ),
      ),
    );
  }

  Widget _chip(String teks) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        teks,
        style: const TextStyle(
          color: hijauTua,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _kartuAngka(String label, String nilai, Color warna) {
    return Expanded(
      child: KartuPutih(
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legenda(String teks, Color latar, Color warna) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        teks,
        style: TextStyle(
          color: warna,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _barisPerhatian(BuildContext context, RingkasanKamar k) {
    final p = k.persenBulat;

    return GestureDetector(
      onTap: () => _bukaDetail(context, k),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: KartuPutih(
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: hijauMuda.withValues(alpha: 0.3),
                child: Text(
                  k.inisial,
                  style: const TextStyle(
                    color: hijauTua,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      k.judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kamar ${k.namaKamar} • ${k.laporan}/${k.total} kegiatan',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: latarPersen(p),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$p%',
                  style: TextStyle(
                    color: warnaPersen(p),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _isi(BuildContext context, MonitoringState s, HasilMonitoring h) {
    final perhatian = h.kamar.where((k) => k.persenBulat < 80).toList()
      ..sort((a, b) => a.persen.compareTo(b.persen));
    final tampil = perhatian.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _kartuAngka('Pengurus', '${h.kamar.length}', hijau),
            const SizedBox(width: 10),
            _kartuAngka(
              'Rata-rata',
              '${h.persenBulat}%',
              Colors.blue.shade700,
            ),
          ],
        ),
        const SizedBox(height: 12),
        KartuPutih(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Konsistensi 7 hari',
                style: TextStyle(color: hijauTua, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 100,
                width: double.infinity,
                child: CustomPaint(painter: _GarisPainter(s.tren)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _legenda(
                    'Sudah presensi',
                    hijauMuda.withValues(alpha: 0.3),
                    hijauTua,
                  ),
                  const SizedBox(width: 8),
                  _legenda(
                    'Belum',
                    const Color(0xFFFDE8E8),
                    Colors.red.shade600,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        JudulBagian(
          judul: 'Perlu perhatian',
          aksi: 'Lihat semua',
          onAksi: () => _lihatSemua(context),
        ),
        const SizedBox(height: 10),
        if (tampil.isEmpty)
          const KartuPutih(
            child: Text(
              'Semua pengurus di atas 80% bulan ini.',
              style: TextStyle(color: Colors.black54),
            ),
          )
        else
          for (final k in tampil) _barisPerhatian(context, k),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monitoring Admin',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Admin dapat meninjau data dan membuka detail, tanpa '
                'mengubah data dari kartu monitoring.',
                style: TextStyle(color: Colors.black54, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MonitoringBloc, MonitoringState>(
      builder: (context, s) {
        final h = s.hasil;

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
                    judul: 'Monitoring',
                    subjudul: 'Kepatuhan presensi pengurus',
                    ikon: Icons.calendar_month_outlined,
                    onIkon: () => tampilkanSegera(context, 'Kalender'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _chip('ADMIN • MONITORING'),
                      GestureDetector(
                        onTap: () => tampilkanSegera(
                          context,
                          'Ringkasan operasional',
                        ),
                        child: const Text(
                          'Ringkasan operasional',
                          style: TextStyle(color: Colors.black54, fontSize: 11),
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
                          TextButton(
                            onPressed: () => context
                                .read<MonitoringBloc>()
                                .add(const MonitoringDimuat()),
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    )
                  else if (h == null || h.kamar.isEmpty)
                    const KartuPutih(
                      child: Text(
                        'Belum ada pengurus yang ditugaskan ke kamar.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  else
                    _isi(context, s, h),
                ],
              ),
            ),
          ),
          bottomNavigationBar: DashboardBottomNav(
            nama: namaLengkap,
            peran: 'Admin',
            currentIndex: 3,
            onDashboard: () => Navigator.pop(context),
            menu: const [
              NavItem(Icons.dashboard_outlined, 'Dashboard'),
              NavItem(Icons.storage_outlined, 'Data'),
              NavItem(Icons.fact_check_outlined, 'Presensi'),
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
    final dasar = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      dasar,
    );

    if (data.length < 2) return;

    final paint = Paint()
      ..color = hijau
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (var i = 0; i < data.length; i++) {
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