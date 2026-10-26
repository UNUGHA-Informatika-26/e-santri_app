import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';
import 'pengurus_model.dart';

class PengurusException implements Exception {
  final String pesan;

  const PengurusException(this.pesan);
}

class PengurusService {
  final SupabaseClient _db = supabase;

  // ============================================================
  // DAFTAR PENGURUS AKTIF (beserta kamar tugasnya)
  // ============================================================

  Future<List<DataPengurus>> ambilSemua() async {
    try {
      final data = await _db
          .from('profiles')
          .select(
            'id, full_name, username, email, phone, gender, status, pengurus(kamar_id, kamar(nama_kamar))',
          )
          .eq('role', 'pengurus')
          .eq('status', 'active')
          .order('full_name');

      return List<Map<String, dynamic>>.from(data)
          .map(DataPengurus.fromMap)
          .toList();
    } on PostgrestException catch (e) {
      throw PengurusException('Gagal memuat data pengurus: ${e.message}');
    }
  }

  // ============================================================
  // TUGASKAN / KOSONGKAN KAMAR
  // [kamarId] null berarti pengurus dilepas dari kamarnya.
  // ============================================================

  Future<void> tetapkanKamar(String pengurusId, String? kamarId) async {
    try {
      if (kamarId == null) {
        await _db
            .from('pengurus')
            .update({'kamar_id': null}).eq('id', pengurusId);
        return;
      }

      // Periksa dulu: apakah kamar ini sudah dipegang pengurus lain?
      final pemegang = await _db
          .from('pengurus')
          .select('id, profiles(full_name)')
          .eq('kamar_id', kamarId)
          .neq('id', pengurusId);

      if (pemegang.isNotEmpty) {
        final nama = _ambilNama(pemegang.first as Map);

        throw PengurusException(
          'Kamar ini sudah dipegang $nama. Kosongkan dulu kamar itu, atau pilih kamar lain.',
        );
      }

      // Buat baris pengurus kalau belum ada, atau ubah kamarnya.
      final hasil = await _db
          .from('pengurus')
          .upsert({'id': pengurusId, 'kamar_id': kamarId}, onConflict: 'id')
          .select();

      if (hasil.isEmpty) {
        throw const PengurusException(
          'Penugasan tidak tersimpan. Aturan akses (RLS) tabel pengurus mungkin belum mengizinkan Admin.',
        );
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const PengurusException(
          'Kamar ini sudah dipegang pengurus lain.',
        );
      }

      if (e.code == '42501') {
        throw const PengurusException(
          'Akun ini belum diizinkan mengatur penugasan (aturan akses database).',
        );
      }

      throw PengurusException('Gagal menyimpan penugasan: ${e.message}');
    }
  }

  String _ambilNama(Map baris) {
    final p = baris['profiles'];
    Map? profil;

    if (p is Map) {
      profil = p;
    } else if (p is List && p.isNotEmpty && p.first is Map) {
      profil = p.first as Map;
    }

    final nama = profil?['full_name']?.toString();

    if (nama == null || nama.isEmpty) {
      return 'pengurus lain';
    }

    return nama;
  }
}