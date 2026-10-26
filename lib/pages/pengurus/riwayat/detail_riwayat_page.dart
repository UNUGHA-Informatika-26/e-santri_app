import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/riwayat_pengurus_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/dashboard_widgets.dart';
import '../presensi/preview_whatsapp_page.dart';
import 'riwayat_format.dart';

class DetailRiwayatPage extends StatelessWidget {
  final String namaPengurus;
  final String namaKamar;
  final String kamarId;
  final String kegiatanId;
  final String namaKegiatan;
  final String tanggal;

  const DetailRiwayatPage({
    super.key,
    required this.namaPengurus,
    required this.namaKamar,
    required this.kamarId,
    required this.kegiatanId,
    required this.namaKegiatan,
    required this.tanggal,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DetailRiwayatBloc>(
      create: (_) => DetailRiwayatBloc(
        kamarId: kamarId,
        kegiatanId: kegiatanId,
        tanggal: tanggal,
      )..add(const DetailRiwayatDimuat()),
      child: _Tampilan(
        namaPengurus: namaPengurus,
        namaKamar: namaKamar,
        namaKegiatan: namaKegiatan,
        tanggal: tanggal,
      ),
    );
  }
}

class _Tampilan extends StatelessWidget {
  final String namaPengurus;
  final String namaKamar;
  final String namaKegiatan;
  final String tanggal;

  const _Tampilan({
    required this.namaPengurus,
    required this.namaKamar,
    required this.namaKegiatan,
    required this.tanggal,
  });

  Future<void> _muat(BuildContext context) async {
    final bloc = context.read<DetailRiwayatBloc>();
    bloc.add(const DetailRiwayatDimuat());
    await bloc.stream.firstWhere((s) => !s.memuat);
  }

  void _kirimUlang(BuildContext context, DetailRiwayatState s) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewWhatsappPage(
          tanggal: tanggalPanjang(tanggal, denganHari: true),
          kegiatan: namaKegiatan,
          kamar: namaKamar,
          pengurus: namaPengurus,
          hadir: s.hadir,
          izin: s.izin,
          sakit: s.sakit,
          alfa: s.alfa,
        ),
      ),
    );
  }

  Widget _barisInfo(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          Flexible(
            child: Text(
              nilai,
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

  Widget _lencanaStatus(String status) {
    Color latar;
    Color teks;
    String label;

    switch (status) {
      case 'izin':
        latar = Colors.blue.shade50;
        teks = Colors.blue.shade700;
        label = 'Izin';
        break;
      case 'sakit':
        latar = Colors.amber.shade50;
        teks = Colors.amber.shade800;
        label = 'Sakit';
        break;
      default:
        latar = Colors.red.shade50;
        teks = Colors.red.shade700;
        label = 'Alfa';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: teks,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _itemTidakHadir(SantriTidakHadir s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: KartuPutih(
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: hijauMuda.withValues(alpha: 0.3),
              child: Text(
                inisial(s.nama),
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
                    s.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'NIS ${s.nis} • ${s.keterangan}',
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
            _lencanaStatus(s.status),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DetailRiwayatBloc, DetailRiwayatState>(
      builder: (context, s) {
        return Scaffold(
          backgroundColor: krem,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _muat(context),
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
                              'Detail Riwayat',
                              style: TextStyle(
                                color: hijauTua,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$namaKegiatan • ${tanggalPanjang(tanggal)}',
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
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: hijauMuda.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _barisInfo('Kamar', namaKamar),
                          _barisInfo('Pengurus', namaPengurus),
                          _barisInfo('Waktu simpan', s.waktu),
                          _barisInfo('Status WhatsApp', 'Tersimpan'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    BarisStatistik(
                      hadir: '${s.hadir}',
                      izin: '${s.izin}',
                      sakit: '${s.sakit}',
                      alfa: '${s.alfa}',
                    ),
                    const SizedBox(height: 16),
                    JudulBagian(
                      judul: 'Tidak hadir',
                      aksi: '${s.tidakHadir.length} santri',
                    ),
                    const SizedBox(height: 10),
                    if (s.tidakHadir.isEmpty)
                      const KartuPutih(
                        child: Text(
                          'Semua santri hadir.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    else
                      for (final st in s.tidakHadir) _itemTidakHadir(st),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => _kirimUlang(context, s),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text(
                          'Kirim Ulang ke WhatsApp',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: hijau,
                          side: const BorderSide(color: hijau),
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
        );
      },
    );
  }
}