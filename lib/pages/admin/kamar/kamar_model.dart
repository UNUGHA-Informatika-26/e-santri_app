class Kamar {
  final String id;
  final String namaKamar;
  final bool aktif;
  final int jumlahPenghuni;
  final String? pengurusId;
  final String? namaPengurus;

  /// 'putra' atau 'putri' (nilai enum gender_type di database).
  final String? gender;

  const Kamar({
    required this.id,
    required this.namaKamar,
    required this.aktif,
    required this.jumlahPenghuni,
    this.pengurusId,
    this.namaPengurus,
    this.gender,
  });

  factory Kamar.fromMap(Map<String, dynamic> m) {
    // Hasil embed santri(count) berbentuk: [{count: 3}]
    final santri = m['santri'];
    int jumlah = 0;

    if (santri is List && santri.isNotEmpty && santri.first is Map) {
      jumlah = ((santri.first as Map)['count'] as num?)?.toInt() ?? 0;
    }

    // Embed pengurus bisa berupa objek tunggal atau list berisi satu objek.
    final p = m['pengurus'];
    Map? pengurus;

    if (p is Map) {
      pengurus = p;
    } else if (p is List && p.isNotEmpty && p.first is Map) {
      pengurus = p.first as Map;
    }

    String? pengurusId;
    String? namaPengurus;

    if (pengurus != null) {
      pengurusId = pengurus['id']?.toString();

      final profil = pengurus['profiles'];

      if (profil is Map) {
        namaPengurus = profil['full_name']?.toString();
      }
    }

    return Kamar(
      id: m['id'].toString(),
      namaKamar: (m['nama_kamar'] ?? '').toString(),
      aktif: m['aktif'] != false,
      jumlahPenghuni: jumlah,
      pengurusId: pengurusId,
      namaPengurus: namaPengurus,
      gender: m['gender']?.toString(),
    );
  }

  String get labelPenghuni =>
      jumlahPenghuni == 0 ? 'Belum ada penghuni' : '$jumlahPenghuni penghuni';

  String get labelGender {
    if (gender == 'putra') {
      return 'Putra';
    }

    if (gender == 'putri') {
      return 'Putri';
    }

    return '-';
  }
}

class Pengurus {
  final String id;
  final String nama;

  /// Kamar yang sedang dipegang, null kalau belum memegang kamar.
  final String? kamarId;

  /// 'putra' atau 'putri'.
  final String? gender;

  const Pengurus({
    required this.id,
    required this.nama,
    this.kamarId,
    this.gender,
  });
}