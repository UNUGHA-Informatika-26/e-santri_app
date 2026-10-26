import '../../../core/supabase/supabase_config.dart';

class Rentang {
  final DateTime mulai;
  final DateTime akhir;

  const Rentang(this.mulai, this.akhir);
}

class RingkasanKamar {
  final String kamarId;
  final String namaKamar;
  final String? namaPengurus;
  final int total;
  final int laporan;

  /// Pecahan kegiatan terlapor per hari (0.0 sampai 1.0).
  final List<double> perHari;

  const RingkasanKamar({
    required this.kamarId,
    required this.namaKamar,
    required this.namaPengurus,
    required this.total,
    required this.laporan,
    required this.perHari,
  });

  /// Nama pengurus kalau terbaca, kalau tidak pakai nama kamar.
  String get judul {
    final n = namaPengurus?.trim() ?? '';
    return n.isEmpty ? 'Kamar $namaKamar' : n;
  }

  String get inisial {
    final kata = judul
        .split(RegExp(r'\s+'))
        .where((k) => k.isNotEmpty)
        .toList();

    if (kata.isEmpty) return '?';
    if (kata.length == 1) return kata.first.substring(0, 1).toUpperCase();

    return (kata[0].substring(0, 1) + kata[1].substring(0, 1)).toUpperCase();
  }

  double get persen =>
      total == 0 ? 0.0 : (laporan / total).clamp(0.0, 1.0).toDouble();

  int get persenBulat => (persen * 100).round();
}

class HasilMonitoring {
  final int kegiatanAktif;
  final int jumlahHari;
  final List<RingkasanKamar> kamar;

  const HasilMonitoring({
    required this.kegiatanAktif,
    required this.jumlahHari,
    required this.kamar,
  });

  int get totalKegiatan => kamar.fold(0, (a, k) => a + k.total);
  int get totalLaporan => kamar.fold(0, (a, k) => a + k.laporan);

  int get persenBulat => totalKegiatan == 0
      ? 0
      : (totalLaporan / totalKegiatan * 100).round().clamp(0, 100);
}

class MonitoringService {
  static const _bulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const _bulanPanjang = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String formatDb(DateTime t) {
    final b = t.month.toString().padLeft(2, '0');
    final h = t.day.toString().padLeft(2, '0');
    return '${t.year}-$b-$h';
  }

  static String labelPendek(DateTime t) =>
      '${t.day} ${_bulan[t.month - 1]} ${t.year}';

  static String labelBulan(DateTime t) =>
      '${_bulanPanjang[t.month - 1]} ${t.year}';

  /// jenis: 'hari', 'minggu', 'bulan', 'tahun'. Akhir rentang selalu hari ini.
  static Rentang untuk(String jenis) {
    final n = DateTime.now();
    final hariIni = DateTime(n.year, n.month, n.day);

    switch (jenis) {
      case 'hari':
        return Rentang(hariIni, hariIni);
      case 'minggu':
        return Rentang(
          hariIni.subtract(Duration(days: hariIni.weekday - 1)),
          hariIni,
        );
      case 'tahun':
        return Rentang(DateTime(n.year, 1, 1), hariIni);
      default:
        return Rentang(DateTime(n.year, n.month, 1), hariIni);
    }
  }

  /// Nama pengurus lewat fungsi database khusus. Kalau gagal, kosong saja
  /// (tampilan akan memakai nama kamar).
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

  Future<HasilMonitoring> ambil(DateTime mulai, DateTime akhir) async {
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

    // Hitungan A: tiap kegiatan dihitung sejak tanggal created_at-nya.
    final dataKeg = await supabase
        .from('kegiatan')
        .select('id, created_at')
        .eq('aktif', true);
    final mulaiKegiatan = <String, DateTime>{};
    for (final k in dataKeg) {
      final c = DateTime.tryParse(k['created_at']?.toString() ?? '')
          ?.toLocal();
      mulaiKegiatan[k['id'] as String] =
          c == null ? DateTime(2000) : DateTime(c.year, c.month, c.day);
    }

    var jumlahHari = akhir.difference(mulai).inDays + 1;
    if (jumlahHari < 0) jumlahHari = 0;

    if (idKamar.isEmpty || jumlahHari == 0) {
      return HasilMonitoring(
        kegiatanAktif: mulaiKegiatan.length,
        jumlahHari: jumlahHari,
        kamar: const [],
      );
    }

    final dataKamar = await supabase
        .from('kamar')
        .select('id, nama_kamar')
        .inFilter('id', idKamar);

    final namaPerKamar = <String, String>{};
    for (final k in dataKamar) {
      namaPerKamar[k['id'] as String] = (k['nama_kamar'] ?? '-').toString();
    }

    final namaPengurus = await _ambilNamaPengurus();

    // Presensi dibaca bertahap: Supabase membatasi 1000 baris per permintaan.
    final terlapor = <String, Set<String>>{};
    var dari = 0;
    while (true) {
      final data = await supabase
          .from('presensi')
          .select('kegiatan_id, kamar_id, tanggal')
          .gte('tanggal', formatDb(mulai))
          .lte('tanggal', formatDb(akhir))
          .order('id')
          .range(dari, dari + 999);

      for (final b in data) {
        final tgl = b['tanggal']?.toString();
        final kamarId = b['kamar_id'] as String?;
        final kegId = b['kegiatan_id'] as String?;
        if (tgl == null || kamarId == null || kegId == null) continue;
        if (!mulaiKegiatan.containsKey(kegId)) continue;
        terlapor.putIfAbsent('$tgl|$kamarId', () => <String>{}).add(kegId);
      }

      if (data.length < 1000) break;
      dari += 1000;
    }

    // Kegiatan yang sudah berlaku pada tiap hari dalam periode.
    final tanggal = <DateTime>[];
    final aktifPerHari = <Set<String>>[];
    for (var i = 0; i < jumlahHari; i++) {
      final d = DateTime(mulai.year, mulai.month, mulai.day + i);
      tanggal.add(d);
      aktifPerHari.add({
        for (final e in mulaiKegiatan.entries)
          if (!e.value.isAfter(d)) e.key,
      });
    }

    final hasil = <RingkasanKamar>[];
    for (final id in idKamar) {
      final perHari = <double>[];
      var laporan = 0;
      var total = 0;

      for (var i = 0; i < jumlahHari; i++) {
        final aktif = aktifPerHari[i];
        final sudah = terlapor['${formatDb(tanggal[i])}|$id'];
        final jumlah = sudah == null
            ? 0
            : sudah.where((kid) => aktif.contains(kid)).length;

        total += aktif.length;
        laporan += jumlah;
        perHari.add(aktif.isEmpty ? 0.0 : jumlah / aktif.length);
      }

      hasil.add(
        RingkasanKamar(
          kamarId: id,
          namaKamar: namaPerKamar[id] ?? '-',
          namaPengurus: namaPengurus[pengurusPerKamar[id]],
          total: total,
          laporan: laporan,
          perHari: perHari,
        ),
      );
    }

    hasil.sort(
      (a, b) => a.judul.toLowerCase().compareTo(b.judul.toLowerCase()),
    );

    return HasilMonitoring(
      kegiatanAktif: mulaiKegiatan.length,
      jumlahHari: jumlahHari,
      kamar: hasil,
    );
  }
}