import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/supabase/supabase_config.dart';
import '../pages/pengurus/presensi/presensi_penanda.dart';

const Object _tidakDiubah = Object();

// ============================================================
// DATA + SERVICE
// ============================================================

class DataDashboardPengurus {
  final String? kamarId;
  final String? namaKamar;
  final int jumlahSantri;
  final int hadir;
  final int izin;
  final int sakit;
  final int alfa;

  const DataDashboardPengurus({
    this.kamarId,
    this.namaKamar,
    this.jumlahSantri = 0,
    this.hadir = 0,
    this.izin = 0,
    this.sakit = 0,
    this.alfa = 0,
  });

  /// Salinan dengan angka presensi dikosongkan (data database tetap aman).
  DataDashboardPengurus tanpaPresensi() {
    return DataDashboardPengurus(
      kamarId: kamarId,
      namaKamar: namaKamar,
      jumlahSantri: jumlahSantri,
    );
  }
}

class DashboardPengurusService {
  String _tanggalHariIni() {
    final now = DateTime.now();
    final bulan = now.month.toString().padLeft(2, '0');
    final hari = now.day.toString().padLeft(2, '0');
    return '${now.year}-$bulan-$hari';
  }

  Future<DataDashboardPengurus> ambil({required bool lewatiPresensi}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Sesi login tidak ditemukan.');
    }

    final dataPengurus = await supabase
        .from('pengurus')
        .select('kamar_id')
        .eq('id', userId)
        .maybeSingle();

    final kamarId = dataPengurus?['kamar_id'] as String?;
    if (kamarId == null) return const DataDashboardPengurus();

    final dataKamar = await supabase
        .from('kamar')
        .select('nama_kamar')
        .eq('id', kamarId)
        .maybeSingle();

    final dataSantri = await supabase
        .from('santri')
        .select('id')
        .eq('kamar_id', kamarId)
        .eq('status_aktif', true);

    var hadir = 0, izin = 0, sakit = 0, alfa = 0;

    if (!lewatiPresensi) {
      final dataPresensi = await supabase
          .from('presensi')
          .select('status')
          .eq('kamar_id', kamarId)
          .eq('tanggal', _tanggalHariIni());

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
      }
    }

    return DataDashboardPengurus(
      kamarId: kamarId,
      namaKamar: dataKamar?['nama_kamar'] as String?,
      jumlahSantri: dataSantri.length,
      hadir: hadir,
      izin: izin,
      sakit: sakit,
      alfa: alfa,
    );
  }
}

// ============================================================
// EVENT
// ============================================================

abstract class DashboardPengurusEvent {
  const DashboardPengurusEvent();
}

class DashboardPengurusDimuat extends DashboardPengurusEvent {
  const DashboardPengurusDimuat();
}

/// Dikirim otomatis saat pengurus menekan "Selesai" di Presensi Berhasil.
class DashboardPengurusDireset extends DashboardPengurusEvent {
  const DashboardPengurusDireset();
}

// ============================================================
// STATE
// ============================================================

class DashboardPengurusState {
  final bool memuat;
  final String? error;

  /// true setelah "Selesai" ditekan: angka presensi mulai dari nol lagi.
  /// Hilang saat aplikasi ditutup. Data di database tetap aman.
  final bool direset;
  final DataDashboardPengurus data;

  const DashboardPengurusState({
    this.memuat = true,
    this.error,
    this.direset = false,
    this.data = const DataDashboardPengurus(),
  });

  DashboardPengurusState salin({
    bool? memuat,
    Object? error = _tidakDiubah,
    bool? direset,
    DataDashboardPengurus? data,
  }) {
    return DashboardPengurusState(
      memuat: memuat ?? this.memuat,
      error: identical(error, _tidakDiubah) ? this.error : error as String?,
      direset: direset ?? this.direset,
      data: data ?? this.data,
    );
  }
}

// ============================================================
// BLOC
// ============================================================

class DashboardPengurusBloc
    extends Bloc<DashboardPengurusEvent, DashboardPengurusState> {
  final DashboardPengurusService service;

  DashboardPengurusBloc({required this.service})
      : super(const DashboardPengurusState()) {
    on<DashboardPengurusDimuat>(_onDimuat);
    on<DashboardPengurusDireset>(_onDireset);

    penandaPresensiSelesai.addListener(_saatPresensiSelesai);
  }

  void _saatPresensiSelesai() {
    if (!isClosed) add(const DashboardPengurusDireset());
  }

  @override
  Future<void> close() {
    penandaPresensiSelesai.removeListener(_saatPresensiSelesai);
    return super.close();
  }

  Future<void> _onDimuat(
    DashboardPengurusDimuat event,
    Emitter<DashboardPengurusState> emit,
  ) async {
    emit(state.salin(memuat: true, error: null));

    try {
      final data = await service.ambil(lewatiPresensi: state.direset);
      emit(state.salin(memuat: false, data: data));
    } catch (e) {
      emit(state.salin(memuat: false, error: e.toString()));
    }
  }

  void _onDireset(
    DashboardPengurusDireset event,
    Emitter<DashboardPengurusState> emit,
  ) {
    emit(state.salin(direset: true, data: state.data.tanpaPresensi()));
  }
}