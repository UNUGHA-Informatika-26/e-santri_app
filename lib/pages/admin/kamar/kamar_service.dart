import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';
import 'kamar_model.dart';
import '../santri/santri_model.dart';

// Nama kolom di tabel profiles.
const String _kolomNama = 'full_name';
const String _kolomRole = 'role';
const String _nilaiRolePengurus = 'pengurus';

class KamarException implements Exception {
  final String pesan;

  const KamarException(this.pesan);
}

class KamarService {
  final SupabaseClient _db = supabase;

  // ============================================================
  // DAFTAR KAMAR (beserta jumlah penghuni dan pengurus)
  // ============================================================

  Future<List<Kamar>> ambilSemua() async {
    final data = await _db
        .from('kamar')
        .select(
          'id, nama_kamar, gender, aktif, santri(count), pengurus(id, profiles($_kolomNama))',
        )
        .order('nama_kamar');

    return List<Map<String, dynamic>>.from(data).map(Kamar.fromMap).toList();
  }

  // ============================================================
  // PENGHUNI KAMAR
  // ============================================================

  Future<List<Santri>> ambilPenghuni(String kamarId) async {
    final data = await _db
        .from('santri')
        .select(
          'id, nis, nama_lengkap, gender, kamar_id, no_hp, alamat, status_aktif, kamar(nama_kamar)',
        )
        .eq('kamar_id', kamarId)
        .order('nama_lengkap');

    return List<Map<String, dynamic>>.from(data)
        .map(Santri.fromMap)
        .toList();
  }

  // ============================================================
  // PENGURUS KAMAR
  // ============================================================

  /// Hanya pengurus berstatus active.
  Future<List<Pengurus>> ambilDaftarPengurus() async {
    try {
      final data = await _db
          .from('profiles')
          .select('id, $_kolomNama, gender, pengurus(kamar_id)')
          .eq(_kolomRole, _nilaiRolePengurus)
          .eq('status', 'active')
          .order(_kolomNama);

      return List<Map<String, dynamic>>.from(data).map((m) {
        final p = m['pengurus'];
        Map? pengurus;

        if (p is Map) {
          pengurus = p;
        } else if (p is List && p.isNotEmpty && p.first is Map) {
          pengurus = p.first as Map;
        }

        return Pengurus(
          id: m['id'].toString(),
          nama: (m[_kolomNama] ?? '').toString(),
          kamarId: pengurus?['kamar_id']?.toString(),
          gender: m['gender']?.toString(),
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw KamarException('Gagal memuat daftar pengurus: ${e.message}');
    }
  }

  /// Tetapkan pengurus untuk sebuah kamar. [pengurusId] null berarti
  /// kamar dikosongkan dari pengurus. Pengurus lama di kamar itu dilepas
  /// dulu supaya aturan unik (1 kamar 1 pengurus) tidak bentrok.
  /// Pengurus hanya boleh memegang kamar dengan gender yang sama.
  Future<void> tetapkanPengurus(String kamarId, String? pengurusId) async {
    try {
      if (pengurusId != null) {
        await _pastikanGenderSama(kamarId, pengurusId);
      }

      await _db
          .from('pengurus')
          .update({'kamar_id': null}).eq('kamar_id', kamarId);

      if (pengurusId != null) {
        final hasil = await _db
            .from('pengurus')
            .upsert({'id': pengurusId, 'kamar_id': kamarId}, onConflict: 'id')
            .select();

        if (hasil.isEmpty) {
          throw const KamarException(
            'Pengurus tidak tersimpan. Aturan akses (RLS) tabel pengurus mungkin belum mengizinkan Admin.',
          );
        }
      }
    } on PostgrestException catch (e) {
      throw KamarException('Gagal menetapkan pengurus: ${e.message}');
    }
  }

  Future<void> _pastikanGenderSama(String kamarId, String pengurusId) async {
    final kamar = await _db
        .from('kamar')
        .select('gender, nama_kamar')
        .eq('id', kamarId)
        .maybeSingle();

    final profil = await _db
        .from('profiles')
        .select('gender, $_kolomNama')
        .eq('id', pengurusId)
        .maybeSingle();

    if (kamar == null || profil == null) {
      throw const KamarException('Data kamar atau pengurus tidak ditemukan.');
    }

    final String? genderKamar = kamar['gender']?.toString();
    final String? genderPengurus = profil['gender']?.toString();

    if (genderPengurus == null) {
      throw const KamarException(
        'Jenis kelamin pengurus belum terisi, jadi belum bisa ditugaskan.',
      );
    }

    if (genderKamar != genderPengurus) {
      throw KamarException(
        '${profil[_kolomNama]} ($genderPengurus) tidak bisa ditugaskan ke kamar ${kamar['nama_kamar']} ($genderKamar). Pengurus hanya boleh memegang kamar dengan jenis yang sama.',
      );
    }
  }

  // ============================================================
  // TAMBAH (mengembalikan id kamar baru)
  // [gender] berisi 'putra' atau 'putri'.
  // ============================================================

  Future<String> tambah(String namaKamar, String gender) async {
    try {
      final hasil = await _db.from('kamar').insert({
        'nama_kamar': namaKamar.trim(),
        'gender': gender,
        'aktif': true,
      }).select();

      if (hasil.isEmpty) {
        throw const KamarException(
          'Data tidak tersimpan. Aturan akses (RLS) tabel kamar mungkin belum mengizinkan Admin.',
        );
      }

      return hasil.first['id'].toString();
    } on PostgrestException catch (e) {
      throw _terjemahkan(e, 'menambah');
    }
  }

  // ============================================================
  // PERBARUI (EDIT NAMA)
  // ============================================================

  Future<void> perbarui(String id, String namaKamar) async {
    try {
      final hasil = await _db
          .from('kamar')
          .update({'nama_kamar': namaKamar.trim()})
          .eq('id', id)
          .select();

      if (hasil.isEmpty) {
        throw const KamarException(
          'Perubahan tidak tersimpan. Aturan akses (RLS) tabel kamar mungkin belum mengizinkan Admin mengubah data.',
        );
      }
    } on PostgrestException catch (e) {
      throw _terjemahkan(e, 'mengubah');
    }
  }

  // ============================================================
  // AKTIFKAN / NONAKTIFKAN
  // ============================================================

  Future<void> ubahStatusAktif(String id, bool aktif) async {
    try {
      final hasil = await _db
          .from('kamar')
          .update({'aktif': aktif})
          .eq('id', id)
          .select();

      if (hasil.isEmpty) {
        throw const KamarException(
          'Status tidak berubah. Aturan akses (RLS) tabel kamar mungkin belum mengizinkan Admin mengubah data.',
        );
      }
    } on PostgrestException catch (e) {
      throw _terjemahkan(e, 'mengubah');
    }
  }

  // ============================================================
  // HAPUS (hanya kalau tidak ada penghuni)
  // ============================================================

  Future<void> hapus(String id) async {
    try {
      // Dicek manual, supaya santri tidak kehilangan kamar secara diam-diam
      // kalau relasi di database diatur ON DELETE SET NULL.
      final penghuni =
          await _db.from('santri').select('id').eq('kamar_id', id);

      if (penghuni.isNotEmpty) {
        throw KamarException(
          'Kamar masih dihuni ${penghuni.length} santri. Pindahkan santrinya dulu, atau nonaktifkan kamar saja.',
        );
      }

      final hasil = await _db.from('kamar').delete().eq('id', id).select();

      if (hasil.isEmpty) {
        throw const KamarException(
          'Kamar tidak terhapus. Aturan akses (RLS) tabel kamar mungkin belum mengizinkan Admin menghapus data.',
        );
      }
    } on PostgrestException catch (e) {
      throw _terjemahkan(e, 'menghapus');
    }
  }

  // ============================================================
  // BANTUAN
  // ============================================================

  KamarException _terjemahkan(PostgrestException e, String aksi) {
    if (e.code == '23505') {
      return const KamarException('Nama kamar sudah dipakai.');
    }

    if (e.code == '42501') {
      return KamarException(
        'Akun ini belum diizinkan $aksi kamar (aturan akses database).',
      );
    }

    if (e.code == '23502') {
      return KamarException(
        'Tabel kamar punya kolom wajib lain yang belum diisi: ${e.message}',
      );
    }

    if (e.code == '23503') {
      return const KamarException(
        'Kamar ini masih dipakai data lain, jadi tidak bisa dihapus. Nonaktifkan saja.',
      );
    }

    return KamarException('Gagal $aksi kamar: ${e.message}');
  }
}