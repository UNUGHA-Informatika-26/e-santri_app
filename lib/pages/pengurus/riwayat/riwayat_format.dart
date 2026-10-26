const List<String> _bulanPendek = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

const List<String> _bulanPanjang = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

const List<String> _namaHari = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
];

/// DateTime -> '2026-10-21' (format tanggal di database)
String formatTanggalDb(DateTime d) {
  final bulan = d.month.toString().padLeft(2, '0');
  final hari = d.day.toString().padLeft(2, '0');
  return '${d.year}-$bulan-$hari';
}

/// '2026-10-21' -> '21 Okt'
String tanggalPendek(String iso) {
  final p = iso.split('-');
  if (p.length != 3) return iso;
  final bulan = int.tryParse(p[1]) ?? 1;
  final hari = int.tryParse(p[2]) ?? 1;
  return '$hari ${_bulanPendek[(bulan - 1).clamp(0, 11)]}';
}

/// '2026-10-21' -> '21 Oktober 2026' atau 'Rabu, 21 Oktober 2026'
String tanggalPanjang(String iso, {bool denganHari = false}) {
  final p = iso.split('-');
  if (p.length != 3) return iso;
  final tahun = int.tryParse(p[0]) ?? 2000;
  final bulan = int.tryParse(p[1]) ?? 1;
  final hari = int.tryParse(p[2]) ?? 1;
  final teks = '$hari ${_bulanPanjang[(bulan - 1).clamp(0, 11)]} $tahun';
  if (!denganHari) return teks;
  final namaHari = _namaHari[DateTime(tahun, bulan, hari).weekday - 1];
  return '$namaHari, $teks';
}

/// created_at dari database -> '05.40' (jam lokal)
String waktuSimpan(String? createdAt) {
  if (createdAt == null) return '-';
  final waktu = DateTime.tryParse(createdAt)?.toLocal();
  if (waktu == null) return '-';
  final jam = waktu.hour.toString().padLeft(2, '0');
  final menit = waktu.minute.toString().padLeft(2, '0');
  return '$jam.$menit';
}

/// 'Sholat Subuh' -> 'SS'
String inisial(String teks) {
  final kata = teks
      .trim()
      .split(RegExp(r'\s+'))
      .where((k) => k.isNotEmpty)
      .toList();
  if (kata.isEmpty) return '?';
  if (kata.length == 1) return kata.first.substring(0, 1).toUpperCase();
  return (kata[0].substring(0, 1) + kata[1].substring(0, 1)).toUpperCase();
}