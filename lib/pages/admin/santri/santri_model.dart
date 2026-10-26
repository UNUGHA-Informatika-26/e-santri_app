class Santri {
  final String id;
  final String nis;
  final String namaLengkap;
  final String gender; // putra / putri
  final String? kamarId;
  final String? namaKamar;
  final String? noHp; // nomor HP wali
  final String? alamat;
  final bool statusAktif;

  const Santri({
    required this.id,
    required this.nis,
    required this.namaLengkap,
    required this.gender,
    this.kamarId,
    this.namaKamar,
    this.noHp,
    this.alamat,
    required this.statusAktif,
  });

  factory Santri.fromMap(Map<String, dynamic> m) {
    final kamar = m['kamar'];

    return Santri(
      id: m['id'].toString(),
      nis: (m['nis'] ?? '').toString(),
      namaLengkap: (m['nama_lengkap'] ?? '').toString(),
      gender: (m['gender'] ?? '').toString(),
      kamarId: m['kamar_id']?.toString(),
      namaKamar: kamar is Map ? kamar['nama_kamar']?.toString() : null,
      noHp: m['no_hp']?.toString(),
      alamat: m['alamat']?.toString(),
      statusAktif: m['status_aktif'] == true,
    );
  }

  String get labelGender {
    switch (gender) {
      case 'putra':
        return 'L';
      case 'putri':
        return 'P';
      default:
        return '-';
    }
  }

  String get labelKamar =>
      namaKamar == null ? 'Belum ada kamar' : 'Kamar $namaKamar';

  String get inisial {
    final bagian =
        namaLengkap.trim().split(' ').where((e) => e.isNotEmpty).toList();

    if (bagian.isEmpty) {
      return '?';
    }

    if (bagian.length == 1) {
      return bagian[0][0].toUpperCase();
    }

    return (bagian[0][0] + bagian[1][0]).toUpperCase();
  }
}

class KamarPilihan {
  final String id;
  final String nama;

  const KamarPilihan({required this.id, required this.nama});

  factory KamarPilihan.fromMap(Map<String, dynamic> m) {
    return KamarPilihan(
      id: m['id'].toString(),
      nama: (m['nama_kamar'] ?? '-').toString(),
    );
  }
}