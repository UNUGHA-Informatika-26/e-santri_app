import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/supabase/supabase_config.dart';
import '../pages/pengurus/riwayat/riwayat_format.dart';

// ============================================================
// DATA MODEL
// ============================================================

class GrupRiwayat extends Equatable {
  final String tanggal;
  final String kegiatanId;
  final String namaKegiatan;
  final int hadir;
  final int izin;
  final int sakit;
  final int alfa;

  const GrupRiwayat({
    required this.tanggal,
    required this.kegiatanId,
    this.namaKegiatan = '-',
    this.hadir = 0,
    this.izin = 0,
    this.sakit = 0,
    this.alfa = 0,
  });

  int get total => hadir + izin + sakit + alfa;
  int get persen => total == 0 ? 0 : (hadir / total * 100).round();

  @override
  List<Object?> get props => [
        tanggal,
        kegiatanId,
        namaKegiatan,
        hadir,
        izin,
        sakit,
        alfa,
      ];
}

class SantriTidakHadir extends Equatable {
  final String nama;
  final String nis;
  final String keterangan;
  final String status;

  const SantriTidakHadir({
    required this.nama,
    required this.nis,
    required this.keterangan,
    required this.status,
  });

  @override
  List<Object?> get props => [nama, nis, keterangan, status];
}

// ============================================================
// BLOC RIWAYAT UTAMA
// ============================================================

abstract class RiwayatPengurusEvent extends Equatable {
  const RiwayatPengurusEvent();

  @override
  List<Object?> get props => [];
}

class RiwayatPengurusDimuat extends RiwayatPengurusEvent {
  const RiwayatPengurusDimuat();
}

class RiwayatPengurusFilterDiubah extends RiwayatPengurusEvent {
  final int filter;
  const RiwayatPengurusFilterDiubah(this.filter);

  @override
  List<Object?> get props => [filter];
}

class RiwayatPengurusState extends Equatable {
  final bool memuat;
  final String? error;
  final int filter; // 0 = Hari Ini, 1 = Minggu Ini, 2 = Bulan Ini
  final String? kamarId;
  final String? namaKamar;
  final List<GrupRiwayat> daftar;

  const RiwayatPengurusState({
    this.memuat = true,
    this.error,
    this.filter = 0,
    this.kamarId,
    this.namaKamar,
    this.daftar = const [],
  });

  RiwayatPengurusState salin({
    bool? memuat,
    Object? error = const Object(),
    int? filter,
    Object? kamarId = const Object(),
    Object? namaKamar = const Object(),
    List<GrupRiwayat>? daftar,
  }) {
    return RiwayatPengurusState(
      memuat: memuat ?? this.memuat,
      error: identical(error, const Object())
          ? this.error
          : error as String?,
      filter: filter ?? this.filter,
      kamarId: identical(kamarId, const Object())
          ? this.kamarId
          : kamarId as String?,
      namaKamar: identical(namaKamar, const Object())
          ? this.namaKamar
          : namaKamar as String?,
      daftar: daftar ?? this.daftar,
    );
  }

  @override
  List<Object?> get props => [memuat, error, filter, kamarId, namaKamar, daftar];
}

class RiwayatPengurusBloc
    extends Bloc<RiwayatPengurusEvent, RiwayatPengurusState> {
  RiwayatPengurusBloc() : super(const RiwayatPengurusState()) {
    on<RiwayatPengurusDimuat>(_onDimuat);
    on<RiwayatPengurusFilterDiubah>(_onFilterDiubah);
  }

  Future<void> _onFilterDiubah(
    RiwayatPengurusFilterDiubah event,
    Emitter<RiwayatPengurusState> emit,
  ) async {
    if (state.filter == event.filter) return;
    emit(state.salin(filter: event.filter));
    await _muatData(emit);
  }

  Future<void> _onDimuat(
    RiwayatPengurusDimuat event,
    Emitter<RiwayatPengurusState> emit,
  ) async {
    await _muatData(emit);
  }

  Future<void> _muatData(Emitter<RiwayatPengurusState> emit) async {
    emit(state.salin(memuat: true, error: null));

    try {
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

      if (kamarId == null) {
        emit(
          state.salin(
            memuat: false,
            kamarId: null,
            namaKamar: null,
            daftar: [],
          ),
        );
        return;
      }

      final dataKamar = await supabase
          .from('kamar')
          .select('nama_kamar')
          .eq('id', kamarId)
          .maybeSingle();

      final sekarang = DateTime.now();
      final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
      DateTime awal;
      if (state.filter == 1) {
        awal = hariIni.subtract(Duration(days: hariIni.weekday - 1));
      } else if (state.filter == 2) {
        awal = DateTime(hariIni.year, hariIni.month, 1);
      } else {
        awal = hariIni;
      }

      final dataPresensi = await supabase
          .from('presensi')
          .select('kegiatan_id, tanggal, status')
          .eq('kamar_id', kamarId)
          .gte('tanggal', formatTanggalDb(awal))
          .lte('tanggal', formatTanggalDb(hariIni))
          .order('tanggal', ascending: false);

      final tempGrup = <String, Map<String, dynamic>>{};
      for (final baris in dataPresensi) {
        final tanggal = baris['tanggal'] as String?;
        final kegiatanId = baris['kegiatan_id'] as String?;
        if (tanggal == null || kegiatanId == null) continue;

        final kunci = '$tanggal|$kegiatanId';
        final g = tempGrup.putIfAbsent(
          kunci,
          () => {
            'tanggal': tanggal,
            'kegiatanId': kegiatanId,
            'hadir': 0,
            'izin': 0,
            'sakit': 0,
            'alfa': 0,
          },
        );

        switch (baris['status'] as String?) {
          case 'hadir':
            g['hadir'] = (g['hadir'] as int) + 1;
            break;
          case 'izin':
            g['izin'] = (g['izin'] as int) + 1;
            break;
          case 'sakit':
            g['sakit'] = (g['sakit'] as int) + 1;
            break;
          case 'alfa':
            g['alfa'] = (g['alfa'] as int) + 1;
            break;
        }
      }

      final idKegiatan =
          tempGrup.values.map((g) => g['kegiatanId'] as String).toSet().toList();
      final namaPerId = <String, String>{};

      if (idKegiatan.isNotEmpty) {
        final dataKegiatan = await supabase
            .from('kegiatan')
            .select('id, nama_kegiatan')
            .inFilter('id', idKegiatan);

        for (final k in dataKegiatan) {
          namaPerId[k['id'] as String] =
              (k['nama_kegiatan'] as String?) ?? '-';
        }
      }

      final hasilDaftar = tempGrup.values.map((g) {
        final kegId = g['kegiatanId'] as String;
        return GrupRiwayat(
          tanggal: g['tanggal'] as String,
          kegiatanId: kegId,
          namaKegiatan: namaPerId[kegId] ?? '-',
          hadir: g['hadir'] as int,
          izin: g['izin'] as int,
          sakit: g['sakit'] as int,
          alfa: g['alfa'] as int,
        );
      }).toList();

      emit(
        state.salin(
          memuat: false,
          kamarId: kamarId,
          namaKamar: dataKamar?['nama_kamar'] as String?,
          daftar: hasilDaftar,
        ),
      );
    } catch (e) {
      emit(state.salin(memuat: false, error: e.toString()));
    }
  }
}

// ============================================================
// BLOC DETAIL RIWAYAT
// ============================================================

abstract class DetailRiwayatEvent extends Equatable {
  const DetailRiwayatEvent();

  @override
  List<Object?> get props => [];
}

class DetailRiwayatDimuat extends DetailRiwayatEvent {
  const DetailRiwayatDimuat();
}

class DetailRiwayatState extends Equatable {
  final bool memuat;
  final String? error;
  final int hadir;
  final int izin;
  final int sakit;
  final int alfa;
  final String waktu;
  final List<SantriTidakHadir> tidakHadir;

  const DetailRiwayatState({
    this.memuat = true,
    this.error,
    this.hadir = 0,
    this.izin = 0,
    this.sakit = 0,
    this.alfa = 0,
    this.waktu = '-',
    this.tidakHadir = const [],
  });

  DetailRiwayatState salin({
    bool? memuat,
    Object? error = const Object(),
    int? hadir,
    int? izin,
    int? sakit,
    int? alfa,
    String? waktu,
    List<SantriTidakHadir>? tidakHadir,
  }) {
    return DetailRiwayatState(
      memuat: memuat ?? this.memuat,
      error: identical(error, const Object())
          ? this.error
          : error as String?,
      hadir: hadir ?? this.hadir,
      izin: izin ?? this.izin,
      sakit: sakit ?? this.sakit,
      alfa: alfa ?? this.alfa,
      waktu: waktu ?? this.waktu,
      tidakHadir: tidakHadir ?? this.tidakHadir,
    );
  }

  @override
  List<Object?> get props => [
        memuat,
        error,
        hadir,
        izin,
        sakit,
        alfa,
        waktu,
        tidakHadir,
      ];
}

class DetailRiwayatBloc extends Bloc<DetailRiwayatEvent, DetailRiwayatState> {
  final String kamarId;
  final String kegiatanId;
  final String tanggal;

  DetailRiwayatBloc({
    required this.kamarId,
    required this.kegiatanId,
    required this.tanggal,
  }) : super(const DetailRiwayatState()) {
    on<DetailRiwayatDimuat>(_onDimuat);
  }

  Future<void> _onDimuat(
    DetailRiwayatDimuat event,
    Emitter<DetailRiwayatState> emit,
  ) async {
    emit(state.salin(memuat: true, error: null));

    try {
      final dataPresensi = await supabase
          .from('presensi')
          .select('santri_id, status, keterangan, created_at')
          .eq('kamar_id', kamarId)
          .eq('kegiatan_id', kegiatanId)
          .eq('tanggal', tanggal);

      final idSantri = <String>[];
      for (final baris in dataPresensi) {
        final id = baris['santri_id'] as String?;
        if (id != null) idSantri.add(id);
      }

      List<Map<String, dynamic>> dataSantri = [];
      if (idSantri.isNotEmpty) {
        dataSantri = await supabase
            .from('santri')
            .select('id, nis, nama_lengkap')
            .inFilter('id', idSantri);
      }

      final santriPerId = <String, Map<String, dynamic>>{};
      for (final s in dataSantri) {
        santriPerId[s['id'] as String] = s;
      }

      int hadir = 0, izin = 0, sakit = 0, alfa = 0;
      String? waktuTerbaru;
      final tidakHadir = <SantriTidakHadir>[];

      for (final baris in dataPresensi) {
        final status = baris['status'] as String?;
        final createdAt = baris['created_at'] as String?;
        if (createdAt != null &&
            (waktuTerbaru == null || createdAt.compareTo(waktuTerbaru) > 0)) {
          waktuTerbaru = createdAt;
        }

        switch (status) {
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

        if (status == 'izin' || status == 'sakit' || status == 'alfa') {
          final santri = santriPerId[baris['santri_id'] as String?];
          final ket = (baris['keterangan'] as String?)?.trim() ?? '';
          tidakHadir.add(
            SantriTidakHadir(
              nama: (santri?['nama_lengkap'] as String?) ?? '-',
              nis: (santri?['nis'] as String?) ?? '-',
              keterangan: ket.isEmpty ? 'Tanpa keterangan' : ket,
              status: status!,
            ),
          );
        }
      }

      tidakHadir.sort((a, b) => a.nama.compareTo(b.nama));

      emit(
        state.salin(
          memuat: false,
          hadir: hadir,
          izin: izin,
          sakit: sakit,
          alfa: alfa,
          waktu: waktuSimpan(waktuTerbaru),
          tidakHadir: tidakHadir,
        ),
      );
    } catch (e) {
      emit(state.salin(memuat: false, error: e.toString()));
    }
  }
}