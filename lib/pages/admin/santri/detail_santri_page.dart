import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'santri_model.dart';
import 'santri_service.dart';
import 'tambah_santri_page.dart';

/// Detail santri. Kalau ada perubahan (edit / status / hapus), halaman ini
/// ditutup dengan hasil berupa pesan String, supaya daftar memuat ulang.
class DetailSantriPage extends StatefulWidget {
  final Santri santri;

  const DetailSantriPage({super.key, required this.santri});

  @override
  State<DetailSantriPage> createState() => _DetailSantriPageState();
}

class _DetailSantriPageState extends State<DetailSantriPage> {
  final SantriService _service = SantriService();
  bool _bekerja = false;

  Santri get _s => widget.santri;

  // ============================================================
  // AKSI
  // ============================================================

  Future<void> _edit() async {
    final bool? berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TambahSantriPage(santri: _s)),
    );

    if (berhasil == true && mounted) {
      Navigator.pop(context, 'Perubahan disimpan.');
    }
  }

  Future<void> _ubahStatus() async {
    final bool jadiNonaktif = _s.statusAktif;

    if (jadiNonaktif) {
      final ya = await _konfirmasi(
        judul: 'Nonaktifkan santri?',
        isi:
            '${_s.namaLengkap} akan ditandai nonaktif. Datanya tetap tersimpan dan bisa diaktifkan kembali.',
        labelYa: 'Nonaktifkan',
      );

      if (!ya) {
        return;
      }
    }

    await _jalankan(
      () => _service.ubahStatusAktif(_s.id, !_s.statusAktif),
      jadiNonaktif ? 'Santri dinonaktifkan.' : 'Santri diaktifkan kembali.',
    );
  }

  Future<void> _hapus() async {
    final ya = await _konfirmasi(
      judul: 'Hapus permanen?',
      isi:
          '${_s.namaLengkap} akan dihapus dari database dan tidak bisa dikembalikan. '
          'Kalau santri hanya sudah keluar atau lulus, pilih Nonaktifkan saja.',
      labelYa: 'Hapus',
      bahaya: true,
    );

    if (!ya) {
      return;
    }

    await _jalankan(() => _service.hapus(_s.id), 'Santri dihapus.');
  }

  Future<void> _jalankan(
    Future<void> Function() aksi,
    String pesanSukses,
  ) async {
    if (_bekerja) {
      return;
    }

    setState(() {
      _bekerja = true;
    });

    try {
      await aksi();

      if (!mounted) {
        return;
      }

      Navigator.pop(context, pesanSukses);
    } on SantriException catch (e) {
      if (!mounted) {
        return;
      }

      _tampilkanError(e.pesan);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _tampilkanError('Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() {
          _bekerja = false;
        });
      }
    }
  }

  Future<bool> _konfirmasi({
    required String judul,
    required String isi,
    required String labelYa,
    bool bahaya = false,
  }) async {
    final hasil = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(judul),
        content: Text(isi),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              labelYa,
              style: TextStyle(
                color: bahaya ? Colors.red.shade700 : hijauTua,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return hasil == true;
  }

  void _tampilkanError(String pesan) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _gender(String g) {
    switch (g) {
      case 'putra':
        return 'Putra (L)';
      case 'putri':
        return 'Putri (P)';
      default:
        return '-';
    }
  }

  // ============================================================
  // TAMPILAN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final aktif = _s.statusAktif;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Santri')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  child: Text(
                    _s.inisial,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _s.namaLengkap,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(aktif ? 'Aktif' : 'Nonaktif'),
                  backgroundColor: aktif
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _Section(
            title: 'Data Santri',
            rows: [
              _Row('NIS', _s.nis),
              _Row('Jenis Kelamin', _gender(_s.gender)),
              _Row('Kamar', _s.labelKamar),
              _Row('Alamat', _s.alamat),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Kontak Wali',
            rows: [
              _Row('No. HP Wali', _s.noHp),
            ],
          ),

          const SizedBox(height: 24),

          // Aksi
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _bekerja ? null : _edit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text(
                'Edit Data',
                style: TextStyle(fontWeight: FontWeight.bold),
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
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _bekerja ? null : _ubahStatus,
              icon: Icon(
                aktif ? Icons.block : Icons.check_circle_outline,
              ),
              label: Text(
                aktif ? 'Nonaktifkan' : 'Aktifkan kembali',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: hijauTua,
                side: const BorderSide(color: hijau),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: _bekerja ? null : _hapus,
            icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
            label: Text(
              'Hapus permanen',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),

          if (_bekerja)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                child: CircularProgressIndicator(color: hijau),
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Row {
  final String label;
  final String? value;
  const _Row(this.label, this.value);
}

class _Section extends StatelessWidget {
  final String title;
  final List<_Row> rows;

  const _Section({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: 24),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        r.label,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        (r.value == null || r.value!.isEmpty) ? '-' : r.value!,
                      ),
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