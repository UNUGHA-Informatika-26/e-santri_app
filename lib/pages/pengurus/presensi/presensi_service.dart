import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';

class PresensiException implements Exception {
  final String pesan;

  const PresensiException(this.pesan);
}

/// Kamar tugas pengurus yang sedang login.
class KamarTugas {
  final String id;
  final String namaKamar;

  const KamarTugas({required this.id, required this.namaKamar});
}

/// Kegiatan aktif untuk dipilih.
class KegiatanPilihan {
  final String id;
  final String nama;

  const KegiatanPilihan({required this.id, required this.nama});
}

/// Satu santri di daftar presensi.
class SantriPresensi {
  final String id;
  final String nis;
  final String nama;

  const SantriPresensi({
    required this.id,
    required this.nis,
    required this.nama,
  });

  String get inisial {
    final kata = nama
        .trim()
        .split(RegExp(r'\s+'))
        .where((k) => k.isNotEmpty)
        .toList();

    if (kata.isEmpty) return '?';
    if (kata.length == 1) return kata.first.substring(0, 1).toUpperCase();

    return (kata[0].substring(0, 1) + kata[1].substring(0, 1)).toUpperCase();
  }
}

/// Status dan keterangan yang sudah tersimpan untuk satu santri.
class PresensiTersimpan {
  final String status;
  final String? keterangan;

  const PresensiTersimpan({required this.status, this.keterangan});
}

class PresensiService {
  final SupabaseClient _db = supabase;

  /// Format tanggal untuk kolom date: yyyy-MM-dd.
  static String formatTanggalDb(DateTime t) {
    final bulan = t.month.toString().padLeft(2, '0');
    final hari = t.day.toString().padLeft(2, '0');
    return '${t.year}-$bulan-$hari';
  }

  // ============================================================
  // KAMAR TUGAS PENGURUS YANG LOGIN
  // ============================================================

  Future<KamarTugas?> ambilKamarTugas() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) {
      throw const PresensiException('Sesi login tidak ditemukan.');
    }

    final pengurus = await _db
        .from('pengurus')
        .select('kamar_id')
        .eq('id', userId)
        .maybeSingle();

    final kamarId = pengurus?['kamar_id'] as String?;
    if (kamarId == null) return null;

    final kamar = await _db
        .from('kamar')
        .select('id, nama_kamar')
        .eq('id', kamarId)
        .maybeSingle();

    if (kamar == null) return null;

    return KamarTugas(
      id: kamar['id'].toString(),
      namaKamar: (kamar['nama_kamar'] ?? '').toString(),
    );
  }

  // ============================================================
  // KEGIATAN AKTIF
  // ============================================================

  Future<List<KegiatanPilihan>> ambilKegiatanAktif() async {
    final data = await _db
        .from('kegiatan')
        .select('id, nama_kegiatan')
        .eq('aktif', true)
        .order('created_at');

    return List<Map<String, dynamic>>.from(data)
        .map(
          (m) => KegiatanPilihan(
            id: m['id'].toString(),
            nama: (m['nama_kegiatan'] ?? '').toString(),
          ),
        )
        .toList();
  }

  // ============================================================
  // SANTRI AKTIF DI KAMAR
  // ============================================================

  Future<List<SantriPresensi>> ambilSantriKamar(String kamarId) async {
    final data = await _db
        .from('santri')
        .select('id, nis, nama_lengkap')
        .eq('kamar_id', kamarId)
        .eq('status_aktif', true)
        .order('nama_lengkap');

    return List<Map<String, dynamic>>.from(data)
        .map(
          (m) => SantriPresensi(
            id: m['id'].toString(),
            nis: (m['nis'] ?? '').toString(),
            nama: (m['nama_lengkap'] ?? '').toString(),
          ),
        )
        .toList();
  }

  // ============================================================
  // PRESENSI YANG SUDAH TERSIMPAN (kunci = santri_id)
  // ============================================================

  Future<Map<String, PresensiTersimpan>> ambilTersimpan({
    required String kamarId,
    required String kegiatanId,
    required DateTime tanggal,
  }) async {
    final data = await _db
        .from('presensi')
        .select('santri_id, status, keterangan')
        .eq('kamar_id', kamarId)
        .eq('kegiatan_id', kegiatanId)
        .eq('tanggal', formatTanggalDb(tanggal));

    final hasil = <String, PresensiTersimpan>{};

    for (final m in List<Map<String, dynamic>>.from(data)) {
      final ket = m['keterangan']?.toString();

      hasil[m['santri_id'].toString()] = PresensiTersimpan(
        status: (m['status'] ?? '').toString(),
        keterangan: (ket == null || ket.trim().isEmpty) ? null : ket.trim(),
      );
    }

    return hasil;
  }

  // ============================================================
  // SIMPAN (UPSERT)
  // status: santriId -> 'hadir' | 'izin' | 'sakit' | 'alfa'
  // ============================================================

  Future<void> simpan({
    required String kamarId,
    required String kegiatanId,
    required DateTime tanggal,
    required Map<String, String> status,
    required Map<String, String> keterangan,
  }) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) {
      throw const PresensiException('Sesi login tidak ditemukan.');
    }

    if (status.isEmpty) {
      throw const PresensiException('Belum ada santri yang diisi.');
    }

    final tgl = formatTanggalDb(tanggal);

    final baris = status.entries.map((e) {
      final ket = (keterangan[e.key] ?? '').trim();

      return {
        'santri_id': e.key,
        'kamar_id': kamarId,
        'kegiatan_id': kegiatanId,
        'tanggal': tgl,
        'status': e.value,
        'keterangan': (e.value == 'hadir' || ket.isEmpty) ? null : ket,
        'dicatat_oleh': userId,
      };
    }).toList();

    try {
      final hasil = await _db
          .from('presensi')
          .upsert(baris, onConflict: 'santri_id,kegiatan_id,tanggal')
          .select();

      if (hasil.isEmpty) {
        throw const PresensiException(
          'Presensi tidak tersimpan. Aturan akses (RLS) tabel presensi mungkin menolak akun ini.',
        );
      }
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw const PresensiException(
          'Akun ini belum diizinkan menyimpan presensi (aturan akses database).',
        );
      }

      throw PresensiException('Gagal menyimpan: ${e.message}');
    }
  }
}