import 'package:flutter_bloc/flutter_bloc.dart';

import '../pages/admin/kegiatan/kegiatan_model.dart';
import '../pages/admin/kegiatan/kegiatan_service.dart';

const Object _tidakDiubah = Object();

// ============================================================
// DAFTAR KEGIATAN
// ============================================================

abstract class KegiatanEvent {
  const KegiatanEvent();
}

class KegiatanDimuat extends KegiatanEvent {
  const KegiatanDimuat();
}

class KegiatanKataCariDiubah extends KegiatanEvent {
  final String kata;
  const KegiatanKataCariDiubah(this.kata);
}

/// nilai: 'semua', 'aktif', atau 'nonaktif'.
class KegiatanFilterDipilih extends KegiatanEvent {
  final String nilai;
  const KegiatanFilterDipilih(this.nilai);
}

class KegiatanUrutanDibalik extends KegiatanEvent {
  const KegiatanUrutanDibalik();
}

class KegiatanState {
  final List<Kegiatan> kegiatan;
  final bool memuat;
  final String? error;
  final String kataCari;
  final String filter;
  final bool urutNaik;

  const KegiatanState({
    this.kegiatan = const [],
    this.memuat = true,
    this.error,
    this.kataCari = '',
    this.filter = 'semua',
    this.urutNaik = true,
  });

  int get jumlahAktif => kegiatan.where((k) => k.aktif).length;

  /// Daftar setelah cari, filter, dan urutan diterapkan.
  List<Kegiatan> get tersaring {
    final kata = kataCari.trim().toLowerCase();

    final hasil = kegiatan.where((k) {
      if (filter == 'aktif' && !k.aktif) return false;
      if (filter == 'nonaktif' && k.aktif) return false;
      if (kata.isEmpty) return true;

      return k.namaKegiatan.toLowerCase().contains(kata) ||
          (k.deskripsi ?? '').toLowerCase().contains(kata);
    }).toList();

    hasil.sort(
      (a, b) =>
          a.namaKegiatan.toLowerCase().compareTo(b.namaKegiatan.toLowerCase()),
    );

    return urutNaik ? hasil : hasil.reversed.toList();
  }

  KegiatanState salin({
    List<Kegiatan>? kegiatan,
    bool? memuat,
    Object? error = _tidakDiubah,
    String? kataCari,
    String? filter,
    bool? urutNaik,
  }) {
    return KegiatanState(
      kegiatan: kegiatan ?? this.kegiatan,
      memuat: memuat ?? this.memuat,
      error: identical(error, _tidakDiubah) ? this.error : error as String?,
      kataCari: kataCari ?? this.kataCari,
      filter: filter ?? this.filter,
      urutNaik: urutNaik ?? this.urutNaik,
    );
  }
}

class KegiatanBloc extends Bloc<KegiatanEvent, KegiatanState> {
  final KegiatanService service;

  KegiatanBloc({required this.service}) : super(const KegiatanState()) {
    on<KegiatanDimuat>(_onDimuat);
    on<KegiatanKataCariDiubah>(
      (event, emit) => emit(state.salin(kataCari: event.kata)),
    );
    on<KegiatanFilterDipilih>(
      (event, emit) => emit(state.salin(filter: event.nilai)),
    );
    on<KegiatanUrutanDibalik>(
      (event, emit) => emit(state.salin(urutNaik: !state.urutNaik)),
    );
  }

  Future<void> _onDimuat(
    KegiatanDimuat event,
    Emitter<KegiatanState> emit,
  ) async {
    emit(state.salin(memuat: true, error: null));

    try {
      final data = await service.ambilSemua();
      emit(state.salin(kegiatan: data, memuat: false));
    } catch (e) {
      emit(
        state.salin(
          memuat: false,
          error: e is KegiatanException
              ? e.pesan
              : 'Gagal memuat data kegiatan. Tarik layar ke bawah untuk mencoba lagi.',
        ),
      );
    }
  }
}

// ============================================================
// FORM KEGIATAN
// ============================================================

abstract class FormKegiatanEvent {
  const FormKegiatanEvent();
}

class FormKegiatanSimpanDitekan extends FormKegiatanEvent {
  final String nama;
  final String deskripsi;
  final bool aktif;

  const FormKegiatanSimpanDitekan({
    required this.nama,
    required this.deskripsi,
    required this.aktif,
  });
}

class FormKegiatanHapusDitekan extends FormKegiatanEvent {
  const FormKegiatanHapusDitekan();
}

class FormKegiatanState {
  final bool bekerja;

  /// Hanya berlaku untuk satu emisi: pesan error (snackbar merah).
  final String? error;

  /// Hanya berlaku untuk satu emisi: aksi berhasil, halaman ditutup
  /// dengan pesan ini.
  final String? selesai;

  const FormKegiatanState({
    this.bekerja = false,
    this.error,
    this.selesai,
  });
}

class FormKegiatanBloc extends Bloc<FormKegiatanEvent, FormKegiatanState> {
  final KegiatanService service;

  /// null = mode tambah, terisi = mode edit.
  final Kegiatan? kegiatan;

  FormKegiatanBloc({required this.service, this.kegiatan})
      : super(const FormKegiatanState()) {
    on<FormKegiatanSimpanDitekan>(_onSimpan);
    on<FormKegiatanHapusDitekan>(_onHapus);
  }

  bool get _modeEdit => kegiatan != null;

  Future<void> _jalankan(
    Emitter<FormKegiatanState> emit,
    Future<void> Function() aksi,
    String pesanSukses,
  ) async {
    emit(const FormKegiatanState(bekerja: true));

    try {
      await aksi();
      emit(FormKegiatanState(selesai: pesanSukses));
    } on KegiatanException catch (e) {
      emit(FormKegiatanState(error: e.pesan));
    } catch (_) {
      emit(const FormKegiatanState(error: 'Terjadi kesalahan. Coba lagi.'));
    }
  }

  Future<void> _onSimpan(
    FormKegiatanSimpanDitekan event,
    Emitter<FormKegiatanState> emit,
  ) async {
    if (state.bekerja) return;

    await _jalankan(emit, () async {
      if (_modeEdit) {
        await service.perbarui(
          id: kegiatan!.id,
          nama: event.nama,
          deskripsi: event.deskripsi,
          aktif: event.aktif,
        );
      } else {
        await service.tambah(
          nama: event.nama,
          deskripsi: event.deskripsi,
          aktif: event.aktif,
        );
      }
    }, _modeEdit ? 'Perubahan disimpan.' : 'Kegiatan ditambahkan.');
  }

  Future<void> _onHapus(
    FormKegiatanHapusDitekan event,
    Emitter<FormKegiatanState> emit,
  ) async {
    if (state.bekerja || !_modeEdit) return;

    await _jalankan(
      emit,
      () => service.hapus(kegiatan!.id),
      'Kegiatan dihapus.',
    );
  }
}