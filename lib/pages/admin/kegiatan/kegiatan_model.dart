class Kegiatan {
  final String id;
  final String namaKegiatan;
  final String? deskripsi;
  final bool aktif;

  const Kegiatan({
    required this.id,
    required this.namaKegiatan,
    required this.aktif,
    this.deskripsi,
  });

  factory Kegiatan.fromMap(Map<String, dynamic> m) {
    final d = m['deskripsi']?.toString();

    return Kegiatan(
      id: m['id'].toString(),
      namaKegiatan: (m['nama_kegiatan'] ?? '').toString(),
      deskripsi: (d == null || d.trim().isEmpty) ? null : d.trim(),
      aktif: m['aktif'] != false,
    );
  }

  String get labelDeskripsi => deskripsi ?? 'Tanpa deskripsi';

  /// Huruf awal dua kata pertama nama, untuk avatar.
  String get inisial {
    final kata = namaKegiatan
        .trim()
        .split(RegExp(r'\s+'))
        .where((k) => k.isNotEmpty)
        .toList();

    if (kata.isEmpty) {
      return '?';
    }

    if (kata.length == 1) {
      return kata.first.substring(0, 1).toUpperCase();
    }

    return (kata[0].substring(0, 1) + kata[1].substring(0, 1)).toUpperCase();
  }
}