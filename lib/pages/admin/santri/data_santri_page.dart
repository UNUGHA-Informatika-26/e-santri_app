import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'detail_santri_page.dart';
import 'santri_model.dart';
import 'santri_service.dart';
import 'tambah_santri_page.dart';

class DataSantriPage extends StatefulWidget {
  const DataSantriPage({super.key});

  @override
  State<DataSantriPage> createState() => _DataSantriPageState();
}

class _DataSantriPageState extends State<DataSantriPage> {
  final TextEditingController _cariController = TextEditingController();
  final SantriService _service = SantriService();

  List<Santri> _santri = [];
  bool _memuat = true;
  String? _error;
  String _filter = 'semua'; // semua, aktif, nonaktif

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
        _santri = data;
        _memuat = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error =
            'Gagal memuat data santri. Tarik layar ke bawah untuk mencoba lagi.';
        _memuat = false;
      });
    }
  }

  // ============================================================
  // TAMBAH SANTRI
  // ============================================================

  Future<void> _tambah() async {
    final bool? berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TambahSantriPage()),
    );

    if (berhasil == true && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Santri ditambahkan.'),
          backgroundColor: hijau,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _muat();
    }
  }

  // ============================================================
  // DETAIL SANTRI (edit / nonaktifkan / hapus dilakukan di sana)
  // ============================================================

  Future<void> _bukaDetail(Santri s) async {
    final String? pesan = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => DetailSantriPage(santri: s)),
    );

    if (pesan != null && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesan),
          backgroundColor: hijau,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _muat();
    }
  }

  // ============================================================
  // BANTUAN
  // ============================================================

  List<Santri> _tersaring() {
    final String kata = _cariController.text.trim().toLowerCase();

    return _santri.where((s) {
      if (_filter == 'aktif' && !s.statusAktif) {
        return false;
      }

      if (_filter == 'nonaktif' && s.statusAktif) {
        return false;
      }

      if (kata.isEmpty) {
        return true;
      }

      return s.namaLengkap.toLowerCase().contains(kata) ||
          s.nis.toLowerCase().contains(kata);
    }).toList();
  }

  Widget _chip(String label, String nilai) {
    final bool terpilih = _filter == nilai;

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
          setState(() {
            _filter = nilai;
          });
        },
      ),
    );
  }

  Widget _kartuSantri(Santri s) {
    final Color warna = s.statusAktif ? hijau : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _bukaDetail(s),
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
                      'NIS ${s.nis} • ${s.labelGender} • ${s.labelKamar}',
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
                          'Data Santri',
                          style: TextStyle(
                            color: hijauTua,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _memuat ? 'Memuat…' : '${_santri.length} santri',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _tambah,
                    icon: const Icon(Icons.add, color: hijau),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _cariController,
                onChanged: (_) => setState(() {}),
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
                  _chip('Semua', 'semua'),
                  _chip('Aktif', 'aktif'),
                  _chip('Nonaktif', 'nonaktif'),
                ],
              ),
            ),
            const SizedBox(height: 8),
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
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                                _santri.isEmpty
                                    ? 'Belum ada santri. Tambahkan santri pertama lewat tombol di bawah.'
                                    : 'Tidak ada santri yang cocok.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black54),
                              ),
                            )
                          else
                            for (final s in tampil) _kartuSantri(s),
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
                  onPressed: _tambah,
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
  }
}