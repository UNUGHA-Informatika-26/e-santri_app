import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/presensi_admin_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/dashboard_widgets.dart';
import '../../pengasuh/monitoring/monitoring_service.dart';
import 'presensi_admin_service.dart';

class DetailPresensiAdminPage extends StatelessWidget {
  final DateTime tanggal;
  final LaporanKamar laporan;

  const DetailPresensiAdminPage({
    super.key,
    required this.tanggal,
    required this.laporan,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DetailPresensiAdminBloc>(
      create: (_) => DetailPresensiAdminBloc(
        service: PresensiAdminService(),
        tanggal: tanggal,
        kamarId: laporan.kamarId,
        kegiatanId: laporan.kegiatanId,
      )..add(const DetailPresensiAdminDimuat()),
      child: _Tampilan(tanggal: tanggal, laporan: laporan),
    );
  }
}

class _Tampilan extends StatelessWidget {
  final DateTime tanggal;
  final LaporanKamar laporan;

  const _Tampilan({required this.tanggal, required this.laporan});

  Future<void> _muatUlang(BuildContext context) async {
    final bloc = context.read<DetailPresensiAdminBloc>();
    bloc.add(const DetailPresensiAdminDimuat());
    await bloc.stream.firstWhere((s) => !s.memuat);
  }

  Color _warna(String s) {
    switch (s) {
      case 'hadir':
        return hijau;
      case 'izin':
        return Colors.blue.shade600;
      case 'sakit':
        return Colors.amber.shade800;
      default:
        return Colors.red.shade600;
    }
  }

  Color _latar(String s) {
    switch (s) {
      case 'hadir':
        return hijauMuda.withValues(alpha: 0.3);
      case 'izin':
        return Colors.blue.shade50;
      case 'sakit':
        return const Color(0xFFFFE9A8);
      default:
        return const Color(0xFFFDE8E8);
    }
  }

  String _huruf(String s) =>
      s.isEmpty ? '-' : s.substring(0, 1).toUpperCase() + s.substring(1);

  Widget _baris(String a, String b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            a,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          Flexible(
            child: Text(
              b,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuSantri(BarisSantri s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: KartuPutih(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: hijauMuda.withValues(alpha: 0.3),
                  child: Text(
                    inisialDari(s.nama),
                    style: const TextStyle(
                      color: hijauTua,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'NIS ${s.nis}',
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
                    color: _latar(s.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _huruf(s.status),
                    style: TextStyle(
                      color: _warna(s.status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (s.keterangan.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Keterangan: ${s.keterangan}',
                style: const TextStyle(color: Colors.black54, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = laporan;

    return BlocBuilder<DetailPresensiAdminBloc, DetailPresensiAdminState>(
      builder: (context, s) {
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
                              'Detail Presensi',
                              style: TextStyle(
                                color: hijauTua,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${l.namaKegiatan} • Kamar ${l.namaKamar}',
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
                  const SizedBox(height: 12),
                  BarisStatistik(
                    hadir: '${l.hadir}',
                    izin: '${l.izin}',
                    sakit: '${l.sakit}',
                    alfa: '${l.alfa}',
                  ),
                  const SizedBox(height: 12),
                  KartuPutih(
                    child: Column(
                      children: [
                        _baris(
                          'Tanggal',
                          MonitoringService.labelPendek(tanggal),
                        ),
                        _baris('Pengurus', l.pengurusTeks),
                        _baris('Total santri', '${l.total}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Daftar Santri',
                    style: TextStyle(
                      color: hijauTua,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                                .read<DetailPresensiAdminBloc>()
                                .add(const DetailPresensiAdminDimuat()),
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    )
                  else if (s.data.isEmpty)
                    const KartuPutih(
                      child: Text(
                        'Tidak ada data santri.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  else
                    for (final b in s.data) _kartuSantri(b),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}