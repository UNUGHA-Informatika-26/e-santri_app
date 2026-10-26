import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/presensi_admin_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/dashboard_widgets.dart';
import '../../pengasuh/monitoring/monitoring_service.dart';
import 'detail_presensi_admin_page.dart';
import 'presensi_admin_service.dart';
import 'rekap_presensi_admin_page.dart';

class PresensiAdminPage extends StatelessWidget {
  final String namaLengkap;

  const PresensiAdminPage({super.key, this.namaLengkap = 'Admin'});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PresensiAdminBloc>(
      create: (_) => PresensiAdminBloc(service: PresensiAdminService())
        ..add(const PresensiAdminDimuat()),
      child: _Tampilan(namaLengkap: namaLengkap),
    );
  }
}

class _Tampilan extends StatelessWidget {
  final String namaLengkap;

  const _Tampilan({required this.namaLengkap});

  Future<void> _muatUlang(BuildContext context) async {
    final bloc = context.read<PresensiAdminBloc>();
    bloc.add(const PresensiAdminDimuat());
    await bloc.stream.firstWhere((s) => !s.memuat);
  }

  Future<void> _pilihTanggal(
    BuildContext context,
    PresensiAdminState s,
  ) async {
    final bloc = context.read<PresensiAdminBloc>();

    final dipilih = await showDatePicker(
      context: context,
      initialDate: s.tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (dipilih == null) return;

    bloc.add(PresensiAdminTanggalDipilih(dipilih));
  }

  void _bukaRekap(BuildContext context, PresensiAdminState s) {
    final h = s.hasil;
    if (h == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RekapPresensiAdminPage(
          hasil: h,
          kegiatanId: s.kegiatanId,
          kamarId: s.kamarId,
        ),
      ),
    );
  }

  Widget _kotak(String label, Widget isi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: isi,
        ),
      ],
    );
  }

  Widget _filter(BuildContext context, PresensiAdminState s) {
    final h = s.hasil!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _kotak(
                'Tanggal',
                InkWell(
                  onTap: () => _pilihTanggal(context, s),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          MonitoringService.labelPendek(s.tanggal),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: hijau,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kotak(
                'Kegiatan',
                DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: s.kegiatanId,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Semua'),
                      ),
                      for (final g in h.kegiatan)
                        DropdownMenuItem<String?>(
                          value: g.id,
                          child: Text(g.nama, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => context
                        .read<PresensiAdminBloc>()
                        .add(PresensiAdminKegiatanDipilih(v)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _kotak(
          'Kamar',
          DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: s.kamarId,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Semua kamar'),
                ),
                for (final k in h.kamar)
                  DropdownMenuItem<String?>(
                    value: k.id,
                    child: Text('Kamar ${k.nama}'),
                  ),
              ],
              onChanged: (v) => context
                  .read<PresensiAdminBloc>()
                  .add(PresensiAdminKamarDipilih(v)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _ringkasan(List<LaporanKamar> data) {
    final selesai = data.where((l) => l.selesai).length;
    final belum = data.length - selesai;
    final p = data.isEmpty ? 0.0 : selesai / data.length;

    Widget baris(String a, String b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                a,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              Text(
                b,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hijauMuda.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          baris('Total laporan', '${data.length}'),
          baris('Selesai', '$selesai'),
          baris('Belum', '$belum'),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: p,
              minHeight: 8,
              backgroundColor: Colors.white,
              color: hijau,
            ),
          ),
        ],
      ),
    );
  }

  Widget _barisLaporan(BuildContext context, PresensiAdminState s, LaporanKamar l) {
    final selesai = l.selesai;

    return GestureDetector(
      onTap: selesai
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailPresensiAdminPage(
                    tanggal: s.tanggal,
                    laporan: l,
                  ),
                ),
              )
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: KartuPutih(
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: hijauMuda.withValues(alpha: 0.3),
                child: Text(
                  inisialDari(l.namaKegiatan),
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
                      '${l.namaKegiatan} • ${l.namaKamar}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${MonitoringService.labelPendek(s.tanggal)} • '
                      '${l.pengurusTeks}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                  color: selesai
                      ? hijauMuda.withValues(alpha: 0.3)
                      : const Color(0xFFFFE9A8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  selesai ? '${l.total} santri' : 'Belum',
                  style: TextStyle(
                    color: selesai ? hijauTua : Colors.amber.shade800,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (selesai) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.black38),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PresensiAdminBloc, PresensiAdminState>(
      builder: (context, s) {
        final h = s.hasil;
        final data = s.tersaring;

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
                    judul: 'Presensi',
                    subjudul: 'Hasil presensi pengurus',
                    ikon: Icons.insights_outlined,
                    onIkon: () => _bukaRekap(context, s),
                  ),
                  const SizedBox(height: 12),
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
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ADMIN • PRESENSI',
                          style: TextStyle(
                            color: hijauTua,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Text(
                        'Hanya melihat',
                        style: TextStyle(color: Colors.black54, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (h != null) ...[
                    _filter(context, s),
                    const SizedBox(height: 12),
                  ],
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
                                .read<PresensiAdminBloc>()
                                .add(const PresensiAdminDimuat()),
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    )
                  else if (data.isEmpty)
                    const KartuPutih(
                      child: Text(
                        'Belum ada pengurus yang ditugaskan ke kamar.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  else ...[
                    _ringkasan(data),
                    const SizedBox(height: 12),
                    for (final l in data) _barisLaporan(context, s, l),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => _bukaRekap(context, s),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: hijau,
                          side: const BorderSide(color: hijau),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Rekap'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          bottomNavigationBar: DashboardBottomNav(
            nama: namaLengkap,
            peran: 'Admin',
            currentIndex: 2,
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