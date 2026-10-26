import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';
import 'kegiatan_model.dart';

class KegiatanException implements Exception {
  final String pesan;

  const KegiatanException(this.pesan);
}

class KegiatanService {
  final SupabaseClient _db = supabase;

  // ============================================================
  // DAFTAR KEGIATAN
  // ============================================================

  Future<List<Kegiatan>> ambilSemua() async {
    try {
      final data = await _db
          .from('kegiatan')
          .select('id, nama_kegiatan, deskripsi, aktif')
          .order('nama_kegiatan');

      return List<Map<String, dynamic>>.from(data)
          .map(Kegiatan.fromMap)
          .toList();
    } on PostgrestException catch (e) {
      throw KegiatanException('Gagal memuat data kegiatan: ${e.message}');
    }
  }

  // ============================================================
  // TAMBAH
  // ============================================================

  Future<void> tambah({
    required String nama,
    required String deskripsi,
    required bool aktif,
  }) async {
    try {
      final hasil = await _db.from('kegiatan').insert({
        'nama_kegiatan': nama.trim(),
        'deskripsi': _bersihkan(deskripsi),
        'aktif': aktif,
      }).select();

      if (hasil.isEmpty) {
        throw const KegiatanException(
          'Data tidak tersimpan. Aturan akses (RLS) tabel kegiatan mungkin belum mengizinkan Admin.',
        );
      }
    } on PostgrestException catch (e) {
      throw _terjemahkan(e, 'menambah');
    }
  }

  // ============================================================
  // PERBARUI
  // ============================================================

  Future<void> perbarui({
    required String id,
    required String nama,
    required String deskripsi,
    required bool aktif,
  }) async {
    try {
      final hasil = await _db
          .from('kegiatan')
          .update({
            'nama_kegiatan': nama.trim(),
            'deskripsi': _bersihkan(deskripsi),
            'aktif': aktif,
          })
          .eq('id', id)
          .select();

      if (hasil.isEmpty) {
        throw const KegiatanException(
          'Perubahan tidak tersimpan. Aturan akses (RLS) tabel kegiatan mungkin belum mengizinkan Admin mengubah data.',
        );
      }
    } on PostgrestException catch (e) {
      throw _terjemahkan(e, 'mengubah');
    }
  }

  // ============================================================
  // HAPUS
  // ============================================================

  Future<void> hapus(String id) async {
    try {
      final hasil =
          await _db.from('kegiatan').delete().eq('id', id).select();

      if (hasil.isEmpty) {
        throw const KegiatanException(
          'Kegiatan tidak terhapus. Aturan akses (RLS) tabel kegiatan mungkin belum mengizinkan Admin menghapus data.',
        );
      }
    } on PostgrestException catch (e) {
      throw _terjemahkan(e, 'menghapus');
    }
  }

  // ============================================================
  // BANTUAN
  // ============================================================

  String? _bersihkan(String teks) {
    final t = teks.trim();

    return t.isEmpty ? null : t;
  }

  KegiatanException _terjemahkan(PostgrestException e, String aksi) {
    if (e.code == '23505') {
      return const KegiatanException('Nama kegiatan sudah dipakai.');
    }

    if (e.code == '42501') {
      return KegiatanException(
        'Akun ini belum diizinkan $aksi kegiatan (aturan akses database).',
      );
    }

    if (e.code == '23502') {
      return KegiatanException(
        'Tabel kegiatan punya kolom wajib yang belum diisi: ${e.message}',
      );
    }

    if (e.code == '23503') {
      return const KegiatanException(
        'Kegiatan ini sudah dipakai data lain, jadi tidak bisa dihapus. Nonaktifkan saja.',
      );
    }

    return KegiatanException('Gagal $aksi kegiatan: ${e.message}');
  }
}