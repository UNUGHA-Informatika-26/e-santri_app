class DataPengurus {
  final String id;
  final String nama;
  final String username;
  final String email;
  final String? noHp;
  final String? gender;

  /// Kamar yang sedang dipegang, null kalau belum ditugaskan.
  final String? kamarId;
  final String? namaKamar;

  const DataPengurus({
    required this.id,
    required this.nama,
    required this.username,
    required this.email,
    this.noHp,
    this.gender,
    this.kamarId,
    this.namaKamar,
  });

  factory DataPengurus.fromMap(Map<String, dynamic> m) {
    // Embed pengurus bisa berupa objek tunggal atau list berisi satu objek.
    final Map? pengurus = _ambilMap(m['pengurus']);
    final Map? kamar = _ambilMap(pengurus?['kamar']);

    return DataPengurus(
      id: m['id'].toString(),
      nama: (m['full_name'] ?? '').toString(),
      username: (m['username'] ?? '').toString(),
      email: (m['email'] ?? '').toString(),
      noHp: m['phone']?.toString(),
      gender: m['gender']?.toString(),
      kamarId: pengurus?['kamar_id']?.toString(),
      namaKamar: kamar?['nama_kamar']?.toString(),
    );
  }

  static Map? _ambilMap(dynamic nilai) {
    if (nilai is Map) {
      return nilai;
    }

    if (nilai is List && nilai.isNotEmpty && nilai.first is Map) {
      return nilai.first as Map;
    }

    return null;
  }

  bool get sudahBertugas => kamarId != null;

  String get labelKamar =>
      namaKamar == null ? 'Belum ditugaskan' : 'Kamar $namaKamar';

  String get labelGender {
    if (gender == 'putra') {
      return 'Laki-laki';
    }

    if (gender == 'putri') {
      return 'Perempuan';
    }

    return '-';
  }

  /// Huruf awal dua kata pertama nama, untuk avatar.
  String get inisial {
    final kata =
        nama.trim().split(RegExp(r'\s+')).where((k) => k.isNotEmpty).toList();

    if (kata.isEmpty) {
      return '?';
    }

    if (kata.length == 1) {
      return kata.first.substring(0, 1).toUpperCase();
    }

    return (kata[0].substring(0, 1) + kata[1].substring(0, 1)).toUpperCase();
  }
}