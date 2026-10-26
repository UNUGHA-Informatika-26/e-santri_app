import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/supabase/supabase_config.dart';
import 'kamar/data_kamar_page.dart';
import 'kegiatan/data_kegiatan_page.dart';
import 'pengurus/data_pengurus_page.dart';
import 'santri/data_santri_page.dart';

/// Halaman pilihan untuk tab Data: Santri, Kamar, Pengurus, atau Kegiatan.
class DataHubPage extends StatefulWidget {
  const DataHubPage({super.key});

  @override
  State<DataHubPage> createState() => _DataHubPageState();
}

class _DataHubPageState extends State<DataHubPage> {
  int? _jumlahSantri;
  int? _jumlahKamar;
  int? _jumlahPengurus;
  int? _jumlahKegiatan;

  @override
  void initState() {
    super.initState();
    _muatJumlah();
  }

  // Jumlah hanya pelengkap tampilan. Kalau gagal, teks ringkasan
  // tetap ditampilkan tanpa angka.
  Future<void> _muatJumlah() async {
    try {
      final data = await supabase.from('santri').select('id');

      if (!mounted) {
        return;
      }

      setState(() {
        _jumlahSantri = data.length;
      });
    } catch (_) {}

    try {
      final data = await supabase.from('kamar').select('id').eq('aktif', true);

      if (!mounted) {
        return;
      }

      setState(() {
        _jumlahKamar = data.length;
      });
    } catch (_) {}

    try {
      final data = await supabase
          .from('profiles')
          .select('id')
          .eq('role', 'pengurus')
          .eq('status', 'active');

      if (!mounted) {
        return;
      }

      setState(() {
        _jumlahPengurus = data.length;
      });
    } catch (_) {}

    try {
      final data =
          await supabase.from('kegiatan').select('id').eq('aktif', true);

      if (!mounted) {
        return;
      }

      setState(() {
        _jumlahKegiatan = data.length;
      });
    } catch (_) {}
  }

  Future<void> _bukaSantri() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DataSantriPage()),
    );

    // Jumlah bisa berubah setelah tambah/hapus di daftar santri.
    if (mounted) {
      _muatJumlah();
    }
  }

  Future<void> _bukaKamar() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DataKamarPage()),
    );

    if (mounted) {
      _muatJumlah();
    }
  }

  Future<void> _bukaPengurus() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DataPengurusPage()),
    );

    if (mounted) {
      _muatJumlah();
    }
  }

  Future<void> _bukaKegiatan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DataKegiatanPage()),
    );

    if (mounted) {
      _muatJumlah();
    }
  }

  Widget _kartuPilihan({
    required IconData ikon,
    required String judul,
    required String keterangan,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: hijauMuda.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(ikon, color: hijauTua, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: const TextStyle(
                      color: hijauTua,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    keterangan,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: hijau),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: krem,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: hijauTua),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data',
                          style: TextStyle(
                            color: hijauTua,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Kelola data pesantren',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _kartuPilihan(
                    ikon: Icons.groups_outlined,
                    judul: 'Data Santri',
                    keterangan: _jumlahSantri == null
                        ? 'Tambah, ubah, dan kelola santri'
                        : '$_jumlahSantri santri terdaftar',
                    onTap: _bukaSantri,
                  ),
                  const SizedBox(height: 12),
                  _kartuPilihan(
                    ikon: Icons.bed_outlined,
                    judul: 'Data Kamar',
                    keterangan: _jumlahKamar == null
                        ? 'Kelola kamar dan penghuninya'
                        : '$_jumlahKamar kamar aktif',
                    onTap: _bukaKamar,
                  ),
                  const SizedBox(height: 12),
                  _kartuPilihan(
                    ikon: Icons.badge_outlined,
                    judul: 'Data Pengurus',
                    keterangan: _jumlahPengurus == null
                        ? 'Atur pengurus dan kamar tugasnya'
                        : '$_jumlahPengurus pengurus aktif',
                    onTap: _bukaPengurus,
                  ),
                  const SizedBox(height: 12),
                  _kartuPilihan(
                    ikon: Icons.event_note_outlined,
                    judul: 'Data Kegiatan',
                    keterangan: _jumlahKegiatan == null
                        ? 'Kelola kegiatan untuk presensi'
                        : '$_jumlahKegiatan kegiatan aktif',
                    onTap: _bukaKegiatan,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}