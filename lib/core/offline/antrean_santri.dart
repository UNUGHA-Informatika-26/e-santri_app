import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../pages/admin/santri/santri_service.dart';

class ItemAntreanSantri {
  final String nis;
  final String namaLengkap;
  final String gender;
  final String? kamarId;
  final String? noHp;
  final String? alamat;
  final bool ditolak;
  final String? alasan;

  const ItemAntreanSantri({
    required this.nis,
    required this.namaLengkap,
    required this.gender,
    this.kamarId,
    this.noHp,
    this.alamat,
    this.ditolak = false,
    this.alasan,
  });

  Map<String, dynamic> toMap() => {
        'nis': nis,
        'nama_lengkap': namaLengkap,
        'gender': gender,
        'kamar_id': kamarId,
        'no_hp': noHp,
        'alamat': alamat,
        'ditolak': ditolak,
        'alasan': alasan,
      };

  factory ItemAntreanSantri.fromMap(Map<String, dynamic> m) {
    return ItemAntreanSantri(
      nis: (m['nis'] ?? '').toString(),
      namaLengkap: (m['nama_lengkap'] ?? '').toString(),
      gender: (m['gender'] ?? '').toString(),
      kamarId: m['kamar_id']?.toString(),
      noHp: m['no_hp']?.toString(),
      alamat: m['alamat']?.toString(),
      ditolak: m['ditolak'] == true,
      alasan: m['alasan']?.toString(),
    );
  }

  ItemAntreanSantri ditandaiDitolak(String alasan) => ItemAntreanSantri(
        nis: nis,
        namaLengkap: namaLengkap,
        gender: gender,
        kamarId: kamarId,
        noHp: noHp,
        alamat: alamat,
        ditolak: true,
        alasan: alasan,
      );
}

/// Antrean santri baru yang menunggu internet (disimpan di Hive).
class AntreanSantri {
  static const _kotak = 'antrean_santri';
  static Future<void>? _siap;

  static Future<void> _init() {
    return _siap ??= () async {
      await Hive.initFlutter();
      await Hive.openBox(_kotak);
    }();
  }

  /// Kunci = NIS, jadi NIS yang sama tidak masuk dua kali.
  static Future<void> tambah(ItemAntreanSantri item) async {
    await _init();
    await Hive.box(_kotak).put(item.nis.trim(), jsonEncode(item.toMap()));
  }

  static Future<List<ItemAntreanSantri>> semua() async {
    try {
      await _init();
      final box = Hive.box(_kotak);
      return [
        for (final k in box.keys)
          ItemAntreanSantri.fromMap(
            Map<String, dynamic>.from(jsonDecode(box.get(k) as String) as Map),
          ),
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<void> hapus(String nis) async {
    await _init();
    await Hive.box(_kotak).delete(nis.trim());
  }

  static Future<void> tandaiDitolak(
    ItemAntreanSantri item,
    String alasan,
  ) async {
    await _init();
    await Hive.box(_kotak).put(
      item.nis.trim(),
      jsonEncode(item.ditandaiDitolak(alasan).toMap()),
    );
  }
}

/// Mengirim antrean saat internet kembali.
class SinkronSantri {
  SinkronSantri._();
  static final SinkronSantri instance = SinkronSantri._();

  final StreamController<void> _selesai = StreamController<void>.broadcast();

  /// Berbunyi setiap kali ada perubahan antrean akibat sinkron.
  Stream<void> get selesai => _selesai.stream;

  StreamSubscription? _langganan;
  bool _berjalan = false;

  void mulai() {
    _langganan ??= Connectivity().onConnectivityChanged.listen((hasil) {
      if (!hasil.contains(ConnectivityResult.none)) {
        kirimSekarang();
      }
    });
    kirimSekarang();
  }

  Future<void> kirimSekarang() async {
    if (_berjalan) return;
    _berjalan = true;

    var berubah = false;

    try {
      final service = SantriService();

      for (final item in await AntreanSantri.semua()) {
        if (item.ditolak) continue;

        try {
          await service.tambah(
            nis: item.nis,
            namaLengkap: item.namaLengkap,
            gender: item.gender,
            kamarId: item.kamarId,
            noHp: item.noHp,
            alamat: item.alamat,
          );
          await AntreanSantri.hapus(item.nis);
          berubah = true;
        } on SantriException catch (e) {
          // Ditolak server (mis. NIS sudah dipakai): jangan hilang.
          await AntreanSantri.tandaiDitolak(item, e.pesan);
          berubah = true;
        } catch (_) {
          // Masalah jaringan: berhenti, coba lagi nanti.
          break;
        }
      }
    } finally {
      _berjalan = false;
    }

    if (berubah) _selesai.add(null);
  }
}