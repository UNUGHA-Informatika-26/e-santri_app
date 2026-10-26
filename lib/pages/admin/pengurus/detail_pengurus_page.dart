import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../widgets/dashboard_widgets.dart';
import '../kamar/kamar_model.dart';
import '../kamar/kamar_service.dart';
import 'pengurus_model.dart';
import 'pengurus_service.dart';

class DetailPengurusPage extends StatefulWidget {
  final DataPengurus pengurus;

  const DetailPengurusPage({super.key, required this.pengurus});

  @override
  State<DetailPengurusPage> createState() => _DetailPengurusPageState();
}

class _DetailPengurusPageState extends State<DetailPengurusPage> {
  final PengurusService _service = PengurusService();
  final KamarService _kamarService = KamarService();

  List<Kamar> _kamar = [];
  String? _kamarTerpilih;
  bool _memuat = true;
  bool _menyimpan = false;
  String? _error;

  DataPengurus get _p => widget.pengurus;

  @override
  void initState() {
    super.initState();
    _kamarTerpilih = _p.kamarId;
    _muatKamar();
  }

  // ============================================================
  // MUAT DAFTAR KAMAR
  // ============================================================

  Future<void> _muatKamar() async {
    setState(() {
      _memuat = true;
      _error = null;
    });

    try {
      final data = await _kamarService.ambilSemua();

      if (!mounted) {
        return;
      }

      setState(() {
        // Hanya kamar aktif, ditambah kamar yang sedang dipegang pengurus ini.
        _kamar = data.where((k) => k.aktif || k.id == _p.kamarId).toList();
        _memuat = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Gagal memuat daftar kamar.';
        _memuat = false;
      });
    }
  }

  // ============================================================
  // BANTUAN
  // ============================================================

  bool _dipegangLain(Kamar k) {
    return k.pengurusId != null && k.pengurusId != _p.id;
  }

  void _snackbar(String pesan, {bool galat = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: galat ? Colors.red.shade700 : hijau,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Menjalankan aksi, lalu menutup halaman dengan pesan sukses.
  Future<void> _jalankan(
    Future<void> Function() aksi,
    String pesanSukses,
  ) async {
    setState(() {
      _menyimpan = true;
    });

    try {
      await aksi();

      if (!mounted) {
        return;
      }

      Navigator.pop(context, pesanSukses);
    } on PengurusException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _menyimpan = false;
      });
      _snackbar(e.pesan, galat: true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _menyimpan = false;
      });
      _snackbar('Terjadi kesalahan. Coba lagi.', galat: true);
    }
  }

  // ============================================================
  // AKSI
  // ============================================================

  Future<void> _simpan() async {
    if (_kamarTerpilih == _p.kamarId) {
      _snackbar('Belum ada perubahan.');
      return;
    }

    String pesan;

    if (_kamarTerpilih == null) {
      pesan = '${_p.nama} dilepas dari kamar tugas.';
    } else {
      final kamar = _kamar.firstWhere((k) => k.id == _kamarTerpilih);
      pesan = 'Kamar ${kamar.namaKamar} ditugaskan ke ${_p.nama}.';
    }

    await _jalankan(() => _service.tetapkanKamar(_p.id, _kamarTerpilih), pesan);
  }

  Future<void> _kosongkan() async {
    if (!_p.sudahBertugas) {
      _snackbar('${_p.nama} memang belum punya kamar tugas.');
      return;
    }

    final bool? yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kosongkan kamar tugas?'),
        content: Text(
          '${_p.nama} akan dilepas dari ${_p.labelKamar}. Akunnya tetap aktif.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );

    if (yakin != true) {
      return;
    }

    await _jalankan(
      () => _service.tetapkanKamar(_p.id, null),
      '${_p.nama} dilepas dari kamar tugas.',
    );
  }

  // ============================================================
  // KOMPONEN TAMPILAN
  // ============================================================

  Widget _kartuProfil() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hijauMuda.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Text(
              _p.inisial,
              style: const TextStyle(
                color: hijauTua,
                fontSize: 18,
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
                  _p.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: hijauTua,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${_p.username} • ${_p.labelGender}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: hijau.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Aktif',
              style: TextStyle(
                color: hijau,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barisInfo(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              nilai,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: hijauTua,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pilihanKamar() {
    if (_memuat) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(color: hijau)),
      );
    }

    if (_error != null) {
      return Column(
        children: [
          Text(_error!, style: TextStyle(color: Colors.red.shade700)),
          TextButton(
            onPressed: _muatKamar,
            child: const Text('Coba lagi'),
          ),
        ],
      );
    }

    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('Belum ditugaskan'),
      ),
      for (final k in _kamar) _itemKamar(k),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _kamarTerpilih,
          isExpanded: true,
          items: items,
          onChanged: _menyimpan
              ? null
              : (nilai) {
                  setState(() {
                    _kamarTerpilih = nilai;
                  });
                },
        ),
      ),
    );
  }

  DropdownMenuItem<String?> _itemKamar(Kamar k) {
    final bool dipegang = _dipegangLain(k);
    final String pemegang = k.namaPengurus ?? 'pengurus lain';
    final String teks = dipegang
        ? 'Kamar ${k.namaKamar} • dipegang $pemegang'
        : 'Kamar ${k.namaKamar}';

    return DropdownMenuItem<String?>(
      value: k.id,
      enabled: !dipegang,
      child: Text(
        teks,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: dipegang ? Colors.black38 : Colors.black87),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: krem,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
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
                          'Detail Pengurus',
                          style: TextStyle(
                            color: hijauTua,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Atur akun & kamar tugas',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: hijauTua),
                    onSelected: (nilai) {
                      if (nilai == 'kosongkan') {
                        _kosongkan();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem<String>(
                        value: 'kosongkan',
                        child: Text('Kosongkan kamar tugas'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kartuProfil(),
                    const SizedBox(height: 12),
                    KartuPutih(
                      child: Column(
                        children: [
                          _barisInfo('Email', _p.email),
                          _barisInfo(
                            'Nomor HP',
                            (_p.noHp == null || _p.noHp!.isEmpty)
                                ? '-'
                                : _p.noHp!,
                          ),
                          _barisInfo('Kamar Tugas', _p.labelKamar),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Atur Kamar Tugas',
                      style: TextStyle(
                        color: hijauTua,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Kamar Tugas',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    _pilihanKamar(),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aturan penugasan',
                            style: TextStyle(
                              color: Color(0xFF1F4E8C),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Satu kamar hanya boleh dipegang satu pengurus. Kamar yang sudah dipegang pengurus lain tidak bisa dipilih.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed:
                                  (_menyimpan || _memuat) ? null : _simpan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hijau,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _menyimpan
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Simpan Tugas',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _menyimpan
                                  ? null
                                  : () => tampilkanSegera(
                                        context,
                                        'Edit Profil',
                                      ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: hijau,
                                side: const BorderSide(color: hijau),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Edit Profil',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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