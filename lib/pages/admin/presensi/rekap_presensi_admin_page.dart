import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../widgets/dashboard_widgets.dart';
import '../../pengasuh/monitoring/monitoring_pengasuh_page.dart';
import '../../pengasuh/monitoring/monitoring_service.dart';
import 'presensi_admin_service.dart';

class RekapPresensiAdminPage extends StatelessWidget {
  final HasilPresensiHari hasil;
  final String? kegiatanId;
  final String? kamarId;

  const RekapPresensiAdminPage({
    super.key,
    required this.hasil,
    this.kegiatanId,
    this.kamarId,
  });

  double _persenHadir(Iterable<LaporanKamar> data) {
    var hadir = 0;
    var total = 0;
    for (final l in data) {
      hadir += l.hadir;
      total += l.total;
    }
    return total == 0 ? 0.0 : hadir / total;
  }

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

  @override
  Widget build(BuildContext context) {
    final data = hasil.laporan
        .where(
          (l) =>
              (kegiatanId == null || l.kegiatanId == kegiatanId) &&
              (kamarId == null || l.kamarId == kamarId),
        )
        .toList();

    final selesai = data.where((l) => l.selesai).toList();

    var hadir = 0;
    var izin = 0;
    var sakit = 0;
    var alfa = 0;
    for (final l in selesai) {
      hadir += l.hadir;
      izin += l.izin;
      sakit += l.sakit;
      alfa += l.alfa;
    }
    final totalSantri = hadir + izin + sakit + alfa;
    final persen = _persenHadir(selesai);

    final namaKegiatan = kegiatanId == null
        ? 'Semua kegiatan'
        : hasil.kegiatan.firstWhere((g) => g.id == kegiatanId).nama;

    final daftarKegiatan = kegiatanId == null
        ? hasil.kegiatan
        : hasil.kegiatan.where((g) => g.id == kegiatanId).toList();

    final daftarKamar = kamarId == null
        ? hasil.kamar
        : hasil.kamar.where((k) => k.id == kamarId).toList();

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rekap Presensi',
                        style: TextStyle(
                          color: hijauTua,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        MonitoringService.labelPendek(hasil.tanggal),
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
              hadir: '$hadir',
              izin: '$izin',
              sakit: '$sakit',
              alfa: '$alfa',
            ),
            const SizedBox(height: 12),
            KartuPutih(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _baris('Kegiatan', namaKegiatan),
                  _baris('Laporan masuk', '${selesai.length} dari ${data.length}'),
                  _baris('Total santri', '$totalSantri'),
                  _baris(
                    'Persentase hadir',
                    '${(persen * 100).toStringAsFixed(1)}%',
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 120,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final g in daftarKegiatan)
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: 4 +
                                      _persenHadir(
                                            selesai.where(
                                              (l) => l.kegiatanId == g.id,
                                            ),
                                          ) *
                                          90,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hijau,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  inisialDari(g.nama),
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Per kamar',
              style: TextStyle(
                color: hijauTua,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (daftarKamar.isEmpty)
              const KartuPutih(
                child: Text(
                  'Belum ada kamar.',
                  style: TextStyle(color: Colors.black54),
                ),
              )
            else
              for (final k in daftarKamar)
                Builder(
                  builder: (_) {
                    final lapKamar =
                        selesai.where((l) => l.kamarId == k.id).toList();
                    var h = 0;
                    var t = 0;
                    for (final l in lapKamar) {
                      h += l.hadir;
                      t += l.total;
                    }
                    final p = t == 0 ? 0 : (h / t * 100).round();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: KartuPutih(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kamar ${k.nama}',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    t == 0
                                        ? 'Belum presensi'
                                        : '$h/$t hadir',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$p%',
                              style: TextStyle(
                                color: t == 0
                                    ? Colors.red.shade600
                                    : warnaPersen(p),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}