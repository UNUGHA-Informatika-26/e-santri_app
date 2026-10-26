import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/kamar_bloc.dart';
import '../../../core/constants/app_colors.dart';
import 'detail_kamar_page.dart';
import 'form_kamar_page.dart';
import 'kamar_model.dart';
import 'kamar_service.dart';

class DataKamarPage extends StatelessWidget {
  const DataKamarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<KamarBloc>(
      create: (_) =>
          KamarBloc(service: KamarService())..add(const KamarDimuat()),
      child: const _Tampilan(),
    );
  }
}

class _Tampilan extends StatefulWidget {
  const _Tampilan();

  @override
  State<_Tampilan> createState() => _TampilanState();
}

class _TampilanState extends State<_Tampilan> {
  // Urusan tampilan saja: isi kolom cari. Teksnya dikirim ke Bloc.
  final TextEditingController _cariController = TextEditingController();

  @override
  void dispose() {
    _cariController.dispose();
    super.dispose();
  }

  Future<void> _muatUlang(BuildContext context) async {
    final bloc = context.read<KamarBloc>();
    bloc.add(const KamarDimuat());
    await bloc.stream.firstWhere((s) => !s.memuat);
  }

  void _snackbar(String pesan) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: hijau,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _tambah(BuildContext context) async {
    final bloc = context.read<KamarBloc>();

    final bool? berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FormKamarPage()),
    );

    if (berhasil == true && mounted) {
      _snackbar('Kamar ditambahkan.');
      bloc.add(const KamarDimuat());
    }
  }

  Future<void> _bukaDetail(BuildContext context, Kamar k) async {
    final bloc = context.read<KamarBloc>();

    final String? pesan = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => DetailKamarPage(kamar: k)),
    );

    if (!mounted) return;

    if (pesan != null) {
      _snackbar(pesan);
    }

    // Selalu muat ulang: jumlah penghuni bisa berubah dari halaman detail.
    bloc.add(const KamarDimuat());
  }

  Widget _chip(BuildContext context, KamarState s, String label, String nilai) {
    final bool terpilih = s.filter == nilai;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: terpilih,
        showCheckmark: false,
        selectedColor: hijau,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: terpilih ? Colors.white : hijauTua,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: terpilih ? hijau : Colors.grey.shade300,
        ),
        onSelected: (_) =>
            context.read<KamarBloc>().add(KamarFilterDipilih(nilai)),
      ),
    );
  }

  Widget _kartuKamar(BuildContext context, Kamar k) {
    final Color warna = k.aktif ? hijau : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _bukaDetail(context, k),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: hijauMuda.withValues(alpha: 0.3),
                child: const Icon(Icons.bed_outlined, color: hijauTua),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kamar ${k.namaKamar}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: hijauTua,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      k.labelPenghuni,
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
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: warna.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  k.aktif ? 'Aktif' : 'Nonaktif',
                  style: TextStyle(
                    color: warna,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KamarBloc, KamarState>(
      builder: (context, s) {
        final tampil = s.tersaring;

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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Data Kamar',
                              style: TextStyle(
                                color: hijauTua,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              s.memuat ? 'Memuat…' : '${s.kamar.length} kamar',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _tambah(context),
                        icon: const Icon(Icons.add, color: hijau),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _cariController,
                    onChanged: (kata) => context
                        .read<KamarBloc>()
                        .add(KamarKataCariDiubah(kata)),
                    decoration: InputDecoration(
                      hintText: 'Cari nama kamar',
                      prefixIcon: const Icon(Icons.search, color: hijau),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: hijau),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _chip(context, s, 'Semua', 'semua'),
                      _chip(context, s, 'Aktif', 'aktif'),
                      _chip(context, s, 'Nonaktif', 'nonaktif'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: s.memuat
                      ? const Center(
                          child: CircularProgressIndicator(color: hijau),
                        )
                      : RefreshIndicator(
                          color: hijau,
                          onRefresh: () => _muatUlang(context),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            children: [
                              if (s.error != null)
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    s.error!,
                                    textAlign: TextAlign.center,
                                    style:
                                        TextStyle(color: Colors.red.shade700),
                                  ),
                                )
                              else if (tampil.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Text(
                                    s.kamar.isEmpty
                                        ? 'Belum ada kamar. Tambahkan kamar pertama lewat tombol di bawah.'
                                        : 'Tidak ada kamar yang cocok.',
                                    textAlign: TextAlign.center,
                                    style:
                                        const TextStyle(color: Colors.black54),
                                  ),
                                )
                              else
                                for (final k in tampil) _kartuKamar(context, k),
                            ],
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _tambah(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hijau,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '+ Tambah Kamar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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