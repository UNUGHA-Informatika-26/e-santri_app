import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/kegiatan_bloc.dart';
import '../../../core/constants/app_colors.dart';
import 'form_kegiatan_page.dart';
import 'kegiatan_model.dart';
import 'kegiatan_service.dart';

class DataKegiatanPage extends StatelessWidget {
  const DataKegiatanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<KegiatanBloc>(
      create: (_) =>
          KegiatanBloc(service: KegiatanService())..add(const KegiatanDimuat()),
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
    final bloc = context.read<KegiatanBloc>();
    bloc.add(const KegiatanDimuat());
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

  Future<void> _bukaForm(BuildContext context, [Kegiatan? k]) async {
    final bloc = context.read<KegiatanBloc>();

    final String? pesan = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => FormKegiatanPage(kegiatan: k)),
    );

    if (!mounted) return;

    if (pesan != null) {
      _snackbar(pesan);
      bloc.add(const KegiatanDimuat());
    }
  }

  Widget _kotakIkon(IconData ikon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(ikon, color: hijauTua, size: 20),
    );
  }

  Widget _kartuKegiatan(BuildContext context, Kegiatan k) {
    final Color warna = k.aktif ? hijau : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _bukaForm(context, k),
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
                child: Text(
                  k.inisial,
                  style: const TextStyle(
                    color: hijauTua,
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
                      k.namaKegiatan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: hijauTua,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      k.labelDeskripsi,
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
    return BlocBuilder<KegiatanBloc, KegiatanState>(
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
                              'Data Kegiatan',
                              style: TextStyle(
                                color: hijauTua,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              s.memuat
                                  ? 'Memuat…'
                                  : '${s.kegiatan.length} kegiatan • ${s.jumlahAktif} aktif',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _bukaForm(context),
                        icon: const Icon(Icons.add, color: hijau),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cariController,
                          onChanged: (kata) => context
                              .read<KegiatanBloc>()
                              .add(KegiatanKataCariDiubah(kata)),
                          decoration: InputDecoration(
                            hintText: 'Cari kegiatan…',
                            prefixIcon: const Icon(Icons.search, color: hijau),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: hijau),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        tooltip: 'Filter',
                        onSelected: (nilai) => context
                            .read<KegiatanBloc>()
                            .add(KegiatanFilterDipilih(nilai)),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'semua', child: Text('Semua')),
                          PopupMenuItem(value: 'aktif', child: Text('Aktif')),
                          PopupMenuItem(
                            value: 'nonaktif',
                            child: Text('Nonaktif'),
                          ),
                        ],
                        child: _kotakIkon(Icons.filter_list),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => context
                            .read<KegiatanBloc>()
                            .add(const KegiatanUrutanDibalik()),
                        child: _kotakIkon(Icons.swap_vert),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
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
                                    s.kegiatan.isEmpty
                                        ? 'Belum ada kegiatan. Tambahkan kegiatan pertama lewat tombol di bawah.'
                                        : 'Tidak ada kegiatan yang cocok.',
                                    textAlign: TextAlign.center,
                                    style:
                                        const TextStyle(color: Colors.black54),
                                  ),
                                )
                              else
                                for (final k in tampil)
                                  _kartuKegiatan(context, k),
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
                      onPressed: () => _bukaForm(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hijau,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '+ Tambah Kegiatan',
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