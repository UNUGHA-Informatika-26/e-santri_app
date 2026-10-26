import '../../../core/supabase/supabase_config.dart';
import '../../pengasuh/monitoring/monitoring_service.dart';

String inisialDari(String teks) {
  final kata = teks.split(RegExp(r'\s+')).where((k) => k.isNotEmpty).toList();

  if (kata.isEmpty) return '?';
  if (kata.length == 1) return kata.first.substring(0, 1).toUpperCase();

  return (kata[0].substring(0, 1) + kata[1].substring(0, 1)).toUpperCase();
}

class OpsiKamar {
  final String id;
  final String nama;

  const OpsiKamar(this.id, this.nama);
}

class OpsiKegiatan {
  final String id;
  final String nama;

  const OpsiKegiatan(this.id, this.nama);
}

/// Satu laporan = satu kamar + satu kegiatan pada satu tanggal.
class LaporanKamar {
  final String kamarId;
  final String namaKamar;
  final String? namaPengurus;
  final String kegiatanId;
  final String namaKegiatan;
  final int hadir;
  final int izin;
  final int sakit;
  final int alfa;

  const LaporanKamar({
    required this.kamarId,
    required this.namaKamar,
    required this.namaPengurus,
    required this.kegiatanId,
    required this.namaKegiatan,
    required this.hadir,
    required this.izin,
    required this.sakit,
    required this.alfa,
  });

  int get total => hadir + izin + sakit + alfa;
  bool get selesai => total > 0;

  String get pengurusTeks {
    final n = namaPengurus?.trim() ?? '';
    return n.isEmpty ? 'Kamar $namaKamar' : n;
  }
}

class HasilPresensiHari {
  final DateTime tanggal;
  final List<OpsiKamar> kamar;
  final List<OpsiKegiatan> kegiatan;
  final List<LaporanKamar> laporan;

  const HasilPresensiHari({
    required this.tanggal,
    required this.kamar,
    required this.kegiatan,
    required this.laporan,
  });
}

class BarisSantri {
  final String nama;
  final String nis;
  final String status;
  final String keterangan;

  const BarisSantri({
    required this.nama,
    required this.nis,
    required this.status,
    required this.keterangan,
  });
}

class PresensiAdminService {
  static const _urutanStatus = ['hadir', 'izin', 'sakit', 'alfa'];

  Future<Map<String, String>> _ambilNamaPengurus() async {
    try {
      final data = await supabase.rpc('daftar_nama_pengurus');
      final hasil = <String, String>{};

      for (final b in List<Map<String, dynamic>>.from(data as List)) {
        final id = b['pengurus_id']?.toString();
        final nama = b['nama']?.toString();
        if (id != null && nama != null) hasil[id] = nama;
      }

      return hasil;
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<HasilPresensiHari> ambilHari(DateTime tanggal) async {
    final dataPengurus =
        await supabase.from('pengurus').select('id, kamar_id');

    final idKamar = <String>[];
    final pengurusPerKamar = <String, String>{};
    for (final b in dataPengurus) {
      final k = b['kamar_id'] as String?;
      if (k == null) continue;
      if (!idKamar.contains(k)) idKamar.add(k);
      pengurusPerKamar[k] = b['id'] as String;
    }

    final dataKeg = await supabase
        .from('kegiatan')
        .select('id, nama_kegiatan')
        .eq('aktif', true)
        .order('created_at');

    final kegiatan = <OpsiKegiatan>[
      for (final k in dataKeg)
        OpsiKegiatan(
          k['id'] as String,
          (k['nama_kegiatan'] ?? '-').toString(),
        ),
    ];

    if (idKamar.isEmpty) {
      return HasilPresensiHari(
        tanggal: tanggal,
        kamar: const [],
        kegiatan: kegiatan,
        laporan: const [],
      );
    }

    final dataKamar = await supabase
        .from('kamar')
        .select('id, nama_kamar')
        .inFilter('id', idKamar);

    final kamar = <OpsiKamar>[
      for (final k in dataKamar)
        OpsiKamar(k['id'] as String, (k['nama_kamar'] ?? '-').toString()),
    ]..sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));

    final namaPengurus = await _ambilNamaPengurus();

    // Hitung status per kamar + kegiatan. Dibaca bertahap (batas 1000 baris).
    final hitung = <String, List<int>>{};
    var dari = 0;
    while (true) {
      final data = await supabase
          .from('presensi')
          .select('kamar_id, kegiatan_id, status')
          .eq('tanggal', MonitoringService.formatDb(tanggal))
          .order('id')
          .range(dari, dari + 999);

      for (final b in data) {
        final k = b['kamar_id'] as String?;
        final g = b['kegiatan_id'] as String?;
        final idx = _urutanStatus.indexOf(b['status']?.toString() ?? '');
        if (k == null || g == null || idx < 0) continue;
        final c = hitung.putIfAbsent('$k|$g', () => [0, 0, 0, 0]);
        c[idx] = c[idx] + 1;
      }

      if (data.length < 1000) break;
      dari += 1000;
    }

    final laporan = <LaporanKamar>[];
    for (final k in kamar) {
      for (final g in kegiatan) {
        final c = hitung['${k.id}|${g.id}'] ?? [0, 0, 0, 0];
        laporan.add(
          LaporanKamar(
            kamarId: k.id,
            namaKamar: k.nama,
            namaPengurus: namaPengurus[pengurusPerKamar[k.id]],
            kegiatanId: g.id,
            namaKegiatan: g.nama,
            hadir: c[0],
            izin: c[1],
            sakit: c[2],
            alfa: c[3],
          ),
        );
      }
    }

    return HasilPresensiHari(
      tanggal: tanggal,
      kamar: kamar,
      kegiatan: kegiatan,
      laporan: laporan,
    );
  }

  Future<List<BarisSantri>> ambilDetail(
    DateTime tanggal,
    String kamarId,
    String kegiatanId,
  ) async {
    final data = await supabase
        .from('presensi')
        .select('santri_id, status, keterangan')
        .eq('tanggal', MonitoringService.formatDb(tanggal))
        .eq('kamar_id', kamarId)
        .eq('kegiatan_id', kegiatanId);

    final idSantri = <String>[];
    for (final b in data) {
      final id = b['santri_id'] as String?;
      if (id != null) idSantri.add(id);
    }

    if (idSantri.isEmpty) return [];

    final dataSantri = await supabase
        .from('santri')
        .select('id, nis, nama_lengkap')
        .inFilter('id', idSantri);

    final info = <String, Map<String, dynamic>>{
      for (final s in dataSantri) s['id'] as String: s,
    };

    final hasil = <BarisSantri>[
      for (final b in data)
        BarisSantri(
          nama: (info[b['santri_id']]?['nama_lengkap'] ?? '-').toString(),
          nis: (info[b['santri_id']]?['nis'] ?? '-').toString(),
          status: (b['status'] ?? '').toString(),
          keterangan: (b['keterangan'] ?? '').toString().trim(),
        ),
    ]..sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));

    return hasil;
  }
}