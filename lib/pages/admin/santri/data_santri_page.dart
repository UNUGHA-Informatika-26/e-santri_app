import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/santri_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/offline/antrean_santri.dart';
import 'detail_santri_page.dart';
import 'santri_model.dart';
import 'santri_service.dart';
import 'tambah_santri_page.dart';

class DataSantriPage extends StatelessWidget {
  const DataSantriPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SantriBloc>(
      create: (_) =>
          SantriBloc(service: SantriService())..add(const SantriDimuat()),
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
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _cariController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _muatUlang(BuildContext context) async {
    final bloc = context.read<SantriBloc>();
    bloc.add(const SantriDimuat());
    await bloc.stream.firstWhere((s) => !s.memuat);
  }

  void _keAtas() {
    if (_scroll.hasClients) {
      _scroll.jumpTo(0);
    }
  }

  void _snackbar(String pesan, {Color warna = hijau}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _tambah(BuildContext context) async {
    final bloc = context.read<SantriBloc>();

    final Object? hasil = await Navigator.push<Object>(
      context,
      MaterialPageRoute(builder: (_) => const TambahSantriPage()),
    );

    if (hasil == null || !mounted) return;

    if (hasil == 'antre') {
      _snackbar(
        'Tersimpan di HP. Belum ada koneksi, menunggu koneksi untuk dikirim.',
        warna: Colors.amber.shade800,
      );
    } else {
      _snackbar('Santri ditambahkan.');
    }

    bloc.add(const SantriDimuat());
  }
  Future<void> _bukaDetail(BuildContext context, Santri s) async {
    final bloc = context.read<SantriBloc>();

    final String? pesan = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => DetailSantriPage(santri: s)),
    );

    if (pesan != null && mounted) {
      _snackbar(pesan);
      bloc.add(const SantriDimuat());
    }
  }

  Widget _chip(BuildContext context, SantriState st, String label, String nilai) {
    final bool terpilih = st.filter == nilai;

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
        onSelected: (_) {
          context.read<SantriBloc>().add(SantriFilterDipilih(nilai));
          _keAtas();
        },
      ),
    );
  }

  Widget _kartuMenunggu(BuildContext context, ItemAntreanSantri m) {
    final Color warna =
        m.ditolak ? Colors.red.shade700 : Colors.amber.shade800;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: warna.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: warna.withValues(alpha: 0.15),
              child: Icon(
                m.ditolak ? Icons.error_outline : Icons.schedule,
                color: warna,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.namaLengkap,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: hijauTua,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.ditolak
                        ? 'NIS ${m.nis} \u2022 Ditolak: ${m.alasan ?? '-'}'
                        : 'NIS ${m.nis} \u2022 Menunggu koneksi untuk dikirim',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: warna, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (m.ditolak)
              IconButton(
                tooltip: 'Buang dari antrean',
                icon: const Icon(Icons.close, color: Colors.black45),
                onPressed: () async {
                  final bloc = context.read<SantriBloc>();
                  await AntreanSantri.hapus(m.nis);
                  if (mounted) bloc.add(const SantriDimuat());
                },
              ),
          ],
        ),
      ),
    );
  }
  Widget _kartuSantri(BuildContext context, Santri s) {
    final Color warna = s.statusAktif ? hijau : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _bukaDetail(context, s),
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
                  s.inisial,
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
                      s.namaLengkap,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: hijauTua,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIS ${s.nis} \u2022 ${s.labelGender} \u2022 ${s.labelKamar}',
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
                  s.statusAktif ? 'Aktif' : 'Nonaktif',
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

  /// Baris pilihan jumlah per halaman + tombol pindah halaman.
  Widget _barisHalaman(BuildContext context, SantriState st) {
    final int halaman = st.halamanAman;
    final int total = st.totalHalaman;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<int>(
              value: st.perHalaman,
              isDense: true,
              underline: const SizedBox.shrink(),
              iconEnabledColor: hijau,
              style: const TextStyle(
                color: hijauTua,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              items: [
                for (final n in pilihanPerHalaman)
                  DropdownMenuItem<int>(
                    value: n,
                    child: Text('$n / hal'),
                  ),
              ],
              onChanged: (nilai) {
                if (nilai == null) return;
                context.read<SantriBloc>().add(SantriPerHalamanDiubah(nilai));
                _keAtas();
              },
            ),
          ),
          Expanded(
            child: Text(
              'Halaman $halaman dari $total',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sebelumnya',
            onPressed: halaman > 1
                ? () {
                    context
                        .read<SantriBloc>()
                        .add(SantriHalamanDiubah(halaman - 1));
                    _keAtas();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
            color: hijau,
          ),
          IconButton(
            tooltip: 'Berikutnya',
            onPressed: halaman < total
                ? () {
                    context
                        .read<SantriBloc>()
                        .add(SantriHalamanDiubah(halaman + 1));
                    _keAtas();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
            color: hijau,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SantriBloc, SantriState>(
      builder: (context, st) {
        final tersaring = st.tersaring;
        final tampil = st.tampilHalaman;

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
                              'Data Santri',
                              style: TextStyle(
                                color: hijauTua,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              st.memuat
                                  ? 'Memuat\u2026'
                                  : '${st.santri.length} santri'
                                      '${st.offline ? ' \u2022 Offline' : ''}',
                              style: TextStyle(
                                color: st.offline
                                    ? Colors.amber.shade800
                                    : Colors.black54,
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
                    onChanged: (kata) {
                      context
                          .read<SantriBloc>()
                          .add(SantriKataCariDiubah(kata));
                      _keAtas();
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau NIS',
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
                      _chip(context, st, 'Semua', 'semua'),
                      _chip(context, st, 'Aktif', 'aktif'),
                      _chip(context, st, 'Nonaktif', 'nonaktif'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: st.memuat
                      ? const Center(
                          child: CircularProgressIndicator(color: hijau),
                        )
                      : RefreshIndicator(
                          color: hijau,
                          onRefresh: () => _muatUlang(context),
                          child: ListView(
                            controller: _scroll,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            children: [
                              if (st.error != null)
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    st.error!,
                                    textAlign: TextAlign.center,
                                    style:
                                        TextStyle(color: Colors.red.shade700),
                                  ),
                                )
                              else if (tampil.isEmpty && st.menunggu.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Text(
                                    st.santri.isEmpty
                                        ? 'Belum ada santri. Tambahkan santri pertama lewat tombol di bawah.'
                                        : 'Tidak ada santri yang cocok.',
                                    textAlign: TextAlign.center,
                                    style:
                                        const TextStyle(color: Colors.black54),
                                  ),
                                )
                              else ...[
                                for (final m in st.menunggu)
                                  _kartuMenunggu(context, m),
                                for (final s in tampil)
                                  _kartuSantri(context, s),
                              ],
                            ],
                          ),
                        ),
                ),
                if (!st.memuat && st.error == null && tersaring.isNotEmpty)
                  _barisHalaman(context, st),
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
                        '+ Tambah Santri',
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