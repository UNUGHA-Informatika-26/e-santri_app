import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/dashboard_pengurus_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/dashboard_widgets.dart';
import 'presensi/isi_presensi_page.dart';
import 'riwayat/riwayat_pengurus_page.dart';

class PengurusDashboardPage extends StatelessWidget {
  final String namaLengkap;

  const PengurusDashboardPage({
    super.key,
    this.namaLengkap = 'Pengurus',
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardPengurusBloc>(
      create: (_) => DashboardPengurusBloc(service: DashboardPengurusService())
        ..add(const DashboardPengurusDimuat()),
      child: _Tampilan(namaLengkap: namaLengkap),
    );
  }
}

class _Tampilan extends StatelessWidget {
  final String namaLengkap;

  const _Tampilan({required this.namaLengkap});

  Future<void> _muatUlang(BuildContext context) async {
    final bloc = context.read<DashboardPengurusBloc>();
    bloc.add(const DashboardPengurusDimuat());
    await bloc.stream.firstWhere((s) => !s.memuat);
  }

  Future<void> _bukaIsiPresensi(BuildContext context) async {
    final bloc = context.read<DashboardPengurusBloc>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IsiPresensiPage(namaPengurus: namaLengkap),
      ),
    );

    bloc.add(const DashboardPengurusDimuat());
  }

  void _bukaRiwayat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiwayatPengurusPage(namaPengurus: namaLengkap),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardPengurusBloc, DashboardPengurusState>(
      builder: (context, s) {
        final d = s.data;
        final adaKamar = d.kamarId != null;
        final namaKamar = d.namaKamar ?? '-';

        final totalTercatat = d.hadir + d.izin + d.sakit + d.alfa;
        final persen = totalTercatat == 0 ? 0.0 : d.hadir / totalTercatat;
        final persenTeks = '${(persen * 100).round()}%';

        final subjudul = adaKamar
            ? 'Pengurus Kamar $namaKamar'
            : 'Belum ditugaskan ke kamar';

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
                    judul: 'Assalamu\'alaikum, $namaLengkap',
                    subjudul: subjudul,
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
                              Text(
                                adaKamar
                                    ? 'Kamar Tugas • $namaKamar'
                                    : 'Kamar Tugas • Belum ditugaskan',
                                style: const TextStyle(
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
                          child: Text(
                            '${d.jumlahSantri} Santri',
                            style: const TextStyle(
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
                                .read<DashboardPengurusBloc>()
                                .add(const DashboardPengurusDimuat()),
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
                  else ...[
                    const JudulBagian(judul: 'Presensi hari ini'),

                    const SizedBox(height: 10),

                    BarisStatistik(
                      hadir: '${d.hadir}',
                      izin: '${d.izin}',
                      sakit: '${d.sakit}',
                      alfa: '${d.alfa}',
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PERSENTASE HADIR',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 11,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    persenTeks,
                                    style: const TextStyle(
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
                            child: LinearProgressIndicator(
                              value: persen,
                              minHeight: 8,
                              color: hijau,
                              backgroundColor: Colors.white,
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
                        onPressed: () => _bukaIsiPresensi(context),
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
                  ],
                ],
              ),
            ),
          ),
          bottomNavigationBar: DashboardBottomNav(
            nama: namaLengkap,
            peran: 'Pengurus',
            onPresensi: () => _bukaIsiPresensi(context),
            onRiwayat: () => _bukaRiwayat(context),
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