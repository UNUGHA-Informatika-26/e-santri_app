import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'detail_pengurus_page.dart';
import 'pengurus_model.dart';
import 'pengurus_service.dart';

class DataPengurusPage extends StatefulWidget {
  const DataPengurusPage({super.key});

  @override
  State<DataPengurusPage> createState() => _DataPengurusPageState();
}

class _DataPengurusPageState extends State<DataPengurusPage> {
  final TextEditingController _cariController = TextEditingController();
  final PengurusService _service = PengurusService();

  List<DataPengurus> _pengurus = [];
  bool _memuat = true;
  String? _error;
  String _filter = 'semua'; // semua, bertugas, belum
  bool _urutNaik = true; // true = A-Z, false = Z-A

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _cariController.dispose();
    super.dispose();
  }

  // ============================================================
  // MUAT DATA
  // ============================================================

  Future<void> _muat() async {
    setState(() {
      _memuat = true;
      _error = null;
    });

    try {
      final data = await _service.ambilSemua();

      if (!mounted) {
        return;
      }

      setState(() {
        _pengurus = data;
        _memuat = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e is PengurusException
            ? e.pesan
            : 'Gagal memuat data pengurus. Tarik layar ke bawah untuk mencoba lagi.';
        _memuat = false;
      });
    }
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

  Future<void> _bukaDetail(DataPengurus p) async {
    final String? pesan = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => DetailPengurusPage(pengurus: p)),
    );

    if (!mounted) {
      return;
    }

    if (pesan != null) {
      _snackbar(pesan);
    }

    // Selalu muat ulang: kamar tugas bisa berubah dari halaman detail.
    await _muat();
  }

  // ============================================================
  // BANTUAN
  // ============================================================

  List<DataPengurus> _tersaring() {
    final String kata = _cariController.text.trim().toLowerCase();

    final hasil = _pengurus.where((p) {
      if (_filter == 'bertugas' && !p.sudahBertugas) {
        return false;
      }

      if (_filter == 'belum' && p.sudahBertugas) {
        return false;
      }

      if (kata.isEmpty) {
        return true;
      }

      return p.nama.toLowerCase().contains(kata) ||
          p.username.toLowerCase().contains(kata) ||
          p.email.toLowerCase().contains(kata);
    }).toList();

    hasil.sort(
      (a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()),
    );

    return _urutNaik ? hasil : hasil.reversed.toList();
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

  Widget _kartuPengurus(DataPengurus p) {
    final Color warna =
        p.sudahBertugas ? hijau : const Color(0xFFB7791F); // kuning tua

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _bukaDetail(p),
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
                  p.inisial,
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
                      p.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: hijauTua,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.username} • ${p.labelKamar}',
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
                  'Aktif',
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final tampil = _tersaring();

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
                          'Data Pengurus',
                          style: TextStyle(
                            color: hijauTua,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _memuat
                              ? 'Memuat…'
                              : '${_pengurus.length} pengurus aktif',
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cariController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cari nama, username, email…',
                        prefixIcon: const Icon(Icons.search, color: hijau),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 0),
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
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    tooltip: 'Filter',
                    onSelected: (nilai) {
                      setState(() {
                        _filter = nilai;
                      });
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'semua', child: Text('Semua')),
                      PopupMenuItem(
                        value: 'bertugas',
                        child: Text('Sudah bertugas'),
                      ),
                      PopupMenuItem(
                        value: 'belum',
                        child: Text('Belum ditugaskan'),
                      ),
                    ],
                    child: _kotakIkon(Icons.filter_list),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setState(() {
                        _urutNaik = !_urutNaik;
                      });
                    },
                    child: _kotakIkon(Icons.swap_vert),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _memuat
                  ? const Center(
                      child: CircularProgressIndicator(color: hijau),
                    )
                  : RefreshIndicator(
                      color: hijau,
                      onRefresh: _muat,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            )
                          else if (tampil.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                _pengurus.isEmpty
                                    ? 'Belum ada pengurus aktif. Pengurus muncul di sini setelah mendaftar dan disetujui di Manajemen Akun.'
                                    : 'Tidak ada pengurus yang cocok.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black54),
                              ),
                            )
                          else
                            for (final p in tampil) _kartuPengurus(p),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}