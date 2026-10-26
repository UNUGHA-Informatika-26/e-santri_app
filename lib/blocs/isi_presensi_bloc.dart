import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/offline/presensi_offline.dart';
import '../pages/pengurus/presensi/presensi_service.dart';

// ============================================================
// EVENT
// ============================================================

abstract class IsiPresensiEvent {
  const IsiPresensiEvent();
}

class IsiPresensiDimuat extends IsiPresensiEvent {
  const IsiPresensiDimuat();
}

class IsiPresensiTanggalDipilih extends IsiPresensiEvent {
  final DateTime tanggal;
  const IsiPresensiTanggalDipilih(this.tanggal);
}

class IsiPresensiKegiatanDipilih extends IsiPresensiEvent {
  final KegiatanPilihan kegiatan;
  const IsiPresensiKegiatanDipilih(this.kegiatan);
}

class IsiPresensiLanjutDitekan extends IsiPresensiEvent {
  const IsiPresensiLanjutDitekan();
}

class IsiPresensiKembaliDitekan extends IsiPresensiEvent {
  const IsiPresensiKembaliDitekan();
}

class IsiPresensiStatusDipilih extends IsiPresensiEvent {
  final String santriId;
  final String status;
  const IsiPresensiStatusDipilih(this.santriId, this.status);
}

class IsiPresensiKeteranganDiubah extends IsiPresensiEvent {
  final String santriId;
  final String teks;
  const IsiPresensiKeteranganDiubah(this.santriId, this.teks);
}

class IsiPresensiSimpanDitekan extends IsiPresensiEvent {
  const IsiPresensiSimpanDitekan();
}

// ============================================================
// STATE
// ============================================================

/// Ringkasan setelah simpan berhasil (dipakai halaman berhasil).
class HasilSimpanPresensi {
  final DateTime tanggal;
  final String kegiatan;
  final String kamar;
  final int hadir;
  final int izin;
  final int sakit;
  final int alfa;

  /// true = tersimpan di HP dan menunggu internet untuk dikirim.
  final bool menunggu;

  const HasilSimpanPresensi({
    required this.tanggal,
    required this.kegiatan,
    required this.kamar,
    required this.hadir,
    required this.izin,
    required this.sakit,
    required this.alfa,
    this.menunggu = false,
  });
}

const Object _tidakDiubah = Object();

class IsiPresensiState {
  final int langkah;
  final bool memuat;
  final bool menyimpan;
  final String? error;
  final KamarTugas? kamar;
  final List<KegiatanPilihan> daftarKegiatan;
  final KegiatanPilihan? kegiatan;
  final DateTime tanggal;
  final List<SantriPresensi> santri;
  final bool laporanSudahAda;

  /// true = data kamar/santri dibaca dari cache karena tanpa internet.
  final bool offline;

  /// santriId -> hadir/izin/sakit/alfa
  final Map<String, String> status;

  /// santriId -> keterangan
  final Map<String, String> keterangan;

  /// Hanya berlaku untuk satu emisi (pesan snackbar).
  final String? pesan;

  /// Hanya berlaku untuk satu emisi (simpan berhasil).
  final HasilSimpanPresensi? hasilSimpan;

  const IsiPresensiState({
    this.langkah = 1,
    this.memuat = true,
    this.menyimpan = false,
    this.error,
    this.kamar,
    this.daftarKegiatan = const [],
    this.kegiatan,
    required this.tanggal,
    this.santri = const [],
    this.laporanSudahAda = false,
    this.offline = false,
    this.status = const {},
    this.keterangan = const {},
    this.pesan,
    this.hasilSimpan,
  });

  /// pesan dan hasilSimpan tidak dibawa ke emisi berikutnya.
  IsiPresensiState salin({
    int? langkah,
    bool? memuat,
    bool? menyimpan,
    Object? error = _tidakDiubah,
    Object? kamar = _tidakDiubah,
    List<KegiatanPilihan>? daftarKegiatan,
    Object? kegiatan = _tidakDiubah,
    DateTime? tanggal,
    List<SantriPresensi>? santri,
    bool? laporanSudahAda,
    bool? offline,
    Map<String, String>? status,
    Map<String, String>? keterangan,
    String? pesan,
    HasilSimpanPresensi? hasilSimpan,
  }) {
    return IsiPresensiState(
      langkah: langkah ?? this.langkah,
      memuat: memuat ?? this.memuat,
      menyimpan: menyimpan ?? this.menyimpan,
      error: identical(error, _tidakDiubah) ? this.error : error as String?,
      kamar: identical(kamar, _tidakDiubah)
          ? this.kamar
          : kamar as KamarTugas?,
      daftarKegiatan: daftarKegiatan ?? this.daftarKegiatan,
      kegiatan: identical(kegiatan, _tidakDiubah)
          ? this.kegiatan
          : kegiatan as KegiatanPilihan?,
      tanggal: tanggal ?? this.tanggal,
      santri: santri ?? this.santri,
      laporanSudahAda: laporanSudahAda ?? this.laporanSudahAda,
      offline: offline ?? this.offline,
      status: status ?? this.status,
      keterangan: keterangan ?? this.keterangan,
      pesan: pesan,
      hasilSimpan: hasilSimpan,
    );
  }
}

// ============================================================
// BLOC
// ============================================================

class IsiPresensiBloc extends Bloc<IsiPresensiEvent, IsiPresensiState> {
  static const _opsiStatus = ['hadir', 'izin', 'sakit', 'alfa'];

  final PresensiService service;

  IsiPresensiBloc({required this.service})
      : super(IsiPresensiState(tanggal: DateTime.now())) {
    on<IsiPresensiDimuat>(_onDimuat);
    on<IsiPresensiTanggalDipilih>(_onTanggalDipilih);
    on<IsiPresensiKegiatanDipilih>(_onKegiatanDipilih);
    on<IsiPresensiLanjutDitekan>(_onLanjut);
    on<IsiPresensiKembaliDitekan>(
      (event, emit) => emit(state.salin(langkah: 1)),
    );
    on<IsiPresensiStatusDipilih>(_onStatusDipilih);
    on<IsiPresensiKeteranganDiubah>(_onKeteranganDiubah);
    on<IsiPresensiSimpanDitekan>(_onSimpan);

    // Kirim antrean yang menunggu, dan pantau kembalinya internet.
    SinkronPresensi.instance.mulai();
  }

  String _tgl(DateTime t) => PresensiService.formatTanggalDb(t);

  /// Status laporan hanya info tambahan, jadi error diabaikan.
  Future<bool> _adaLaporan(
    KamarTugas? kamar,
    KegiatanPilihan? kegiatan,
    DateTime tanggal,
    bool nilaiLama,
  ) async {
    if (kamar == null || kegiatan == null) return false;

    try {
      final tersimpan = await service.ambilTersimpan(
        kamarId: kamar.id,
        kegiatanId: kegiatan.id,
        tanggal: tanggal,
      );
      if (tersimpan.isNotEmpty) return true;
    } catch (_) {
      // Lanjut cek antrean di HP.
    }

    final antre = await AntreanPresensi.cari(
      kamar.id,
      kegiatan.id,
      _tgl(tanggal),
    );
    return antre != null || nilaiLama;
  }

  Future<void> _onDimuat(
    IsiPresensiDimuat event,
    Emitter<IsiPresensiState> emit,
  ) async {
    emit(state.salin(memuat: true, error: null));

    try {
      final kamar = await service.ambilKamarTugas();
      final daftar = await service.ambilKegiatanAktif();

      var santri = <SantriPresensi>[];
      if (kamar != null) {
        santri = await service.ambilSantriKamar(kamar.id);
      }

      await AntreanPresensi.simpanCache(kamar, daftar, santri);

      final kegiatan = daftar.isNotEmpty ? daftar.first : null;
      final ada = await _adaLaporan(kamar, kegiatan, state.tanggal, false);

      emit(
        state.salin(
          memuat: false,
          offline: false,
          kamar: kamar,
          daftarKegiatan: daftar,
          kegiatan: kegiatan,
          santri: santri,
          laporanSudahAda: ada,
        ),
      );
    } catch (e) {
      // Ditolak server atau sesi hilang: tampilkan error biasa.
      // Selain itu dianggap tanpa internet: pakai cache di HP.
      final cache =
          e is PresensiException ? null : await AntreanPresensi.bacaCache();

      if (cache == null) {
        emit(
          state.salin(
            memuat: false,
            error: e is PresensiException
                ? e.pesan
                : 'Tidak ada internet dan belum ada data tersimpan di HP. '
                    'Buka aplikasi sekali saat online.',
          ),
        );
        return;
      }

      final kegiatan =
          cache.kegiatan.isNotEmpty ? cache.kegiatan.first : null;
      final ada =
          await _adaLaporan(cache.kamar, kegiatan, state.tanggal, false);

      emit(
        state.salin(
          memuat: false,
          offline: true,
          kamar: cache.kamar,
          daftarKegiatan: cache.kegiatan,
          kegiatan: kegiatan,
          santri: cache.santri,
          laporanSudahAda: ada,
        ),
      );
    }
  }

  Future<void> _onTanggalDipilih(
    IsiPresensiTanggalDipilih event,
    Emitter<IsiPresensiState> emit,
  ) async {
    emit(state.salin(tanggal: event.tanggal));

    final ada = await _adaLaporan(
      state.kamar,
      state.kegiatan,
      event.tanggal,
      false,
    );
    emit(state.salin(laporanSudahAda: ada));
  }

  Future<void> _onKegiatanDipilih(
    IsiPresensiKegiatanDipilih event,
    Emitter<IsiPresensiState> emit,
  ) async {
    emit(state.salin(kegiatan: event.kegiatan));

    final ada = await _adaLaporan(
      state.kamar,
      event.kegiatan,
      state.tanggal,
      false,
    );
    emit(state.salin(laporanSudahAda: ada));
  }

  Future<void> _onLanjut(
    IsiPresensiLanjutDitekan event,
    Emitter<IsiPresensiState> emit,
  ) async {
    final kamar = state.kamar;
    final kegiatan = state.kegiatan;
    if (kamar == null || kegiatan == null) return;

    if (state.santri.isEmpty) {
      emit(state.salin(pesan: 'Kamar ini belum punya santri aktif.'));
      return;
    }

    // Dari server (kalau ada internet).
    var tersimpan = <String, PresensiTersimpan>{};
    try {
      tersimpan = await service.ambilTersimpan(
        kamarId: kamar.id,
        kegiatanId: kegiatan.id,
        tanggal: state.tanggal,
      );
    } catch (e) {
      if (e is PresensiException) {
        emit(state.salin(pesan: e.pesan));
        return;
      }
      // Tanpa internet: lanjut dengan formulir kosong / data antrean.
    }

    // Yang menunggu di HP adalah isian terbaru, jadi menimpa data server.
    final antre = await AntreanPresensi.cari(
      kamar.id,
      kegiatan.id,
      _tgl(state.tanggal),
    );

    final status = <String, String>{};
    final keterangan = <String, String>{};

    for (final s in state.santri) {
      final t = tersimpan[s.id];
      if (t != null && _opsiStatus.contains(t.status)) {
        status[s.id] = t.status;
      }
      keterangan[s.id] = t?.keterangan ?? '';

      final st = antre?.status[s.id];
      if (st != null && _opsiStatus.contains(st)) {
        status[s.id] = st;
        keterangan[s.id] = antre?.keterangan[s.id] ?? '';
      }
    }

    emit(state.salin(langkah: 2, status: status, keterangan: keterangan));
  }

  void _onStatusDipilih(
    IsiPresensiStatusDipilih event,
    Emitter<IsiPresensiState> emit,
  ) {
    emit(
      state.salin(
        status: {...state.status, event.santriId: event.status},
      ),
    );
  }

  void _onKeteranganDiubah(
    IsiPresensiKeteranganDiubah event,
    Emitter<IsiPresensiState> emit,
  ) {
    emit(
      state.salin(
        keterangan: {...state.keterangan, event.santriId: event.teks},
      ),
    );
  }

  HasilSimpanPresensi _ringkasan(
    KamarTugas kamar,
    KegiatanPilihan kegiatan, {
    required bool menunggu,
  }) {
    final nilai = state.status.values.toList();

    return HasilSimpanPresensi(
      tanggal: state.tanggal,
      kegiatan: kegiatan.nama,
      kamar: kamar.namaKamar,
      hadir: nilai.where((s) => s == 'hadir').length,
      izin: nilai.where((s) => s == 'izin').length,
      sakit: nilai.where((s) => s == 'sakit').length,
      alfa: nilai.where((s) => s == 'alfa').length,
      menunggu: menunggu,
    );
  }

  Future<void> _onSimpan(
    IsiPresensiSimpanDitekan event,
    Emitter<IsiPresensiState> emit,
  ) async {
    final kamar = state.kamar;
    final kegiatan = state.kegiatan;
    if (kamar == null || kegiatan == null || state.menyimpan) return;

    if (state.status.length < state.santri.length) {
      emit(
        state.salin(
          pesan: 'Masih ada ${state.santri.length - state.status.length} '
              'santri yang belum diisi.',
        ),
      );
      return;
    }

    emit(state.salin(menyimpan: true));

    final tgl = _tgl(state.tanggal);

    try {
      await service.simpan(
        kamarId: kamar.id,
        kegiatanId: kegiatan.id,
        tanggal: state.tanggal,
        status: Map<String, String>.from(state.status),
        keterangan: Map<String, String>.from(state.keterangan),
      );

      // Sudah di server, jadi antrean lama untuk laporan ini tidak perlu.
      await AntreanPresensi.hapus(
        AntreanPresensi.kunci(kamar.id, kegiatan.id, tgl),
      );
      await SinkronPresensi.instance.segarkan();

      emit(
        state.salin(
          menyimpan: false,
          hasilSimpan: _ringkasan(kamar, kegiatan, menunggu: false),
        ),
      );
    } on PresensiException catch (e) {
      // Ditolak server (bukan masalah internet): jangan masuk antrean.
      emit(state.salin(menyimpan: false, pesan: e.pesan));
    } catch (_) {
      // Tanpa internet: simpan di HP, kirim otomatis nanti.
      try {
        await AntreanPresensi.tambah(
          ItemAntrean(
            kamarId: kamar.id,
            kegiatanId: kegiatan.id,
            tanggal: tgl,
            namaKamar: kamar.namaKamar,
            namaKegiatan: kegiatan.nama,
            status: Map<String, String>.from(state.status),
            keterangan: Map<String, String>.from(state.keterangan),
          ),
        );
        await SinkronPresensi.instance.segarkan();

        emit(
          state.salin(
            menyimpan: false,
            pesan: 'Tidak ada internet. Presensi tersimpan di HP dan akan '
                'dikirim otomatis saat internet kembali.',
            hasilSimpan: _ringkasan(kamar, kegiatan, menunggu: true),
          ),
        );
      } catch (_) {
        emit(
          state.salin(
            menyimpan: false,
            pesan: 'Gagal menyimpan di HP. Coba lagi.',
          ),
        );
      }
    }
  }
}