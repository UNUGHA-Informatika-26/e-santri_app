import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/kamar_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../santri/detail_santri_page.dart';
import 'form_kamar_page.dart';
import 'kamar_model.dart';
import 'kamar_service.dart';
import '../santri/santri_model.dart';

/// Detail kamar + daftar penghuni. Perubahan (edit / status / hapus)
/// menutup halaman ini dengan hasil berupa pesan String.
class DetailKamarPage extends StatelessWidget {
  final Kamar kamar;

  const DetailKamarPage({super.key, required this.kamar});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DetailKamarBloc>(
      create: (_) => DetailKamarBloc(service: KamarService(), kamar: kamar)
        ..add(const DetailKamarPenghuniDimuat()),
      child: _Tampilan(kamar: kamar),
    );
  }
}

class _Tampilan extends StatelessWidget {
  final Kamar kamar;

  const _Tampilan({required this.kamar});

  // ============================================================
  // AKSI
  // ============================================================

  Future<void> _bukaSantri(BuildContext context, Santri s) async {
    final bloc = context.read<DetailKamarBloc>();

    final String? pesan = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => DetailSantriPage(santri: s)),
    );

    if (pesan == null || !context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: hijau,
        behavior: SnackBarBehavior.floating,
      ),
    );

    bloc.add(const DetailKamarPenghuniDimuat());
  }

  Future<void> _edit(BuildContext context) async {
    final bool? berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FormKamarPage(kamar: kamar)),
    );

    if (berhasil == true && context.mounted) {
      Navigator.pop(context, 'Perubahan disimpan.');
    }
  }

  Future<void> _ubahStatus(BuildContext context) async {
    final bloc = context.read<DetailKamarBloc>();

    if (kamar.aktif) {
      final ya = await _konfirmasi(
        context,
        judul: 'Nonaktifkan kamar?',
        isi:
            'Kamar ${kamar.namaKamar} tidak akan muncul sebagai pilihan saat menambah santri. Santri yang sudah di dalamnya tidak berubah.',
        labelYa: 'Nonaktifkan',
      );

      if (!ya) return;
    }

    bloc.add(const DetailKamarStatusDitekan());
  }

  Future<void> _hapus(BuildContext context) async {
    final bloc = context.read<DetailKamarBloc>();

    final ya = await _konfirmasi(
      context,
      judul: 'Hapus kamar?',
      isi:
          'Kamar ${kamar.namaKamar} akan dihapus permanen dan tidak bisa dikembalikan. Kamar yang masih dihuni tidak bisa dihapus.',
      labelYa: 'Hapus',
      bahaya: true,
    );

    if (!ya) return;

    bloc.add(const DetailKamarHapusDitekan());
  }

  Future<bool> _konfirmasi(
    BuildContext context, {
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

  void _tanganiState(BuildContext context, DetailKamarState s) {
    final selesai = s.selesai;
    if (selesai != null) {
      Navigator.pop(context, selesai);
      return;
    }

    final error = s.error;
    if (error != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // TAMPILAN
  // ============================================================

  Widget _baris(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(nilai)),
        ],
      ),
    );
  }

  Widget _daftarPenghuni(BuildContext context, DetailKamarState s) {
    if (s.memuat) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(color: hijau)),
      );
    }

    if (s.gagalMuat) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              'Gagal memuat penghuni.',
              style: TextStyle(color: Colors.red.shade700),
            ),
            TextButton(
              onPressed: () => context
                  .read<DetailKamarBloc>()
                  .add(const DetailKamarPenghuniDimuat()),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    if (s.penghuni.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          'Belum ada santri di kamar ini. Atur kamar lewat Edit pada data santri.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Column(
      children: [
        for (final santri in s.penghuni)
          ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () => _bukaSantri(context, santri),
            leading: CircleAvatar(
              backgroundColor: hijauMuda.withValues(alpha: 0.3),
              child: Text(
                santri.inisial,
                style: const TextStyle(
                  color: hijauTua,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              santri.namaLengkap,
              style: const TextStyle(
                color: hijauTua,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'NIS ${santri.nis} • ${santri.statusAktif ? 'Aktif' : 'Nonaktif'}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.black38),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DetailKamarBloc, DetailKamarState>(
      listenWhen: (a, b) => b.selesai != null || b.error != null,
      listener: _tanganiState,
      builder: (context, s) {
        final aktif = kamar.aktif;
        final jumlah =
            s.memuat || s.gagalMuat ? kamar.jumlahPenghuni : s.penghuni.length;

        return Scaffold(
          appBar: AppBar(title: const Text('Detail Kamar')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: hijauMuda.withValues(alpha: 0.3),
                      child: const Icon(
                        Icons.bed_outlined,
                        size: 40,
                        color: hijauTua,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kamar ${kamar.namaKamar}',
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Kamar',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(height: 24),
                      _baris('Nama kamar', kamar.namaKamar),
                      _baris('Status', aktif ? 'Aktif' : 'Nonaktif'),
                      _baris('Penghuni', '$jumlah santri'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Penghuni',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(height: 24),
                      _daftarPenghuni(context, s),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: s.bekerja ? null : () => _edit(context),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text(
                    'Edit Nama Kamar',
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
                  onPressed: s.bekerja ? null : () => _ubahStatus(context),
                  icon: Icon(aktif ? Icons.block : Icons.check_circle_outline),
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
                onPressed: s.bekerja ? null : () => _hapus(context),
                icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                label: Text(
                  'Hapus kamar',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
              if (s.bekerja)
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
      },
    );
  }
}