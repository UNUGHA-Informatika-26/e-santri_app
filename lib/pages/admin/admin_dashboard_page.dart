import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/format_tanggal.dart';
import '../../widgets/dashboard_widgets.dart';
import 'akun/manajemen_akun_page.dart';

class AdminDashboardPage extends StatefulWidget {
  final String namaLengkap;

  const AdminDashboardPage({
    super.key,
    this.namaLengkap = 'Admin',
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _memuat = true;
  String? _error;

  int _menunggu = 0;

  // Ringkasan
  int _jumlahSantri = 0;
  int _jumlahKamar = 0;
  int _jumlahPengurus = 0;

  // Statistik presensi hari ini
  int _hadir = 0;
  int _izin = 0;
  int _sakit = 0;
  int _alfa = 0;

  // Progress kegiatan hari ini
  String _namaKegiatan = '-';
  String _waktuKegiatan = '-';
  int _kamarSelesai = 0;
  List<String> _kamarBelum = [];

  @override
  void initState() {
    super.initState();
    _muatSemua();
  }

  String _tanggalHariIni() {
    final now = DateTime.now();
    final bulan = now.month.toString().padLeft(2, '0');
    final hari = now.day.toString().padLeft(2, '0');
    return '${now.year}-$bulan-$hari';
  }

  Future<void> _muatSemua() async {
    setState(() {
      _memuat = true;
      _error = null;
    });

    try {
      await Future.wait([
        _muatJumlahMenunggu(),
        _muatRingkasan(),
        _muatPresensiHariIni(),
      ]);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _memuat = false);
      }
    }
  }

  // ============================================================
  // 1. JUMLAH PENDAFTAR MENUNGGU
  // ============================================================
  Future<void> _muatJumlahMenunggu() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('status', 'pending');

      if (!mounted) return;
      setState(() => _menunggu = data.length);
    } catch (_) {
      // Abaikan, penanda tidak ditampilkan
    }
  }

  // ============================================================
  // 2. RINGKASAN PESANTREN
  // ============================================================
  Future<void> _muatRingkasan() async {
    final client = Supabase.instance.client;

    // Santri aktif
    final santri = await client
        .from('santri')
        .select('id')
        .eq('status_aktif', true);

    // Total kamar
    final kamar = await client.from('kamar').select('id');

    // Total pengurus (dari tabel pengurus)
    final pengurus = await client.from('pengurus').select('id');

    if (!mounted) return;
    setState(() {
      _jumlahSantri = santri.length;
      _jumlahKamar = kamar.length;
      _jumlahPengurus = pengurus.length;
    });
  }

  // ============================================================
  // 3. PRESENSI HARI INI + PROGRESS KEGIATAN
  // ============================================================
  Future<void> _muatPresensiHariIni() async {
    final client = Supabase.instance.client;
    final tanggal = _tanggalHariIni();

    // Ambil semua presensi hari ini
    final dataPresensi = await client
        .from('presensi')
        .select('status, kamar_id, kegiatan_id')
        .eq('tanggal', tanggal);

    int hadir = 0, izin = 0, sakit = 0, alfa = 0;
    final Set<String> kamarSudahKirim = {};

    for (final baris in dataPresensi) {
      final status = baris['status'] as String?;
      final kamarId = baris['kamar_id'] as String?;

      switch (status) {
        case 'hadir':
          hadir++;
          break;
        case 'izin':
          izin++;
          break;
        case 'sakit':
          sakit++;
          break;
        case 'alfa':
          alfa++;
          break;
      }

      if (kamarId != null) {
        kamarSudahKirim.add(kamarId);
      }
    }

    // Ambil semua kamar + nama
    final dataKamar = await client.from('kamar').select('id, nama_kamar');

    final Map<String, String> namaKamar = {};
    for (final k in dataKamar) {
      namaKamar[k['id'] as String] = k['nama_kamar'] as String? ?? '-';
    }

    // Kamar yang belum kirim
    final List<String> belum = [];
    for (final k in dataKamar) {
      final id = k['id'] as String;
      if (!kamarSudahKirim.contains(id)) {
        belum.add(namaKamar[id] ?? id);
      }
    }

    // Ambil kegiatan aktif (ambil yang pertama / utama hari ini)
    String namaKegiatan = 'Presensi Hari Ini';
    String waktuKegiatan = '-';

    try {
      final kegiatan = await client
          .from('kegiatan')
          .select('nama, jam_mulai, jam_selesai')
          .eq('status_aktif', true)
          .order('jam_mulai')
          .limit(1)
          .maybeSingle();

      if (kegiatan != null) {
        namaKegiatan = kegiatan['nama'] as String? ?? namaKegiatan;
        final mulai = kegiatan['jam_mulai'] as String? ?? '';
        final selesai = kegiatan['jam_selesai'] as String? ?? '';
        if (mulai.isNotEmpty || selesai.isNotEmpty) {
          waktuKegiatan = '$mulai–$selesai';
        }
      }
    } catch (_) {
      // Tabel kegiatan belum ada / kolom beda → pakai default
    }

    if (!mounted) return;
    setState(() {
      _hadir = hadir;
      _izin = izin;
      _sakit = sakit;
      _alfa = alfa;
      _namaKegiatan = namaKegiatan;
      _waktuKegiatan = waktuKegiatan;
      _kamarSelesai = kamarSudahKirim.length;
      _kamarBelum = belum;
    });
  }

  Future<void> _bukaManajemenAkun() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManajemenAkunPage()),
    );
    if (mounted) {
      _muatJumlahMenunggu();
    }
  }

  // ============================================================
  // KARTU MANAJEMEN AKUN
  // ============================================================
  Widget _kartuManajemenAkun() {
    final adaMenunggu = _menunggu > 0;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _bukaManajemenAkun,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: adaMenunggu ? Colors.amber.shade600 : Colors.grey.shade200,
            width: adaMenunggu ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.manage_accounts_outlined, color: hijau),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manajemen Akun',
                    style: TextStyle(
                      color: hijauTua,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    adaMenunggu
                        ? '$_menunggu pendaftar menunggu persetujuan'
                        : 'Setujui pendaftaran dan kelola pengguna',
                    style: TextStyle(
                      color: adaMenunggu
                          ? Colors.amber.shade900
                          : Colors.black54,
                      fontSize: 12,
                      fontWeight:
                          adaMenunggu ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (adaMenunggu)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _menunggu > 99 ? '99+' : '$_menunggu',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right, color: hijau),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TAMPILAN
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final totalTercatat = _hadir + _izin + _sakit + _alfa;
    final persen =
        _jumlahKamar == 0 ? 0.0 : _kamarSelesai / _jumlahKamar;
    final persenTeks = '${(persen * 100).round()}% selesai';

    return Scaffold(
      backgroundColor: krem,
      body: SafeArea(
        child: RefreshIndicator(
          color: hijau,
          onRefresh: _muatSemua,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              DashboardHeader(
                judul: 'Assalamu\'alaikum, ${widget.namaLengkap}',
                subjudul: formatTanggalIndonesia(DateTime.now()),
                ikon: Icons.notifications_none,
                onIkon: _bukaManajemenAkun,
              ),

              const SizedBox(height: 16),

              if (_memuat)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator(color: hijau)),
                )
              else if (_error != null)
                KartuPutih(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data gagal dimuat',
                        style: TextStyle(
                          color: hijauTua,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      TextButton(
                        onPressed: _muatSemua,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                )
              else ...[
                // RINGKASAN REAL
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: hijauTua,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'RINGKASAN PESANTREN',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_jumlahSantri santri aktif',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$_jumlahKamar kamar • $_jumlahPengurus pengurus',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.home_work_outlined,
                          color: Colors.white70,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // STATISTIK REAL
                BarisStatistik(
                  hadir: '$_hadir',
                  izin: '$_izin',
                  sakit: '$_sakit',
                  alfa: '$_alfa',
                ),

                const SizedBox(height: 20),

                JudulBagian(
                  judul: 'Presensi hari ini',
                  aksi: 'Lihat rekap',
                  onAksi: () => tampilkanSegera(context, 'Rekap presensi'),
                ),

                const SizedBox(height: 10),

                // KARTU KEGIATAN REAL
                KartuPutih(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _namaKegiatan,
                                  style: const TextStyle(
                                    color: hijauTua,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$_waktuKegiatan • $_jumlahKamar kamar',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: hijauMuda.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              persenTeks,
                              style: const TextStyle(
                                color: hijauTua,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: persen,
                          minHeight: 8,
                          color: hijau,
                          backgroundColor: const Color(0xFFE5E7E5),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _kartuManajemenAkun(),

                const SizedBox(height: 16),

                // PERINGATAN KAMAR YANG BELUM KIRIM
                if (_kamarBelum.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber.shade800,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_kamarBelum.length} kamar belum mengirim presensi',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_kamarBelum.take(3).join(', ')}'
                                '${_kamarBelum.length > 3 ? ' +${_kamarBelum.length - 3} lainnya' : ''}'
                                ' • $_namaKegiatan',
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
                  )
                else if (totalTercatat > 0)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: hijauMuda.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: hijau),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Semua kamar sudah mengirim presensi hari ini',
                            style: TextStyle(
                              color: hijauTua,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomNav(
        nama: widget.namaLengkap,
        peran: 'Admin',
        menu: const [
          NavItem(Icons.dashboard_outlined, 'Dashboard'),
          NavItem(Icons.storage_outlined, 'Data'),
          NavItem(Icons.fact_check_outlined, 'Presensi'),
          NavItem(Icons.show_chart, 'Monitoring'),
          NavItem(Icons.person_outline, 'Profil'),
        ],
      ),
    );
  }
}