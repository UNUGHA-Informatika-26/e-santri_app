import 'package:flutter_bloc/flutter_bloc.dart';

import '../pages/admin/kamar/kamar_model.dart';
import '../pages/admin/kamar/kamar_service.dart';
import '../pages/admin/santri/santri_model.dart';

const Object _tidakDiubah = Object();

// ============================================================
// DAFTAR KAMAR
// ============================================================

abstract class KamarEvent {
  const KamarEvent();
}

class KamarDimuat extends KamarEvent {
  const KamarDimuat();
}

class KamarKataCariDiubah extends KamarEvent {
  final String kata;
  const KamarKataCariDiubah(this.kata);
}

/// nilai: 'semua', 'aktif', atau 'nonaktif'.
class KamarFilterDipilih extends KamarEvent {
  final String nilai;
  const KamarFilterDipilih(this.nilai);
}

class KamarState {
  final List<Kamar> kamar;
  final bool memuat;
  final String? error;
  final String kataCari;
  final String filter;

  const KamarState({
    this.kamar = const [],
    this.memuat = true,
    this.error,
    this.kataCari = '',
    this.filter = 'semua',
  });

  List<Kamar> get tersaring {
    final kata = kataCari.trim().toLowerCase();

    return kamar.where((k) {
      if (filter == 'aktif' && !k.aktif) return false;
      if (filter == 'nonaktif' && k.aktif) return false;
      if (kata.isEmpty) return true;

      return k.namaKamar.toLowerCase().contains(kata);
    }).toList();
  }

  KamarState salin({
    List<Kamar>? kamar,
    bool? memuat,
    Object? error = _tidakDiubah,
    String? kataCari,
    String? filter,
  }) {
    return KamarState(
      kamar: kamar ?? this.kamar,
      memuat: memuat ?? this.memuat,
      error: identical(error, _tidakDiubah) ? this.error : error as String?,
      kataCari: kataCari ?? this.kataCari,
      filter: filter ?? this.filter,
    );
  }
}

class KamarBloc extends Bloc<KamarEvent, KamarState> {
  final KamarService service;

  KamarBloc({required this.service}) : super(const KamarState()) {
    on<KamarDimuat>(_onDimuat);
    on<KamarKataCariDiubah>(
      (event, emit) => emit(state.salin(kataCari: event.kata)),
    );
    on<KamarFilterDipilih>(
      (event, emit) => emit(state.salin(filter: event.nilai)),
    );
  }

  Future<void> _onDimuat(KamarDimuat event, Emitter<KamarState> emit) async {
    emit(state.salin(memuat: true, error: null));

    try {
      final data = await service.ambilSemua();
      emit(state.salin(kamar: data, memuat: false));
    } catch (_) {
      emit(
        state.salin(
          memuat: false,
          error:
              'Gagal memuat data kamar. Tarik layar ke bawah untuk mencoba lagi.',
        ),
      );
    }
  }
}

// ============================================================
// DETAIL KAMAR
// ============================================================

abstract class DetailKamarEvent {
  const DetailKamarEvent();
}

class DetailKamarPenghuniDimuat extends DetailKamarEvent {
  const DetailKamarPenghuniDimuat();
}

class DetailKamarStatusDitekan extends DetailKamarEvent {
  const DetailKamarStatusDitekan();
}

class DetailKamarHapusDitekan extends DetailKamarEvent {
  const DetailKamarHapusDitekan();
}

class DetailKamarState {
  final List<Santri> penghuni;
  final bool memuat;
  final bool gagalMuat;
  final bool bekerja;

  /// Hanya berlaku untuk satu emisi: pesan error (snackbar merah).
  final String? error;

  /// Hanya berlaku untuk satu emisi: aksi berhasil, halaman ditutup
  /// dengan pesan ini.
  final String? selesai;

  const DetailKamarState({
    this.penghuni = const [],
    this.memuat = true,
    this.gagalMuat = false,
    this.bekerja = false,
    this.error,
    this.selesai,
  });

  DetailKamarState salin({
    List<Santri>? penghuni,
    bool? memuat,
    bool? gagalMuat,
    bool? bekerja,
    String? error,
    String? selesai,
  }) {
    return DetailKamarState(
      penghuni: penghuni ?? this.penghuni,
      memuat: memuat ?? this.memuat,
      gagalMuat: gagalMuat ?? this.gagalMuat,
      bekerja: bekerja ?? this.bekerja,
      error: error,
      selesai: selesai,
    );
  }
}

class DetailKamarBloc extends Bloc<DetailKamarEvent, DetailKamarState> {
  final KamarService service;
  final Kamar kamar;

  DetailKamarBloc({required this.service, required this.kamar})
      : super(const DetailKamarState()) {
    on<DetailKamarPenghuniDimuat>(_onPenghuni);
    on<DetailKamarStatusDitekan>(_onStatus);
    on<DetailKamarHapusDitekan>(_onHapus);
  }

  Future<void> _onPenghuni(
    DetailKamarPenghuniDimuat event,
    Emitter<DetailKamarState> emit,
  ) async {
    emit(state.salin(memuat: true, gagalMuat: false));

    try {
      final data = await service.ambilPenghuni(kamar.id);
      emit(state.salin(penghuni: data, memuat: false));
    } catch (_) {
      emit(state.salin(memuat: false, gagalMuat: true));
    }
  }

  Future<void> _jalankan(
    Emitter<DetailKamarState> emit,
    Future<void> Function() aksi,
    String pesanSukses,
  ) async {
    if (state.bekerja) return;

    emit(state.salin(bekerja: true));

    try {
      await aksi();
      emit(state.salin(bekerja: false, selesai: pesanSukses));
    } on KamarException catch (e) {
      emit(state.salin(bekerja: false, error: e.pesan));
    } catch (_) {
      emit(state.salin(bekerja: false, error: 'Terjadi kesalahan. Coba lagi.'));
    }
  }

  Future<void> _onStatus(
    DetailKamarStatusDitekan event,
    Emitter<DetailKamarState> emit,
  ) async {
    final jadiNonaktif = kamar.aktif;

    await _jalankan(
      emit,
      () => service.ubahStatusAktif(kamar.id, !kamar.aktif),
      jadiNonaktif ? 'Kamar dinonaktifkan.' : 'Kamar diaktifkan kembali.',
    );
  }

  Future<void> _onHapus(
    DetailKamarHapusDitekan event,
    Emitter<DetailKamarState> emit,
  ) async {
    await _jalankan(emit, () => service.hapus(kamar.id), 'Kamar dihapus.');
  }
}

// ============================================================
// FORM KAMAR
// ============================================================

abstract class FormKamarEvent {
  const FormKamarEvent();
}

class FormKamarDimuat extends FormKamarEvent {
  const FormKamarDimuat();
}

class FormKamarGenderDiubah extends FormKamarEvent {
  final String? gender;
  const FormKamarGenderDiubah(this.gender);
}

class FormKamarPengurusDipilih extends FormKamarEvent {
  final String? pengurusId;
  const FormKamarPengurusDipilih(this.pengurusId);
}

class FormKamarSimpanDitekan extends FormKamarEvent {
  final String nama;
  const FormKamarSimpanDitekan(this.nama);
}

class FormKamarState {
  final bool menyimpan;

  /// 'putra' atau 'putri'. Dipilih saat membuat kamar, tidak bisa diubah.
  final String? gender;

  final List<Pengurus> daftarPengurus;
  final bool memuatPengurus;
  final bool pengurusTermuat;
  final String? errorPengurus;
  final String? pengurusAwal;
  final String? pengurusDipilih;

  /// Hanya berlaku untuk satu emisi: pesan error (snackbar merah).
  final String? error;

  /// Hanya berlaku untuk satu emisi: simpan berhasil, halaman ditutup.
  final bool selesai;

  const FormKamarState({
    this.menyimpan = false,
    this.gender,
    this.daftarPengurus = const [],
    this.memuatPengurus = true,
    this.pengurusTermuat = false,
    this.errorPengurus,
    this.pengurusAwal,
    this.pengurusDipilih,
    this.error,
    this.selesai = false,
  });

  /// Pengurus yang gendernya sama dengan kamar.
  List<Pengurus> get pengurusSesuai =>
      daftarPengurus.where((p) => p.gender == gender).toList();

  FormKamarState salin({
    bool? menyimpan,
    Object? gender = _tidakDiubah,
    List<Pengurus>? daftarPengurus,
    bool? memuatPengurus,
    bool? pengurusTermuat,
    Object? errorPengurus = _tidakDiubah,
    Object? pengurusDipilih = _tidakDiubah,
    String? error,
    bool selesai = false,
  }) {
    return FormKamarState(
      menyimpan: menyimpan ?? this.menyimpan,
      gender: identical(gender, _tidakDiubah) ? this.gender : gender as String?,
      daftarPengurus: daftarPengurus ?? this.daftarPengurus,
      memuatPengurus: memuatPengurus ?? this.memuatPengurus,
      pengurusTermuat: pengurusTermuat ?? this.pengurusTermuat,
      errorPengurus: identical(errorPengurus, _tidakDiubah)
          ? this.errorPengurus
          : errorPengurus as String?,
      pengurusAwal: pengurusAwal,
      pengurusDipilih: identical(pengurusDipilih, _tidakDiubah)
          ? this.pengurusDipilih
          : pengurusDipilih as String?,
      error: error,
      selesai: selesai,
    );
  }
}

class FormKamarBloc extends Bloc<FormKamarEvent, FormKamarState> {
  final KamarService service;

  /// null = mode tambah, terisi = mode edit.
  final Kamar? kamar;

  FormKamarBloc({required this.service, this.kamar})
      : super(
          FormKamarState(
            gender: kamar?.gender,
            pengurusAwal: kamar?.pengurusId,
            pengurusDipilih: kamar?.pengurusId,
          ),
        ) {
    on<FormKamarDimuat>(_onDimuat);
    on<FormKamarGenderDiubah>(
      (event, emit) => emit(
        // Pilihan pengurus lama bisa tidak sesuai gender baru.
        state.salin(gender: event.gender, pengurusDipilih: null),
      ),
    );
    on<FormKamarPengurusDipilih>(
      (event, emit) => emit(state.salin(pengurusDipilih: event.pengurusId)),
    );
    on<FormKamarSimpanDitekan>(_onSimpan);
  }

  bool get _modeEdit => kamar != null;

  Future<void> _onDimuat(
    FormKamarDimuat event,
    Emitter<FormKamarState> emit,
  ) async {
    try {
      final daftar = await service.ambilDaftarPengurus();
      emit(
        state.salin(
          daftarPengurus: daftar,
          pengurusTermuat: true,
          memuatPengurus: false,
        ),
      );
    } catch (e) {
      emit(
        state.salin(
          errorPengurus: e is KamarException ? e.pesan : e.toString(),
          pengurusTermuat: false,
          memuatPengurus: false,
        ),
      );
    }
  }

  Future<void> _onSimpan(
    FormKamarSimpanDitekan event,
    Emitter<FormKamarState> emit,
  ) async {
    if (state.menyimpan) return;

    emit(state.salin(menyimpan: true));

    try {
      final String kamarId;

      if (_modeEdit) {
        kamarId = kamar!.id;
        await service.perbarui(kamarId, event.nama);
      } else {
        kamarId = await service.tambah(event.nama, state.gender!);
      }

      // Pengurus hanya diubah kalau daftarnya berhasil dimuat dan
      // pilihannya memang berbeda, supaya tidak terhapus tanpa sengaja.
      if (state.pengurusTermuat && state.pengurusDipilih != kamar?.pengurusId) {
        await service.tetapkanPengurus(kamarId, state.pengurusDipilih);
      }

      emit(state.salin(menyimpan: false, selesai: true));
    } on KamarException catch (e) {
      emit(state.salin(menyimpan: false, error: e.pesan));
    } catch (_) {
      emit(
        state.salin(
          menyimpan: false,
          error: 'Terjadi kesalahan saat menyimpan kamar.',
        ),
      );
    }
  }
}