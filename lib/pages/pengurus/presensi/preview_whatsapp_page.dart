import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/whatsapp_preview_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/dashboard_widgets.dart';

class PreviewWhatsappPage extends StatelessWidget {
  final String tanggal;
  final String kegiatan;
  final String kamar;
  final String pengurus;
  final int hadir;
  final int izin;
  final int sakit;
  final int alfa;

  const PreviewWhatsappPage({
    super.key,
    required this.tanggal,
    required this.kegiatan,
    required this.kamar,
    required this.pengurus,
    required this.hadir,
    required this.izin,
    required this.sakit,
    required this.alfa,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WhatsappPreviewBloc>(
      create: (_) => WhatsappPreviewBloc(),
      child: _Tampilan(
        tanggal: tanggal,
        kegiatan: kegiatan,
        kamar: kamar,
        pengurus: pengurus,
        hadir: hadir,
        izin: izin,
        sakit: sakit,
        alfa: alfa,
      ),
    );
  }
}

class _Tampilan extends StatelessWidget {
  final String tanggal;
  final String kegiatan;
  final String kamar;
  final String pengurus;
  final int hadir;
  final int izin;
  final int sakit;
  final int alfa;

  const _Tampilan({
    required this.tanggal,
    required this.kegiatan,
    required this.kamar,
    required this.pengurus,
    required this.hadir,
    required this.izin,
    required this.sakit,
    required this.alfa,
  });

  int get _total => hadir + izin + sakit + alfa;

  String get _persenTeks {
    if (_total == 0) return '0%';
    return '${((hadir / _total) * 100).round()}%';
  }

  String get _pesan {
    return 'LAPORAN PRESENSI E-SANTRI\n'
        'Tanggal: $tanggal\n'
        'Kegiatan: $kegiatan\n'
        'Kamar: $kamar\n'
        'Pengurus: $pengurus\n'
        '\n'
        'Total Santri: $_total\n'
        'Hadir: $hadir\n'
        'Izin: $izin\n'
        'Sakit: $sakit\n'
        'Alfa: $alfa\n'
        'Persentase: $_persenTeks\n'
        '\n'
        'Data tersimpan di E-SANTRI.';
  }

  void _kirim(BuildContext context) {
    context.read<WhatsappPreviewBloc>().add(WhatsappPesanDikirim(_pesan));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WhatsappPreviewBloc, WhatsappPreviewState>(
      listenWhen: (prev, curr) => curr.pesanGagal != null,
      listener: (context, state) {
        if (state.pesanGagal != null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.pesanGagal!),
              backgroundColor: hijau,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: krem,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: hijauTua),
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preview WhatsApp',
                          style: TextStyle(
                            color: hijauTua,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Periksa sebelum dikirim',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                KartuPutih(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: hijau,
                        child: Icon(Icons.groups, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Grup WhatsApp Pengurus',
                              style: TextStyle(
                                color: hijauTua,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Pilih grup saat WhatsApp terbuka',
                              style: TextStyle(
                                color: Colors.black54,
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
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Preview',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: hijauMuda.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _pesan,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed:
                        state.sedangMengirim ? null : () => _kirim(context),
                    icon: state.sedangMengirim
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      state.sedangMengirim
                          ? 'Membuka...'
                          : 'Kirim Sekarang',
                      style: const TextStyle(
                        fontSize: 15,
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
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Kembali',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}