import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../widgets/dashboard_widgets.dart';
import 'presensi_penanda.dart';
import 'preview_whatsapp_page.dart';

class PresensiBerhasilPage extends StatelessWidget {
  final String tanggal;
  final String kegiatan;
  final String kamar;
  final String pengurus;
  final int hadir;
  final int izin;
  final int sakit;
  final int alfa;

  /// true = tersimpan di HP, menunggu internet untuk dikirim.
  final bool menunggu;

  const PresensiBerhasilPage({
    super.key,
    required this.tanggal,
    required this.kegiatan,
    required this.kamar,
    required this.pengurus,
    required this.hadir,
    required this.izin,
    required this.sakit,
    required this.alfa,
    this.menunggu = false,
  });

  int get _total => hadir + izin + sakit + alfa;

  double get _persen => _total == 0 ? 0.0 : hadir / _total;

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

  void _selesai(BuildContext context) {
    tandaiPresensiSelesai();
    Navigator.pop(context, true);
  }

  void _bukaPreview(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewWhatsappPage(
          tanggal: tanggal,
          kegiatan: kegiatan,
          kamar: kamar,
          pengurus: pengurus,
          hadir: hadir,
          izin: izin,
          sakit: sakit,
          alfa: alfa,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final persenTeks = '${(_persen * 100).round()}%';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _selesai(context);
      },
      child: Scaffold(
        backgroundColor: krem,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _selesai(context),
                    icon: const Icon(Icons.arrow_back, color: hijauTua),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Presensi Berhasil',
                        style: TextStyle(
                          color: hijauTua,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        menunggu
                            ? 'Menunggu internet untuk dikirim'
                            : 'Data telah tersimpan',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: hijau,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Presensi Berhasil',
                  style: TextStyle(
                    color: hijauTua,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              KartuPutih(
                child: Column(
                  children: [
                    _baris('Tanggal', tanggal),
                    _baris('Kegiatan', kegiatan),
                    _baris('Kamar', kamar),
                    _baris('Pengurus', pengurus),
                    _baris('Total', '$_total santri'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              BarisStatistik(
                hadir: '$hadir',
                izin: '$izin',
                sakit: '$sakit',
                alfa: '$alfa',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: hijauMuda.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Persentase Kehadiran',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          persenTeks,
                          style: const TextStyle(
                            color: hijauTua,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _persen,
                        minHeight: 8,
                        color: hijau,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (menunggu) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE9A8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Tidak ada internet. Presensi tersimpan di HP dan akan '
                    'dikirim otomatis saat internet kembali.',
                    style: TextStyle(color: Colors.black87, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _bukaPreview(context),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text(
                    'Kirim ke Grup WhatsApp Pengurus',
                    style: TextStyle(
                      fontSize: 14,
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
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => _selesai(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: hijau,
                    side: const BorderSide(color: hijau),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}