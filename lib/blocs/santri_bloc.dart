import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/offline/antrean_santri.dart';
import '../core/offline/santri_cache.dart';
import '../pages/admin/santri/santri_model.dart';
import '../pages/admin/santri/santri_service.dart';

const Object _tidakDiubah = Object();

/// Pilihan jumlah data per halaman.
const List<int> pilihanPerHalaman = [5, 10, 20, 50, 100];

abstract class SantriEvent {
  const SantriEvent();
}

class SantriDimuat extends SantriEvent {
  const SantriDimuat();
}

class SantriKataCariDiubah extends SantriEvent {
  final String kata;
  const SantriKataCariDiubah(this.kata);
}

/// nilai: 'semua', 'aktif', atau 'nonaktif'.
class SantriFilterDipilih extends SantriEvent {
  final String nilai;
  const SantriFilterDipilih(this.nilai);
}

class SantriHalamanDiubah extends SantriEvent {
  final int halaman;
  const SantriHalamanDiubah(this.halaman);
}

class SantriPerHalamanDiubah extends SantriEvent {
  final int jumlah;
  const SantriPerHalamanDiubah(this.jumlah);
}

class SantriState {
  final List<Santri> santri;
  final bool memuat;
  final String? error;
  final String kataCari;
  final String filter;
  final bool offline;
  final int halaman;
  final int perHalaman;

  /// Santri baru yang menunggu dikirim (antrean di HP).
  final List<ItemAntreanSantri> menunggu;

  const SantriState({
    this.santri = const [],
    this.memuat = true,
    this.error,
    this.kataCari = '',
    this.filter = 'semua',
    this.offline = false,
    this.halaman = 1,
    this.perHalaman = 20,
    this.menunggu = const [],
  });

  List<Santri> get tersaring {
    final kata = kataCari.trim().toLowerCase();

    return santri.where((s) {
      if (filter == 'aktif' && !s.statusAktif) return false;
      if (filter == 'nonaktif' && s.statusAktif) return false;
      if (kata.isEmpty) return true;

      return s.namaLengkap.toLowerCase().contains(kata) ||
          s.nis.toLowerCase().contains(kata);
    }).toList();
  }

  int get totalHalaman {
    final n = tersaring.length;
    if (n == 0) return 1;
    return (n + perHalaman - 1) ~/ perHalaman;
  }

  int get halamanAman {
    final total = totalHalaman;
    if (halaman > total) return total;
    if (halaman < 1) return 1;
    return halaman;
  }

  List<Santri> get tampilHalaman {
    final semua = tersaring;
    final mulai = (halamanAman - 1) * perHalaman;
    if (mulai >= semua.length) return const [];
    final akhir = mulai + perHalaman;
    return semua.sublist(
      mulai,
      akhir > semua.length ? semua.length : akhir,
    );
  }

  SantriState salin({
    List<Santri>? santri,
    bool? memuat,
    Object? error = _tidakDiubah,
    String? kataCari,
    String? filter,
    bool? offline,
    int? halaman,
    int? perHalaman,
    List<ItemAntreanSantri>? menunggu,
  }) {
    return SantriState(
      santri: santri ?? this.santri,
      memuat: memuat ?? this.memuat,
      error: identical(error, _tidakDiubah) ? this.error : error as String?,
      kataCari: kataCari ?? this.kataCari,
      filter: filter ?? this.filter,
      offline: offline ?? this.offline,
      halaman: halaman ?? this.halaman,
      perHalaman: perHalaman ?? this.perHalaman,
      menunggu: menunggu ?? this.menunggu,
    );
  }
}

class SantriBloc extends Bloc<SantriEvent, SantriState> {
  final SantriService service;
  StreamSubscription<void>? _langgananSinkron;

  SantriBloc({required this.service}) : super(const SantriState()) {
    on<SantriDimuat>(_onDimuat);
    on<SantriKataCariDiubah>(
      (event, emit) => emit(state.salin(kataCari: event.kata, halaman: 1)),
    );
    on<SantriFilterDipilih>(
      (event, emit) => emit(state.salin(filter: event.nilai, halaman: 1)),
    );
    on<SantriHalamanDiubah>(
      (event, emit) => emit(state.salin(halaman: event.halaman)),
    );
    on<SantriPerHalamanDiubah>(
      (event, emit) =>
          emit(state.salin(perHalaman: event.jumlah, halaman: 1)),
    );

    // Muat ulang saat antrean selesai dikirim.
    _langgananSinkron = SinkronSantri.instance.selesai.listen((_) {
      if (!isClosed) add(const SantriDimuat());
    });
  }

  @override
  Future<void> close() {
    _langgananSinkron?.cancel();
    return super.close();
  }

  Future<void> _onDimuat(SantriDimuat event, Emitter<SantriState> emit) async {
    emit(state.salin(memuat: true, error: null));

    final menunggu = await AntreanSantri.semua();

    try {
      final data = await service.ambilSemua();
      await SantriCache.simpan(data);
      emit(
        state.salin(
          santri: data,
          memuat: false,
          offline: false,
          menunggu: menunggu,
        ),
      );
    } catch (_) {
      final cache = await SantriCache.baca();

      if (cache != null) {
        emit(
          state.salin(
            santri: cache,
            memuat: false,
            offline: true,
            menunggu: menunggu,
          ),
        );
      } else {
        emit(
          state.salin(
            memuat: false,
            menunggu: menunggu,
            error: 'Gagal memuat data santri. Tidak ada internet dan belum '
                'ada data tersimpan di HP. Tarik layar ke bawah untuk mencoba lagi.',
          ),
        );
      }
    }
  }
}