import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/supabase/supabase_config.dart';

class ManajemenAkunPage extends StatefulWidget {
  const ManajemenAkunPage({super.key});

  @override
  State<ManajemenAkunPage> createState() => _ManajemenAkunPageState();
}

class _ManajemenAkunPageState extends State<ManajemenAkunPage> {
  List<Map<String, dynamic>> _akun = [];
  bool _memuat = true;
  String? _error;
  int _tab = 0; // 0 = menunggu, 1 = semua akun
  String? _sedangProses;

  @override
  void initState() {
    super.initState();
    _muat();
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
      final data = await supabase
          .from('profiles')
          .select('id, full_name, username, email, role, status, created_at')
          .order('created_at', ascending: false);

      if (!mounted) {
        return;
      }

      setState(() {
        _akun = List<Map<String, dynamic>>.from(data);
        _memuat = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Gagal memuat data akun. Tarik layar ke bawah untuk mencoba lagi.';
        _memuat = false;
      });
    }
  }

  // ============================================================
  // UBAH STATUS (dengan konfirmasi)
  // ============================================================

  Future<void> _ubahStatus(
    Map<String, dynamic> akun,
    String statusBaru,
    String judul,
    String pesan,
  ) async {
    final bool? ya = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(judul),
        content: Text(pesan),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    if (ya != true || !mounted) {
      return;
    }

    final String id = akun['id'].toString();

    setState(() {
      _sedangProses = id;
    });

    try {
      final hasil = await supabase
          .from('profiles')
          .update({'status': statusBaru})
          .eq('id', id)
          .select();

      if (!mounted) {
        return;
      }

      if (hasil.isEmpty) {
        _tampilkanPesan(
          'Perubahan ditolak database. Aturan akses (RLS) belum mengizinkan Admin mengubah akun.',
          error: true,
        );
      } else {
        _tampilkanPesan('Status akun diperbarui.');
        await _muat();
      }
    } catch (e) {
      if (mounted) {
        _tampilkanPesan('Gagal mengubah status akun.', error: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _sedangProses = null;
        });
      }
    }
  }

  void _tampilkanPesan(String pesan, {bool error = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: error ? Colors.red.shade700 : hijau,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BANTUAN TAMPILAN
  // ============================================================

  String _labelRole(String? role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'pengurus':
        return 'Pengurus';
      case 'pengasuh':
        return 'Pengasuh';
      default:
        return '-';
    }
  }

  String _labelStatus(String? status) {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'pending':
        return 'Menunggu';
      case 'blocked':
        return 'Diblokir';
      default:
        return '-';
    }
  }

  Color _warnaStatus(String? status) {
    switch (status) {
      case 'active':
        return hijau;
      case 'pending':
        return Colors.amber.shade800;
      case 'blocked':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  String _tanggal(dynamic nilai) {
    final DateTime? d = DateTime.tryParse(nilai?.toString() ?? '')?.toLocal();

    if (d == null) {
      return '-';
    }

    final String hari = d.day.toString().padLeft(2, '0');
    final String bulan = d.month.toString().padLeft(2, '0');

    return '$hari/$bulan/${d.year}';
  }

  Widget _lencana(String teks, Color warna) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        teks,
        style: TextStyle(
          color: warna,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _tombolTab(String label, int index) {
    final bool aktif = _tab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: aktif ? hijau : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: aktif ? Colors.white : hijauTua,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // KARTU AKUN
  // ============================================================

  Widget _kartuAkun(Map<String, dynamic> akun) {
    final String? role = akun['role']?.toString();
    final String? status = akun['status']?.toString();
    final String id = akun['id'].toString();
    final String nama = akun['full_name']?.toString() ?? '-';
    final bool sibuk = _sedangProses == id;

    final List<Widget> aksi = [];

    if (role != 'admin') {
      if (status == 'pending') {
        aksi.add(
          Expanded(
            child: OutlinedButton(
              onPressed: sibuk
                  ? null
                  : () => _ubahStatus(
                        akun,
                        'blocked',
                        'Tolak pendaftaran?',
                        'Akun $nama akan diblokir dan tidak bisa login.',
                      ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade700),
              ),
              child: const Text('Tolak'),
            ),
          ),
        );
        aksi.add(const SizedBox(width: 8));
        aksi.add(
          Expanded(
            child: ElevatedButton(
              onPressed: sibuk
                  ? null
                  : () => _ubahStatus(
                        akun,
                        'active',
                        'Setujui akun?',
                        'Akun $nama (${_labelRole(role)}) akan bisa login.',
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hijau,
                foregroundColor: Colors.white,
              ),
              child: const Text('Setujui'),
            ),
          ),
        );
      } else if (status == 'active') {
        aksi.add(
          Expanded(
            child: OutlinedButton(
              onPressed: sibuk
                  ? null
                  : () => _ubahStatus(
                        akun,
                        'blocked',
                        'Blokir akun?',
                        'Akun $nama tidak akan bisa login sampai diaktifkan kembali.',
                      ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade700),
              ),
              child: const Text('Blokir'),
            ),
          ),
        );
      } else if (status == 'blocked') {
        aksi.add(
          Expanded(
            child: ElevatedButton(
              onPressed: sibuk
                  ? null
                  : () => _ubahStatus(
                        akun,
                        'active',
                        'Aktifkan kembali?',
                        'Akun $nama akan bisa login lagi.',
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hijau,
                foregroundColor: Colors.white,
              ),
              child: const Text('Aktifkan kembali'),
            ),
          ),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: hijauTua,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              _lencana(_labelRole(role), Colors.blueGrey.shade700),
              const SizedBox(width: 6),
              _lencana(_labelStatus(status), _warnaStatus(status)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '@${akun['username'] ?? '-'} • ${akun['email'] ?? '-'}',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            'Daftar ${_tanggal(akun['created_at'])}',
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
          if (aksi.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: aksi),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menunggu =
        _akun.where((a) => a['status'] == 'pending').toList();

    final List<Map<String, dynamic>> tampil = _tab == 0 ? menunggu : _akun;

    return Scaffold(
      backgroundColor: krem,
      appBar: AppBar(
        backgroundColor: hijauTua,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Manajemen akun',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _tombolTab('Menunggu (${menunggu.length})', 0),
                  _tombolTab('Semua akun (${_akun.length})', 1),
                ],
              ),
            ),
            Expanded(
              child: _memuat
                  ? const Center(
                      child: CircularProgressIndicator(color: hijau),
                    )
                  : RefreshIndicator(
                      color: hijau,
                      onRefresh: _muat,
                      child: ListView(
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
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'Tidak ada akun yang menunggu persetujuan.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54),
                              ),
                            )
                          else
                            for (final akun in tampil) _kartuAkun(akun),
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