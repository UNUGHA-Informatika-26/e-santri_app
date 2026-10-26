import 'package:flutter_bloc/flutter_bloc.dart';

import '../pages/admin/presensi/presensi_admin_service.dart';

const Object _tidakDiubah = Object();

// ============================================================
// DAFTAR PRESENSI ADMIN
// ============================================================

abstract class PresensiAdminEvent {
  const PresensiAdminEvent();
}

class PresensiAdminDimuat extends PresensiAdminEvent {
  const PresensiAdminDimuat();
}

class PresensiAdminTanggalDipilih extends PresensiAdminEvent {
  final DateTime tanggal;
  const PresensiAdminTanggalDipilih(this.tanggal);
}

class PresensiAdminKegiatanDipilih extends PresensiAdminEvent {
  final String? kegiatanId;
  const PresensiAdminKegiatanDipilih(this.kegiatanId);
}

class PresensiAdminKamarDipilih extends PresensiAdminEvent {
  final String? kamarId;
  const PresensiAdminKamarDipilih(this.kamarId);
}

class PresensiAdminState {
  final DateTime tanggal;
  final String? kegiatanId;
  final String? kamarId;
  final HasilPresensiHari? hasil;
  final bool memuat;
  final String? error;

  const PresensiAdminState({
    required this.tanggal,
    this.kegiatanId,
    this.kamarId,
    this.hasil,
    this.memuat = true,
    this.error,
  });

  /// Laporan setelah filter Kegiatan dan Kamar diterapkan.
  List<LaporanKamar> get tersaring {
    final h = hasil;
    if (h == null) return [];

    return h.laporan
        .where(
          (l) =>
              (kegiatanId == null || l.kegiatanId == kegiatanId) &&
              (kamarId == null || l.kamarId == kamarId),
        )
        .toList();
  }

  PresensiAdminState salin({
    DateTime? tanggal,
    Object? kegiatanId = _tidakDiubah,
    Object? kamarId = _tidakDiubah,
    Object? hasil = _tidakDiubah,
    bool? memuat,
    Object? error = _tidakDiubah,
  }) {
    return PresensiAdminState(
      tanggal: tanggal ?? this.tanggal,
      kegiatanId: identical(kegiatanId, _tidakDiubah)
          ? this.kegiatanId
          : kegiatanId as String?,
      kamarId: identical(kamarId, _tidakDiubah)
          ? this.kamarId
          : kamarId as String?,
      hasil: identical(hasil, _tidakDiubah)
          ? this.hasil
          : hasil as HasilPresensiHari?,
      memuat: memuat ?? this.memuat,
      error: identical(error, _tidakDiubah) ? this.error : error as String?,
    );
  }
}

class PresensiAdminBloc extends Bloc<PresensiAdminEvent, PresensiAdminState> {
  final PresensiAdminService service;

  PresensiAdminBloc({required this.service})
      : super(PresensiAdminState(tanggal: _hariIni())) {
    on<PresensiAdminDimuat>((event, emit) => _muat(emit));
    on<PresensiAdminTanggalDipilih>((event, emit) async {
      emit(
        state.salin(
          tanggal: DateTime(
            event.tanggal.year,
            event.tanggal.month,
            event.tanggal.day,
          ),
        ),
      );
      await _muat(emit);
    });
    on<PresensiAdminKegiatanDipilih>(
      (event, emit) => emit(state.salin(kegiatanId: event.kegiatanId)),
    );
    on<PresensiAdminKamarDipilih>(
      (event, emit) => emit(state.salin(kamarId: event.kamarId)),
    );
  }

  static DateTime _hariIni() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<void> _muat(Emitter<PresensiAdminState> emit) async {
    emit(state.salin(memuat: true, error: null));

    try {
      final hasil = await service.ambilHari(state.tanggal);
      emit(state.salin(memuat: false, hasil: hasil));
    } catch (e) {
      emit(state.salin(memuat: false, error: e.toString()));
    }
  }
}

// ============================================================
// DETAIL PRESENSI ADMIN
// ============================================================

abstract class DetailPresensiAdminEvent {
  const DetailPresensiAdminEvent();
}

class DetailPresensiAdminDimuat extends DetailPresensiAdminEvent {
  const DetailPresensiAdminDimuat();
}

class DetailPresensiAdminState {
  final List<BarisSantri> data;
  final bool memuat;
  final String? error;

  const DetailPresensiAdminState({
    this.data = const [],
    this.memuat = true,
    this.error,
  });
}

class DetailPresensiAdminBloc
    extends Bloc<DetailPresensiAdminEvent, DetailPresensiAdminState> {
  final PresensiAdminService service;
  final DateTime tanggal;
  final String kamarId;
  final String kegiatanId;

  DetailPresensiAdminBloc({
    required this.service,
    required this.tanggal,
    required this.kamarId,
    required this.kegiatanId,
  }) : super(const DetailPresensiAdminState()) {
    on<DetailPresensiAdminDimuat>(_onDimuat);
  }

  Future<void> _onDimuat(
    DetailPresensiAdminDimuat event,
    Emitter<DetailPresensiAdminState> emit,
  ) async {
    emit(DetailPresensiAdminState(data: state.data, memuat: true));

    try {
      final hasil = await service.ambilDetail(tanggal, kamarId, kegiatanId);
      emit(DetailPresensiAdminState(data: hasil, memuat: false));
    } catch (e) {
      emit(DetailPresensiAdminState(memuat: false, error: e.toString()));
    }
  }
}