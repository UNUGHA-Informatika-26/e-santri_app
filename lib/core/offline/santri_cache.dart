import 'dart:convert';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../pages/admin/santri/santri_model.dart';

class SantriCache {
  static const _kotak = 'cache_santri';
  static const _kunci = 'daftar';
  static Future<void>? _siap;

  static Future<void> _init() {
    return _siap ??= () async {
      await Hive.initFlutter();
      await Hive.openBox(_kotak);
    }();
  }

  static Future<void> simpan(List<Santri> data) async {
    try {
      await _init();
      await Hive.box(_kotak).put(
        _kunci,
        jsonEncode([
          for (final s in data)
            {
              'id': s.id,
              'nis': s.nis,
              'nama_lengkap': s.namaLengkap,
              'gender': s.gender,
              'kamar_id': s.kamarId,
              'no_hp': s.noHp,
              'alamat': s.alamat,
              'status_aktif': s.statusAktif,
              'kamar': s.namaKamar == null
                  ? null
                  : {'nama_kamar': s.namaKamar},
            },
        ]),
      );
    } catch (_) {
      // Cache hanya bonus.
    }
  }

  static Future<List<Santri>?> baca() async {
    try {
      await _init();
      final v = Hive.box(_kotak).get(_kunci);
      if (v == null) return null;

      final list = jsonDecode(v as String) as List;
      return [
        for (final e in list)
          Santri.fromMap(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {
      return null;
    }
  }
}