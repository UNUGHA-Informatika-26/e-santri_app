import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/supabase/supabase_config.dart';

const Object _tidakDiubah = Object();

// ============================================================
// DATA
// ============================================================

class _DataKamar {
  final String label;
  final int persen;

  const _DataKamar(this.label, this.persen);
}

class DataPengasuh {
  final int totalPengurus;
  final int totalSantri;
  final int totalKegiatan;
  final int rataRata;
  final int diAtasTarget;
  final int persenTertinggi;
  final int persenTerendah;

  /// Nama pengurus (kalau terbaca), kalau tidak "Kamar X".
  final List<String> tertinggi;
  final List<String> terendah;

  final List<double> tren7;
  final List<String> label7;
  final List<double> bulanan;

  const DataPengasuh({
    this.totalPengurus = 0,
    this.totalSantri = 0,
    this.totalKegiatan = 0,
    this.rataRata = 0,
    this.diAtasTarget = 0,
    this.persenTertinggi = 0,
    this.persenTerendah = 0,
    this.tertinggi = const [],
    this.terendah = const [],
    this.tren7 = const [],
    this.label7 = const [],
    this.bulanan = const [],
  });
}

// ============================================================
// SERVICE
// ============================================================

class DashboardPengasuhService {
  static const int targetPersen = 85;
  static const _hurufHari = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

  String _fmt(DateTime t) {
    final bulan = t.month.toString().padLeft(2, '0');
    final hari = t.day.toString().padLeft(2, '0');
    return '${t.year}-$bulan-$hari';
  }

  /// Nama pengurus lewat fungsi database khusus. Kalau gagal, kosong saja.
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

  /// Presensi dibaca bertahap karena Supabase membatasi 1000 baris.
  Future<List<Map<String, dynamic>>> _ambilPresensi(String mulai) async {
    final hasil = <Map<String, dynamic>>[];
    var dari = 0;

    while (true) {
      final data = await supabase
          .from('presensi')
          .select('kegiatan_id, kamar_id, tanggal')
          .gte('tanggal', mulai)
          .order('id')
          .range(dari, dari + 999);

      hasil.addAll(List<Map<String, dynamic>>.from(data));
      if (data.length < 1000) break;
      dari += 1000;
    }

    return hasil;
  }

  Future<DataPengasuh> ambil() async {
    final dataSantri =
        await supabase.from('santri').select('id').eq('status_aktif', true);
    final totalSantri = dataSantri.length;

    final dataPengurus =
        await supabase.from('pengurus').select('id, kamar_id');

    final idKamar = <String>[];
    final pengurusPerKamar = <String, String>{};
    for (final baris in dataPengurus) {
      final k = baris['kamar_id'] as String?;
      if (k == null) continue;
      idKamar.add(k);
      pengurusPerKamar[k] = baris['id'] as String;
    }

    if (idKamar.isEmpty) {
      return DataPengasuh(totalSantri: totalSantri);
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

    final dataKegiatan =
        await supabase.from('kegiatan').select('id').eq('aktif', true);
    final kegiatanAktif = <String>{};
    for (final k in dataKegiatan) {
      kegiatanAktif.add(k['id'] as String);
    }
    final totalKegiatan = kegiatanAktif.length;

    final sekarang = DateTime.now();
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final mulai = hariIni.subtract(const Duration(days: 29));

    final dataPresensi = await _ambilPresensi(_fmt(mulai));

    final terlapor = <String, Map<String, Set<String>>>{};
    for (final baris in dataPresensi) {
      final tanggal = baris['tanggal']?.toString();
      final kamarId = baris['kamar_id'] as String?;
      final kegiatanId = baris['kegiatan_id'] as String?;
      if (tanggal == null || kamarId == null || kegiatanId == null) continue;
      if (!kegiatanAktif.contains(kegiatanId)) continue;

      terlapor
          .putIfAbsent(tanggal, () => <String, Set<String>>{})
          .putIfAbsent(kamarId, () => <String>{})
          .add(kegiatanId);
    }

    double persenKamar(String tanggal, String kamarId) {
      if (totalKegiatan == 0) return 0;
      final jumlah = terlapor[tanggal]?[kamarId]?.length ?? 0;
      return (jumlah / totalKegiatan).clamp(0.0, 1.0);
    }

    double rataHari(String tanggal) {
      var total = 0.0;
      for (final id in idKamar) {
        total += persenKamar(tanggal, id);
      }
      return total / idKamar.length;
    }

    // Persentase hari ini per kamar (satu kamar = satu pengurus)
    final tanggalHariIni = _fmt(hariIni);
    final hasil = <_DataKamar>[];
    for (final id in idKamar) {
      final persen = (persenKamar(tanggalHariIni, id) * 100).round();
      final label = namaPengurus[pengurusPerKamar[id]] ??
          'Kamar ${namaPerKamar[id] ?? '-'}';
      hasil.add(_DataKamar(label, persen));
    }

    var tertinggi = hasil.first.persen;
    var terendah = hasil.first.persen;
    var jumlahPersen = 0;
    var diAtas = 0;
    for (final h in hasil) {
      if (h.persen > tertinggi) tertinggi = h.persen;
      if (h.persen < terendah) terendah = h.persen;
      if (h.persen >= targetPersen) diAtas++;
      jumlahPersen += h.persen;
    }

    final daftarTertinggi = hasil
        .where((h) => h.persen == tertinggi)
        .map((h) => h.label)
        .toList()
      ..sort();
    final daftarTerendah = hasil
        .where((h) => h.persen == terendah)
        .map((h) => h.label)
        .toList()
      ..sort();

    final tren7 = <double>[];
    final label7 = <String>[];
    final bulanan = <double>[];

    for (var i = 29; i >= 0; i--) {
      final d = hariIni.subtract(Duration(days: i));
      final nilai = rataHari(_fmt(d));
      bulanan.add(nilai);

      if (i <= 6) {
        tren7.add(nilai);
        label7.add(_hurufHari[d.weekday - 1]);
      }
    }

    return DataPengasuh(
      totalPengurus: hasil.length,
      totalSantri: totalSantri,
      totalKegiatan: totalKegiatan,
      rataRata: (jumlahPersen / hasil.length).round(),
      diAtasTarget: diAtas,
      persenTertinggi: tertinggi,
      persenTerendah: terendah,
      tertinggi: daftarTertinggi,
      terendah: daftarTerendah,
      tren7: tren7,
      label7: label7,
      bulanan: bulanan,
    );
  }
}

// ============================================================
// EVENT
// ============================================================

abstract class DashboardPengasuhEvent {
  const DashboardPengasuhEvent();
}

class DashboardPengasuhDimuat extends DashboardPengasuhEvent {
  const DashboardPengasuhDimuat();
}

// ============================================================
// STATE
// ============================================================

class DashboardPengasuhState {
  final bool memuat;
  final String? error;
  final DataPengasuh data;

  const DashboardPengasuhState({
    this.memuat = true,
    this.error,
    this.data = const DataPengasuh(),
  });

  DashboardPengasuhState salin({
    bool? memuat,
    Object? error = _tidakDiubah,
    DataPengasuh? data,
  }) {
    return DashboardPengasuhState(
      memuat: memuat ?? this.memuat,
      error: identical(error, _tidakDiubah) ? this.error : error as String?,
      data: data ?? this.data,
    );
  }
}

// ============================================================
// BLOC
// ============================================================

class DashboardPengasuhBloc
    extends Bloc<DashboardPengasuhEvent, DashboardPengasuhState> {
  final DashboardPengasuhService service;

  DashboardPengasuhBloc({required this.service})
      : super(const DashboardPengasuhState()) {
    on<DashboardPengasuhDimuat>(_onDimuat);
  }

  Future<void> _onDimuat(
    DashboardPengasuhDimuat event,
    Emitter<DashboardPengasuhState> emit,
  ) async {
    emit(state.salin(memuat: true, error: null));

    try {
      final data = await service.ambil();
      emit(state.salin(memuat: false, data: data));
    } catch (e) {
      emit(state.salin(memuat: false, error: e.toString()));
    }
  }
}