import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/riwayat_pengurus_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/dashboard_widgets.dart';
import '../presensi/isi_presensi_page.dart';
import 'detail_riwayat_page.dart';
import 'riwayat_format.dart';

class RiwayatPengurusPage extends StatelessWidget {
  final String namaPengurus;

  const RiwayatPengurusPage({super.key, required this.namaPengurus});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RiwayatPengurusBloc>(
      create: (_) => RiwayatPengurusBloc()..add(const RiwayatPengurusDimuat()),
      child: _Tampilan(namaPengurus: namaPengurus),
    );
  }
}

class _Tampilan extends StatelessWidget {
  final String namaPengurus;

  const _Tampilan({required this.namaPengurus});

  Future<void> _muat(BuildContext context) async {
    final bloc = context.read<RiwayatPengurusBloc>();
    bloc.add(const RiwayatPengurusDimuat());
    await bloc.stream.firstWhere((s) => !s.memuat);
  }

  void _ubahFilter(BuildContext context, int index) {
    context.read<RiwayatPengurusBloc>().add(RiwayatPengurusFilterDiubah(index));
  }

  Future<void> _bukaDetail(
    BuildContext context,
    RiwayatPengurusState state,
    GrupRiwayat g,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailRiwayatPage(
          namaPengurus: namaPengurus,
          namaKamar: state.namaKamar ?? '-',
          kamarId: state.kamarId!,
          kegiatanId: g.kegiatanId,
          namaKegiatan: g.namaKegiatan,
          tanggal: g.tanggal,
        ),
      ),
    );
  }

  Widget _tabFilter(BuildContext context, String label, int index, int currentFilter) {
    final aktif = currentFilter == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _ubahFilter(context, index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: aktif
                ? hijauMuda.withValues(alpha: 0.3)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: aktif ? hijauTua : Colors.black54,
              fontSize: 12,
              fontWeight: aktif ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemRiwayat(
    BuildContext context,
    RiwayatPengurusState state,
    GrupRiwayat g,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _bukaDetail(context, state, g),
        child: KartuPutih(
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: hijauMuda.withValues(alpha: 0.3),
                child: Text(
                  inisial(g.namaKegiatan),
                  style: const TextStyle(
                    color: hijauTua,
                    fontSize: 12,
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
                      g.namaKegiatan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tanggalPendek(g.tanggal)} • ${g.hadir} hadir • ${g.persen}%',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Tersimpan',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
    return BlocBuilder<RiwayatPengurusBloc, RiwayatPengurusState>(
      builder: (context, s) {
        final adaKamar = s.kamarId != null;

        return Scaffold(
          backgroundColor: krem,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _muat(context),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  DashboardHeader(
                    judul: 'Riwayat Presensi',
                    subjudul: adaKamar ? 'Kamar ${s.namaKamar ?? '-'}' : '-',
                    ikon: Icons.filter_list,
                    onIkon: () => tampilkanSegera(context, 'Filter'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _tabFilter(context, 'Hari Ini', 0, s.filter),
                      _tabFilter(context, 'Minggu Ini', 1, s.filter),
                      _tabFilter(context, 'Bulan Ini', 2, s.filter),
                    ],
                  ),
                  const SizedBox(height: 14),
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
                            onPressed: () => _muat(context),
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    )
                  else if (!adaKamar)
                    const KartuPutih(
                      child: Text(
                        'Kamu belum ditugaskan ke kamar mana pun. '
                        'Minta Admin mengatur Kamar Tugas di Data Pengurus.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  else if (s.daftar.isEmpty)
                    const KartuPutih(
                      child: Text(
                        'Belum ada presensi pada rentang ini.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  else
                    for (final g in s.daftar) _itemRiwayat(context, s, g),
                ],
              ),
            ),
          ),
          bottomNavigationBar: DashboardBottomNav(
            nama: namaPengurus,
            peran: 'Pengurus',
            currentIndex: 2,
            onDashboard: () => Navigator.pop(context),
            onPresensi: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IsiPresensiPage(
                    namaPengurus: namaPengurus,
                  ),
                ),
              );
            },
            menu: const [
              NavItem(Icons.dashboard_outlined, 'Dashboard'),
              NavItem(Icons.fact_check_outlined, 'Presensi'),
              NavItem(Icons.history, 'Riwayat'),
              NavItem(Icons.person_outline, 'Profil'),
            ],
          ),
        );
      },
    );
  }
}