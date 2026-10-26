import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/supabase/supabase_config.dart';

const Object _tidakDiubah = Object();

// ============================================================
// DATA + SERVICE
// ============================================================

class RingkasanAdmin {
  final int jumlahSantri;
  final int jumlahKamar;
  final int jumlahPengurus;
  final int hadir;
  final int izin;
  final int sakit;
  final int alfa;
  final String namaKegiatan;
  final String waktuKegiatan;
  final int kamarSelesai;
  final List<String> kamarBelum;

  const RingkasanAdmin({
    this.jumlahSantri = 0,
    this.jumlahKamar = 0,
    this.jumlahPengurus = 0,
    this.hadir = 0,
    this.izin = 0,
    this.sakit = 0,
    this.alfa = 0,
    this.namaKegiatan = 'Presensi Hari Ini',
    this.waktuKegiatan = '-',
    this.kamarSelesai = 0,
    this.kamarBelum = const [],
  });
}

class DashboardAdminService {
  String _tanggalHariIni() {
    final now = DateTime.now();
    final bulan = now.month.toString().padLeft(2, '0');
    final hari = now.day.toString().padLeft(2, '0');
    return '${now.year}-$bulan-$hari';
  }

  Future<int> jumlahMenunggu() async {
    final data =
        await supabase.from('profiles').select('id').eq('status', 'pending');
    return data.length;
  }

  Future<RingkasanAdmin> ambilRingkasan() async {
    final santri =
        await supabase.from('santri').select('id').eq('status_aktif', true);
    final pengurus = await supabase.from('pengurus').select('id');
    final dataKamar = await supabase.from('kamar').select('id, nama_kamar');

    final dataPresensi = await supabase
        .from('presensi')
        .select('status, kamar_id')
        .eq('tanggal', _tanggalHariIni());

    var hadir = 0, izin = 0, sakit = 0, alfa = 0;
    final kamarSudahKirim = <String>{};

    for (final baris in dataPresensi) {
      switch (baris['status'] as String?) {
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

      final kamarId = baris['kamar_id'] as String?;
      if (kamarId != null) kamarSudahKirim.add(kamarId);
    }

    final belum = <String>[];
    for (final k in dataKamar) {
      final id = k['id'] as String;
      if (!kamarSudahKirim.contains(id)) {
        belum.add((k['nama_kamar'] ?? id).toString());
      }
    }

    // Kegiatan aktif (tabel kegiatan tidak punya kolom jam).
    final dataKegiatan = await supabase
        .from('kegiatan')
        .select('nama_kegiatan')
        .eq('aktif', true);

    var namaKegiatan = 'Presensi Hari Ini';
    if (dataKegiatan.length == 1) {
      namaKegiatan =
          (dataKegiatan.first['nama_kegiatan'] ?? namaKegiatan).toString();
    }

    return RingkasanAdmin(
      jumlahSantri: santri.length,
      jumlahKamar: dataKamar.length,
      jumlahPengurus: pengurus.length,
      hadir: hadir,
      izin: izin,
      sakit: sakit,
      alfa: alfa,
      namaKegiatan: namaKegiatan,
      waktuKegiatan: '${dataKegiatan.length} kegiatan aktif',
      kamarSelesai: kamarSudahKirim.length,
      kamarBelum: belum,
    );
  }
}

// ============================================================
// EVENT
// ============================================================

abstract class DashboardAdminEvent {
  const DashboardAdminEvent();
}

class DashboardAdminDimuat extends DashboardAdminEvent {
  const DashboardAdminDimuat();
}

/// Muat ulang hanya jumlah pendaftar menunggu (setelah dari Manajemen Akun).
class DashboardAdminMenungguDimuat extends DashboardAdminEvent {
  const DashboardAdminMenungguDimuat();
}

// ============================================================
// STATE
// ============================================================

class DashboardAdminState {
  final bool memuat;
  final String? error;
  final int menunggu;
  final RingkasanAdmin data;

  const DashboardAdminState({
    this.memuat = true,
    this.error,
    this.menunggu = 0,
    this.data = const RingkasanAdmin(),
  });

  DashboardAdminState salin({
    bool? memuat,
    Object? error = _tidakDiubah,
    int? menunggu,
    RingkasanAdmin? data,
  }) {
    return DashboardAdminState(
      memuat: memuat ?? this.memuat,
      error: identical(error, _tidakDiubah) ? this.error : error as String?,
      menunggu: menunggu ?? this.menunggu,
      data: data ?? this.data,
    );
  }
}

// ============================================================
// BLOC
// ============================================================

class DashboardAdminBloc
    extends Bloc<DashboardAdminEvent, DashboardAdminState> {
  final DashboardAdminService service;

  DashboardAdminBloc({required this.service})
      : super(const DashboardAdminState()) {
    on<DashboardAdminDimuat>(_onDimuat);
    on<DashboardAdminMenungguDimuat>(_onMenunggu);
  }

  Future<int> _menungguAman() async {
    try {
      return await service.jumlahMenunggu();
    } catch (_) {
      return state.menunggu;
    }
  }

  Future<void> _onDimuat(
    DashboardAdminDimuat event,
    Emitter<DashboardAdminState> emit,
  ) async {
    emit(state.salin(memuat: true, error: null));

    try {
      final menunggu = await _menungguAman();
      final data = await service.ambilRingkasan();
      emit(state.salin(memuat: false, menunggu: menunggu, data: data));
    } catch (e) {
      emit(state.salin(memuat: false, error: e.toString()));
    }
  }

  Future<void> _onMenunggu(
    DashboardAdminMenungguDimuat event,
    Emitter<DashboardAdminState> emit,
  ) async {
    final menunggu = await _menungguAman();
    emit(state.salin(menunggu: menunggu));
  }
}