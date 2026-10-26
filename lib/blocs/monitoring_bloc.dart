import 'package:flutter_bloc/flutter_bloc.dart';

import '../pages/pengasuh/monitoring/monitoring_service.dart';

// ============================================================
// EVENT
// ============================================================

abstract class MonitoringEvent {
  const MonitoringEvent();
}

/// Muat (atau muat ulang) data untuk periode yang sedang dipilih.
class MonitoringDimuat extends MonitoringEvent {
  const MonitoringDimuat();
}

/// Pilih periode. [indeks] mengacu ke daftarJenis milik Bloc.
/// Untuk jenis 'custom', kirim [custom] dari pemilih tanggal.
class MonitoringPeriodeDipilih extends MonitoringEvent {
  final int indeks;
  final Rentang? custom;

  const MonitoringPeriodeDipilih(this.indeks, {this.custom});
}

// ============================================================
// STATE
// ============================================================

class MonitoringState {
  final int periode;
  final Rentang rentang;
  final bool memuat;
  final String? error;
  final HasilMonitoring? hasil;

  /// Rata-rata kepatuhan 7 hari terakhir (hanya diisi kalau denganTren).
  final List<double> tren;

  const MonitoringState({
    required this.periode,
    required this.rentang,
    this.memuat = false,
    this.error,
    this.hasil,
    this.tren = const [],
  });
}

// ============================================================
// BLOC
// ============================================================

class MonitoringBloc extends Bloc<MonitoringEvent, MonitoringState> {
  final MonitoringService service;
  final List<String> daftarJenis;
  final bool denganTren;

  MonitoringBloc({
    required this.service,
    required this.daftarJenis,
    int periodeAwal = 0,
    this.denganTren = false,
  }) : super(
          MonitoringState(
            periode: periodeAwal,
            rentang: MonitoringService.untuk(daftarJenis[periodeAwal]),
            memuat: true,
          ),
        ) {
    on<MonitoringDimuat>((event, emit) => _muat(emit));
    on<MonitoringPeriodeDipilih>(_onPeriodeDipilih);
  }

  Future<void> _onPeriodeDipilih(
    MonitoringPeriodeDipilih event,
    Emitter<MonitoringState> emit,
  ) async {
    final jenis = daftarJenis[event.indeks];

    Rentang rentang;
    if (jenis == 'custom') {
      if (event.custom == null) return;
      rentang = event.custom!;
    } else {
      rentang = MonitoringService.untuk(jenis);
    }

    emit(
      MonitoringState(
        periode: event.indeks,
        rentang: rentang,
        memuat: true,
        hasil: state.hasil,
        tren: state.tren,
      ),
    );

    await _muat(emit);
  }

  Future<void> _muat(Emitter<MonitoringState> emit) async {
    final periode = state.periode;
    final rentang = state.rentang;

    emit(
      MonitoringState(
        periode: periode,
        rentang: rentang,
        memuat: true,
        hasil: state.hasil,
        tren: state.tren,
      ),
    );

    try {
      final hasil = await service.ambil(rentang.mulai, rentang.akhir);

      final tren = <double>[];
      if (denganTren) {
        final n = DateTime.now();
        final hariIni = DateTime(n.year, n.month, n.day);
        final tujuhHari = hariIni.subtract(const Duration(days: 6));
        final minggu = await service.ambil(tujuhHari, hariIni);

        if (minggu.kamar.isNotEmpty) {
          for (var i = 0; i < minggu.jumlahHari; i++) {
            var jumlah = 0.0;
            for (final k in minggu.kamar) {
              jumlah += k.perHari[i];
            }
            tren.add(jumlah / minggu.kamar.length);
          }
        }
      }

      emit(
        MonitoringState(
          periode: periode,
          rentang: rentang,
          hasil: hasil,
          tren: tren,
        ),
      );
    } catch (e) {
      emit(
        MonitoringState(
          periode: periode,
          rentang: rentang,
          error: e.toString(),
        ),
      );
    }
  }
}