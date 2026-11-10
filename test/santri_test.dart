import 'package:e_santri/blocs/santri_bloc.dart';
import 'package:e_santri/pages/admin/santri/santri_model.dart';
import 'package:flutter_test/flutter_test.dart';

Santri _buat({
  required String id,
  required String nama,
  String nis = '0001',
  String gender = 'putra',
  bool aktif = true,
}) {
  return Santri(
    id: id,
    nis: nis,
    namaLengkap: nama,
    gender: gender,
    statusAktif: aktif,
  );
}

List<Santri> _banyak(int n) => [
      for (var i = 1; i <= n; i++)
        _buat(id: '$i', nama: 'Santri $i', nis: 'N$i'),
    ];

void main() {
  group('Santri (model)', () {
    test('fromMap membaca semua kolom', () {
      final s = Santri.fromMap({
        'id': 1,
        'nis': '20260001',
        'nama_lengkap': 'Budi Santoso',
        'gender': 'putra',
        'kamar_id': 'k1',
        'kamar': {'nama_kamar': 'Falah'},
        'status_aktif': true,
      });

      expect(s.id, '1');
      expect(s.nis, '20260001');
      expect(s.namaLengkap, 'Budi Santoso');
      expect(s.namaKamar, 'Falah');
      expect(s.statusAktif, true);
    });

    test('fromMap memakai nilai bawaan bila kolom kosong', () {
      final s = Santri.fromMap({'id': 2});

      expect(s.nis, '');
      expect(s.namaLengkap, '');
      expect(s.namaKamar, isNull);
      expect(s.statusAktif, false);
    });

    test('labelGender', () {
      expect(_buat(id: '1', nama: 'A', gender: 'putra').labelGender, 'L');
      expect(_buat(id: '1', nama: 'A', gender: 'putri').labelGender, 'P');
      expect(_buat(id: '1', nama: 'A', gender: 'x').labelGender, '-');
    });

    test('labelKamar', () {
      expect(_buat(id: '1', nama: 'A').labelKamar, 'Belum ada kamar');
      expect(
        const Santri(
          id: '1',
          nis: '1',
          namaLengkap: 'A',
          gender: 'putra',
          namaKamar: 'Falah',
          statusAktif: true,
        ).labelKamar,
        'Kamar Falah',
      );
    });

    test('inisial', () {
      expect(_buat(id: '1', nama: 'Vina Aprilia').inisial, 'VA');
      expect(_buat(id: '1', nama: 'uswatun').inisial, 'U');
      expect(_buat(id: '1', nama: '   ').inisial, '?');
    });
  });

  group('SantriState: filter dan pencarian', () {
    final data = [
      _buat(id: '1', nama: 'Vina Aprilia', nis: '11', aktif: true),
      _buat(id: '2', nama: 'Rizal Maulana', nis: '22', aktif: false),
      _buat(id: '3', nama: 'Raisa Amalia', nis: '33', aktif: true),
    ];

    test('filter semua menampilkan semuanya', () {
      final st = SantriState(santri: data);
      expect(st.tersaring.length, 3);
    });

    test('filter aktif', () {
      final st = SantriState(santri: data, filter: 'aktif');
      expect(st.tersaring.map((s) => s.id), ['1', '3']);
    });

    test('filter nonaktif', () {
      final st = SantriState(santri: data, filter: 'nonaktif');
      expect(st.tersaring.map((s) => s.id), ['2']);
    });

    test('cari berdasarkan nama (tidak peka huruf besar)', () {
      final st = SantriState(santri: data, kataCari: 'RIZAL');
      expect(st.tersaring.map((s) => s.id), ['2']);
    });

    test('cari berdasarkan NIS', () {
      final st = SantriState(santri: data, kataCari: '33');
      expect(st.tersaring.map((s) => s.id), ['3']);
    });

    test('cari tanpa hasil', () {
      final st = SantriState(santri: data, kataCari: 'zzz');
      expect(st.tersaring, isEmpty);
    });

    test('filter dan cari digabung', () {
      final st = SantriState(santri: data, filter: 'aktif', kataCari: 'ra');
      expect(st.tersaring.map((s) => s.id), ['3']);
    });
  });

  group('SantriState: pagination', () {
    test('data kosong tetap 1 halaman', () {
      const st = SantriState();
      expect(st.totalHalaman, 1);
      expect(st.tampilHalaman, isEmpty);
    });

    test('19 santri, 20 per halaman = 1 halaman', () {
      final st = SantriState(santri: _banyak(19));
      expect(st.totalHalaman, 1);
      expect(st.tampilHalaman.length, 19);
    });

    test('45 santri, 20 per halaman = 3 halaman', () {
      final st = SantriState(santri: _banyak(45));
      expect(st.totalHalaman, 3);
    });

    test('halaman 1, 2, dan 3 berisi jumlah yang benar', () {
      final data = _banyak(45);

      expect(SantriState(santri: data, halaman: 1).tampilHalaman.length, 20);
      expect(SantriState(santri: data, halaman: 2).tampilHalaman.length, 20);

      final h3 = SantriState(santri: data, halaman: 3).tampilHalaman;
      expect(h3.length, 5);
      expect(h3.first.id, '41');
    });

    test('halaman melebihi total dipaksa ke halaman terakhir', () {
      final st = SantriState(santri: _banyak(45), halaman: 99);
      expect(st.halamanAman, 3);
    });

    test('halaman di bawah 1 dipaksa ke 1', () {
      final st = SantriState(santri: _banyak(45), halaman: 0);
      expect(st.halamanAman, 1);
    });

    test('ganti jumlah per halaman', () {
      final st = SantriState(santri: _banyak(45), perHalaman: 50);
      expect(st.totalHalaman, 1);
      expect(st.tampilHalaman.length, 45);
    });

    test('pagination mengikuti hasil filter', () {
      final data = [
        for (var i = 1; i <= 30; i++)
          _buat(id: '$i', nama: 'S$i', aktif: i <= 25),
      ];
      final st = SantriState(santri: data, filter: 'nonaktif');

      expect(st.tersaring.length, 5);
      expect(st.totalHalaman, 1);
    });
  });

  group('SantriState.salin', () {
    test('salin mengubah nilai yang diminta saja', () {
      const awal = SantriState(filter: 'aktif', perHalaman: 50);
      final baru = awal.salin(halaman: 2);

      expect(baru.halaman, 2);
      expect(baru.filter, 'aktif');
      expect(baru.perHalaman, 50);
    });

    test('salin bisa mengosongkan error', () {
      final st = const SantriState().salin(error: 'gagal');
      expect(st.error, 'gagal');
      expect(st.salin(error: null).error, isNull);
    });
  });
}