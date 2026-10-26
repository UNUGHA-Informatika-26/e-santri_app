import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/monitoring_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/dashboard_widgets.dart';
import 'monitoring_pengasuh_page.dart';
import 'monitoring_service.dart';

class DetailMonitoringPage extends StatelessWidget {
  final String kamarId;
  final String namaKamar;
  final String judul;

  /// true = dibuka dari Admin (hanya mengubah teks hak akses).
  final bool untukAdmin;

  const DetailMonitoringPage({
    super.key,
    required this.kamarId,
    required this.namaKamar,
    required this.judul,
    this.untukAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MonitoringBloc>(
      create: (_) => MonitoringBloc(
        service: MonitoringService(),
        daftarJenis: const ['hari', 'minggu', 'bulan', 'tahun', 'custom'],
        periodeAwal: 2, // Bulan Ini
      )..add(const MonitoringDimuat()),
      child: _Tampilan(
        kamarId: kamarId,
        namaKamar: namaKamar,
        judul: judul,
        untukAdmin: untukAdmin,
      ),
    );
  }
}

class _Tampilan extends StatelessWidget {
  final String kamarId;
  final String namaKamar;
  final String judul;
  final bool untukAdmin;

  const _Tampilan({
    required this.kamarId,
    required this.namaKamar,
    required this.judul,
    required this.untukAdmin,
  });

  Future<void> _pilihPeriode(
    BuildContext context,
    MonitoringState s,
    int i,
  ) async {
    final bloc = context.read<MonitoringBloc>();

    if (i == 4) {
      final hasil = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: DateTimeRange(
          start: s.rentang.mulai,
          end: s.rentang.akhir,
        ),
      );
      if (hasil == null) return;

      bloc.add(
        MonitoringPeriodeDipilih(
          4,
          custom: Rentang(
            DateTime(hasil.start.year, hasil.start.month, hasil.start.day),
            DateTime(hasil.end.year, hasil.end.month, hasil.end.day),
          ),
        ),
      );
    } else {
      bloc.add(MonitoringPeriodeDipilih(i));
    }
  }

  Future<void> _muatUlang(BuildContext context) async {
    final bloc = context.read<MonitoringBloc>();
    bloc.add(const MonitoringDimuat());
    await bloc.stream.firstWhere((s) => !s.memuat);
  }

  /// Ratakan data menjadi paling banyak [maks] titik.
  List<double> _ringkas(List<double> d, int maks) {
    if (d.length <= maks) return d;

    final ukuran = (d.length / maks).ceil();
    final hasil = <double>[];

    for (var i = 0; i < d.length; i += ukuran) {
      final akhir = i + ukuran > d.length ? d.length : i + ukuran;
      final potong = d.sublist(i, akhir);
      hasil.add(potong.reduce((a, b) => a + b) / potong.length);
    }

    return hasil;
  }

  Widget _baris(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          Text(
            nilai,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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

  Widget _isi(RingkasanKamar d, Rentang rentang) {
    final p = d.persenBulat;
    final belum = d.total - d.laporan;

    final batang = _ringkas(d.perHari, 14);
    final garis = _ringkas(d.perHari, 30);

    final periodeTeks = rentang.mulai == rentang.akhir
        ? MonitoringService.labelPendek(rentang.mulai)
        : '${MonitoringService.labelPendek(rentang.mulai)} - '
            '${MonitoringService.labelPendek(rentang.akhir)}';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hijauMuda.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: hijauTua,
                child: Text(
                  d.inisial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: hijauTua,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Kamar ${d.namaKamar}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$p%',
                style: TextStyle(
                  color: warnaPersen(p),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        KartuPutih(
          child: Column(
            children: [
              _baris('Periode', periodeTeks),
              _baris('Total Kegiatan', '${d.total}'),
              _baris('Sudah Presensi', '${d.laporan}'),
              _baris('Belum Presensi', '$belum'),
              _baris('Persentase', '$p%'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        KartuPutih(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Grafik aktivitas',
                style: TextStyle(color: hijauTua, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < batang.length; i++) ...[
                      Expanded(
                        child: Container(
                          height: 4 + batang[i] * 90,
                          decoration: BoxDecoration(
                            color: i == batang.length - 1
                                ? hijau
                                : hijauMuda.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      if (i != batang.length - 1) const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _legenda(
                    'Sudah',
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
        const SizedBox(height: 12),
        KartuPutih(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tren konsistensi',
                style: TextStyle(color: hijauTua, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 90,
                width: double.infinity,
                child: CustomPaint(painter: _GarisPainter(garis)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            untukAdmin
                ? 'Data hanya dapat dilihat sesuai hak akses Admin.'
                : 'Data hanya dapat dilihat sesuai hak akses Pengasuh / Kyai.',
            style: const TextStyle(color: Colors.black45, fontSize: 11),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MonitoringBloc, MonitoringState>(
      builder: (context, s) {
        RingkasanKamar? d;
        for (final k in s.hasil?.kamar ?? const <RingkasanKamar>[]) {
          if (k.kamarId == kamarId) d = k;
        }

        return Scaffold(
          backgroundColor: krem,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _muatUlang(context),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: hijauTua),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detail Monitoring',
                              style: TextStyle(
                                color: hijauTua,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$judul • Kamar $namaKamar',
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  PilihanPeriode(
                    label: const [
                      'Hari Ini',
                      'Minggu Ini',
                      'Bulan Ini',
                      'Tahun Ini',
                      'Custom',
                    ],
                    terpilih: s.periode,
                    onPilih: (i) => _pilihPeriode(context, s, i),
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
                  else if (d == null)
                    const KartuPutih(
                      child: Text(
                        'Data kamar ini tidak ditemukan.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  else
                    _isi(d, s.rentang),
                ],
              ),
            ),
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