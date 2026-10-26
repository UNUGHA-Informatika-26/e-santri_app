import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/monitoring_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/dashboard_widgets.dart';
import 'detail_monitoring_page.dart';
import 'monitoring_service.dart';

Color warnaPersen(int p) {
  if (p >= 90) return hijau;
  if (p >= 80) return Colors.amber.shade700;
  return Colors.red.shade600;
}

Color latarPersen(int p) {
  if (p >= 90) return hijauMuda.withValues(alpha: 0.3);
  if (p >= 80) return const Color(0xFFFFE9A8);
  return const Color(0xFFFDE8E8);
}

class PilihanPeriode extends StatelessWidget {
  final List<String> label;
  final int terpilih;
  final ValueChanged<int> onPilih;

  const PilihanPeriode({
    super.key,
    required this.label,
    required this.terpilih,
    required this.onPilih,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < label.length; i++) ...[
            GestureDetector(
              onTap: () => onPilih(i),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: i == terpilih
                      ? hijauMuda.withValues(alpha: 0.35)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: i == terpilih ? hijau : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  label[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: i == terpilih ? hijauTua : Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class MonitoringPengasuhPage extends StatelessWidget {
  final String namaLengkap;

  /// true = dibuka dari Admin (menu bawah memakai menu Admin).
  final bool untukAdmin;

  const MonitoringPengasuhPage({
    super.key,
    this.namaLengkap = 'Pengasuh',
    this.untukAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MonitoringBloc>(
      create: (_) => MonitoringBloc(
        service: MonitoringService(),
        daftarJenis: const ['bulan', 'minggu', 'custom'],
      )..add(const MonitoringDimuat()),
      child: _Tampilan(namaLengkap: namaLengkap, untukAdmin: untukAdmin),
    );
  }
}

class _Tampilan extends StatelessWidget {
  final String namaLengkap;
  final bool untukAdmin;

  const _Tampilan({required this.namaLengkap, required this.untukAdmin});

  Future<void> _pilihPeriode(
    BuildContext context,
    MonitoringState s,
    int i,
  ) async {
    final bloc = context.read<MonitoringBloc>();

    if (i == 2) {
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
          2,
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

  String _judulRentang(MonitoringState s) {
    if (s.periode == 0) return MonitoringService.labelBulan(s.rentang.mulai);
    return '${MonitoringService.labelPendek(s.rentang.mulai)} - '
        '${MonitoringService.labelPendek(s.rentang.akhir)}';
  }

  Widget _ringkasan(MonitoringState s, HasilMonitoring h) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _judulRentang(s),
                  style: const TextStyle(
                    color: hijauTua,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${h.totalKegiatan} total kegiatan • ${h.totalLaporan} laporan',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${h.persenBulat}%',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _baris(BuildContext context, RingkasanKamar k) {
    final p = k.persenBulat;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailMonitoringPage(
            kamarId: k.kamarId,
            namaKamar: k.namaKamar,
            judul: k.judul,
            untukAdmin: untukAdmin,
          ),
        ),
      ),
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
                      'Kamar ${k.namaKamar}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '${k.total} kegiatan • ${k.laporan} laporan',
                      style: const TextStyle(
                        color: Colors.black45,
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
                    judul: 'Monitoring Pengurus',
                    subjudul: '${h?.kamar.length ?? 0} pengurus • read-only',
                    ikon: Icons.filter_list,
                    onIkon: () => tampilkanSegera(context, 'Filter'),
                  ),
                  const SizedBox(height: 12),
                  PilihanPeriode(
                    label: const ['Bulan Ini', 'Minggu Ini', 'Custom'],
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
                  else if (h == null || h.kamar.isEmpty)
                    const KartuPutih(
                      child: Text(
                        'Belum ada pengurus yang ditugaskan ke kamar.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  else ...[
                    _ringkasan(s, h),
                    const SizedBox(height: 12),
                    for (final k in h.kamar) _baris(context, k),
                  ],
                ],
              ),
            ),
          ),
          bottomNavigationBar: DashboardBottomNav(
            nama: namaLengkap,
            peran: untukAdmin ? 'Admin' : 'Pengasuh / Kyai',
            currentIndex: untukAdmin ? 3 : 1,
            onDashboard: () => Navigator.pop(context),
            menu: untukAdmin
                ? const [
                    NavItem(Icons.dashboard_outlined, 'Dashboard'),
                    NavItem(Icons.storage_outlined, 'Data'),
                    NavItem(Icons.fact_check_outlined, 'Presensi'),
                    NavItem(Icons.show_chart, 'Monitoring'),
                    NavItem(Icons.person_outline, 'Profil'),
                  ]
                : const [
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