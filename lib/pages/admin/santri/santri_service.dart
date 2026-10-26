import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';
import 'santri_model.dart';

class SantriException implements Exception {
  final String pesan;

  const SantriException(this.pesan);
}

class SantriService {
  final SupabaseClient _db = supabase;

  // ============================================================
  // DAFTAR SANTRI
  // ============================================================

  Future<List<Santri>> ambilSemua() async {
    final data = await _db
        .from('santri')
        .select(
          'id, nis, nama_lengkap, gender, kamar_id, no_hp, alamat, status_aktif, kamar(nama_kamar)',
        )
        .order('nama_lengkap');

    return List<Map<String, dynamic>>.from(data)
        .map(Santri.fromMap)
        .toList();
  }

  // ============================================================
  // KAMAR AKTIF (untuk pilihan di form)
  // ============================================================

  Future<List<KamarPilihan>> ambilKamarAktif() async {
    final data = await _db
        .from('kamar')
        .select('id, nama_kamar')
        .eq('aktif', true)
        .order('nama_kamar');

    return List<Map<String, dynamic>>.from(data)
        .map(KamarPilihan.fromMap)
        .toList();
  }

  // ============================================================
  // TAMBAH SANTRI
  // ============================================================

  Future<void> tambah({
    required String nis,
    required String namaLengkap,
    required String gender,
    String? kamarId,
    String? noHp,
    String? alamat,
  }) async {
    try {
      final hasil = await _db.from('santri').insert({
        'nis': nis.trim(),
        'nama_lengkap': namaLengkap.trim(),
        'gender': gender,
        'kamar_id': kamarId,
        'no_hp': (noHp == null || noHp.trim().isEmpty) ? null : noHp.trim(),
        'alamat':
            (alamat == null || alamat.trim().isEmpty) ? null : alamat.trim(),
      }).select();

      if (hasil.isEmpty) {
        throw const SantriException(
          'Data tidak tersimpan. Aturan akses (RLS) tabel santri mungkin belum mengizinkan Admin.',
        );
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const SantriException('NIS sudah dipakai santri lain.');
      }

      if (e.code == '42501') {
        throw const SantriException(
          'Akun ini belum diizinkan menambah santri (aturan akses database).',
        );
      }

      throw SantriException('Gagal menyimpan: ${e.message}');
    }
  }

  // ============================================================
  // PERBARUI SANTRI (EDIT)
  // ============================================================

  Future<void> perbarui({
    required String id,
    required String nis,
    required String namaLengkap,
    required String gender,
    String? kamarId,
    String? noHp,
    String? alamat,
  }) async {
    try {
      final hasil = await _db
          .from('santri')
          .update({
            'nis': nis.trim(),
            'nama_lengkap': namaLengkap.trim(),
            'gender': gender,
            'kamar_id': kamarId,
            'no_hp':
                (noHp == null || noHp.trim().isEmpty) ? null : noHp.trim(),
            'alamat': (alamat == null || alamat.trim().isEmpty)
                ? null
                : alamat.trim(),
          })
          .eq('id', id)
          .select();

      // Kalau RLS belum mengizinkan UPDATE, Supabase tidak error,
      // tapi hasilnya kosong. Kita tangkap di sini.
      if (hasil.isEmpty) {
        throw const SantriException(
          'Perubahan tidak tersimpan. Aturan akses (RLS) tabel santri mungkin belum mengizinkan Admin mengubah data.',
        );
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const SantriException('NIS sudah dipakai santri lain.');
      }

      if (e.code == '42501') {
        throw const SantriException(
          'Akun ini belum diizinkan mengubah santri (aturan akses database).',
        );
      }

      throw SantriException('Gagal menyimpan perubahan: ${e.message}');
    }
  }

  // ============================================================
  // AKTIFKAN / NONAKTIFKAN SANTRI
  // ============================================================

  Future<void> ubahStatusAktif(String id, bool aktif) async {
    try {
      final hasil = await _db
          .from('santri')
          .update({'status_aktif': aktif})
          .eq('id', id)
          .select();

      if (hasil.isEmpty) {
        throw const SantriException(
          'Status tidak berubah. Aturan akses (RLS) tabel santri mungkin belum mengizinkan Admin mengubah data.',
        );
      }
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw const SantriException(
          'Akun ini belum diizinkan mengubah santri (aturan akses database).',
        );
      }

      throw SantriException('Gagal mengubah status: ${e.message}');
    }
  }

  // ============================================================
  // HAPUS SANTRI (PERMANEN)
  // ============================================================

  Future<void> hapus(String id) async {
    try {
      final hasil =
          await _db.from('santri').delete().eq('id', id).select();

      if (hasil.isEmpty) {
        throw const SantriException(
          'Santri tidak terhapus. Aturan akses (RLS) tabel santri mungkin belum mengizinkan Admin menghapus data.',
        );
      }
    } on PostgrestException catch (e) {
      if (e.code == '23503') {
        throw const SantriException(
          'Santri ini masih punya data terkait (misalnya presensi), jadi tidak bisa dihapus. Nonaktifkan saja.',
        );
      }

      if (e.code == '42501') {
        throw const SantriException(
          'Akun ini belum diizinkan menghapus santri (aturan akses database).',
        );
      }

      throw SantriException('Gagal menghapus: ${e.message}');
    }
  }
}