import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../pages/pengurus/presensi/presensi_service.dart';
import '../supabase/supabase_config.dart';

/// Satu laporan presensi yang menunggu dikirim.
class ItemAntrean {
  final String kamarId;
  final String kegiatanId;
  final String tanggal; // yyyy-MM-dd
  final String namaKamar;
  final String namaKegiatan;
  final Map<String, String> status;
  final Map<String, String> keterangan;

  const ItemAntrean({
    required this.kamarId,
    required this.kegiatanId,
    required this.tanggal,
    required this.namaKamar,
    required this.namaKegiatan,
    required this.status,
    required this.keterangan,
  });

  String get kunci => AntreanPresensi.kunci(kamarId, kegiatanId, tanggal);

  Map<String, dynamic> toJson() => {
        'kamarId': kamarId,
        'kegiatanId': kegiatanId,
        'tanggal': tanggal,
        'namaKamar': namaKamar,
        'namaKegiatan': namaKegiatan,
        'status': status,
        'keterangan': keterangan,
      };

  factory ItemAntrean.fromJson(Map<String, dynamic> j) => ItemAntrean(
        kamarId: j['kamarId'] as String,
        kegiatanId: j['kegiatanId'] as String,
        tanggal: j['tanggal'] as String,
        namaKamar: (j['namaKamar'] ?? '') as String,
        namaKegiatan: (j['namaKegiatan'] ?? '') as String,
        status: Map<String, String>.from(j['status'] as Map),
        keterangan: Map<String, String>.from(j['keterangan'] as Map),
      );
}

/// Isi cache yang dipakai saat tidak ada internet.
class CachePresensi {
  final KamarTugas kamar;
  final List<KegiatanPilihan> kegiatan;
  final List<SantriPresensi> santri;

  const CachePresensi({
    required this.kamar,
    required this.kegiatan,
    required this.santri,
  });
}

class AntreanPresensi {
  static const _kotakAntrean = 'antrean_presensi';
  static const _kotakCache = 'cache_presensi';
  static Future<void>? _siap;

  static Future<void> _init() {
    return _siap ??= () async {
      await Hive.initFlutter();
      await Hive.openBox(_kotakAntrean);
      await Hive.openBox(_kotakCache);
    }();
  }

  static String kunci(String kamarId, String kegiatanId, String tanggal) =>
      '$kamarId|$kegiatanId|$tanggal';

  // ---------------- ANTREAN ----------------

  static Future<void> tambah(ItemAntrean item) async {
    await _init();
    await Hive.box(_kotakAntrean).put(item.kunci, jsonEncode(item.toJson()));
  }

  static Future<List<ItemAntrean>> semua() async {
    await _init();
    final hasil = <ItemAntrean>[];

    for (final v in Hive.box(_kotakAntrean).values) {
      try {
        hasil.add(
          ItemAntrean.fromJson(
            Map<String, dynamic>.from(jsonDecode(v as String) as Map),
          ),
        );
      } catch (_) {
        // Data rusak dilewati.
      }
    }

    return hasil;
  }

  static Future<ItemAntrean?> cari(
    String kamarId,
    String kegiatanId,
    String tanggal,
  ) async {
    await _init();
    final v = Hive.box(_kotakAntrean).get(kunci(kamarId, kegiatanId, tanggal));
    if (v == null) return null;

    try {
      return ItemAntrean.fromJson(
        Map<String, dynamic>.from(jsonDecode(v as String) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> hapus(String kunci) async {
    await _init();
    await Hive.box(_kotakAntrean).delete(kunci);
  }

  static Future<int> jumlah() async {
    await _init();
    return Hive.box(_kotakAntrean).length;
  }

  // ---------------- CACHE ----------------

  static String _kunciCache() => 'cache:${supabase.auth.currentUser?.id}';

  static Future<void> simpanCache(
    KamarTugas? kamar,
    List<KegiatanPilihan> kegiatan,
    List<SantriPresensi> santri,
  ) async {
    if (kamar == null) return;

    try {
      await _init();
      await Hive.box(_kotakCache).put(
        _kunciCache(),
        jsonEncode({
          'kamar': {'id': kamar.id, 'nama': kamar.namaKamar},
          'kegiatan': [
            for (final k in kegiatan) {'id': k.id, 'nama': k.nama},
          ],
          'santri': [
            for (final s in santri)
              {'id': s.id, 'nis': s.nis, 'nama': s.nama},
          ],
        }),
      );
    } catch (_) {
      // Cache hanya bonus, jadi kegagalan diabaikan.
    }
  }

  static Future<CachePresensi?> bacaCache() async {
    try {
      await _init();
      final v = Hive.box(_kotakCache).get(_kunciCache());
      if (v == null) return null;

      final j = Map<String, dynamic>.from(jsonDecode(v as String) as Map);
      final k = Map<String, dynamic>.from(j['kamar'] as Map);

      return CachePresensi(
        kamar: KamarTugas(
          id: k['id'] as String,
          namaKamar: k['nama'] as String,
        ),
        kegiatan: [
          for (final e in (j['kegiatan'] as List))
            KegiatanPilihan(
              id: (e as Map)['id'] as String,
              nama: e['nama'] as String,
            ),
        ],
        santri: [
          for (final e in (j['santri'] as List))
            SantriPresensi(
              id: (e as Map)['id'] as String,
              nis: e['nis'] as String,
              nama: e['nama'] as String,
            ),
        ],
      );
    } catch (_) {
      return null;
    }
  }
}

/// Mengirim antrean ke Supabase saat internet ada.
class SinkronPresensi {
  SinkronPresensi._();
  static final SinkronPresensi instance = SinkronPresensi._();

  final PresensiService _service = PresensiService();
  StreamSubscription<List<ConnectivityResult>>? _langganan;
  bool _jalan = false;

  /// Jumlah laporan yang menunggu dikirim.
  final ValueNotifier<int> menunggu = ValueNotifier<int>(0);

  void mulai() {
    _langganan ??= Connectivity().onConnectivityChanged.listen((hasil) {
      if (hasil.any((r) => r != ConnectivityResult.none)) {
        kirimSemua();
      }
    });

    kirimSemua();
  }

  Future<void> segarkan() async {
    menunggu.value = await AntreanPresensi.jumlah();
  }

  Future<int> kirimSemua() async {
    if (_jalan) return 0;
    _jalan = true;
    var terkirim = 0;

    try {
      for (final item in await AntreanPresensi.semua()) {
        try {
          await _service.simpan(
            kamarId: item.kamarId,
            kegiatanId: item.kegiatanId,
            tanggal: DateTime.parse(item.tanggal),
            status: item.status,
            keterangan: item.keterangan,
          );
          await AntreanPresensi.hapus(item.kunci);
          terkirim++;
        } on PresensiException {
          // Ditolak server: dibiarkan di antrean, lanjut ke berikutnya.
        } catch (_) {
          // Masih tanpa internet: berhenti, coba lagi nanti.
          break;
        }
      }
    } finally {
      _jalan = false;
      await segarkan();
    }

    return terkirim;
  }
}