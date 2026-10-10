import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_config.dart';

class AuthService {
  final SupabaseClient _supabase = supabase;

  // ============================================================
  // REGISTER
  // Role & status yang dipercaya ditetapkan oleh trigger database
  // (handle_new_user), bukan oleh nilai yang dikirim di bawah ini.
  // ============================================================

  Future<AuthResponse> register({
    required String namaLengkap,
    required String username,
    required String email,
    required String nomorHp,
    required String jenisKelamin,
    required String role,
    required String password,
  }) async {
    final String roleDatabase = _convertRole(role);
    final String genderDatabase = _convertGender(jenisKelamin);

    final AuthResponse response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': namaLengkap.trim(),
        'username': username.trim(),
        'phone': nomorHp.trim(),
        'gender': genderDatabase,
        'role': roleDatabase,
      },
    );

    return response;
  }

  // ============================================================
  // LOGIN (EMAIL ATAU USERNAME)
  // ============================================================

  Future<AuthResponse> login({
    required String identifier,
    required String password,
  }) async {
    final String input = identifier.trim();

    String email;

    if (input.contains('@')) {
      email = input;
    } else {
      final String? emailDariUsername =
          await _getEmailByUsername(input);

      if (emailDariUsername == null || emailDariUsername.isEmpty) {
        throw const AuthException('Username tidak ditemukan.');
      }

      email = emailDariUsername;
    }

    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ============================================================
  // CARI EMAIL BERDASARKAN USERNAME
  // ============================================================

  Future<String?> _getEmailByUsername(String username) async {
    try {
      final response = await _supabase.rpc(
        'get_login_email_by_username',
        params: {
          'p_username': username.trim(),
        },
      );

      if (response == null) {
        return null;
      }

      return response.toString();
    } on PostgrestException catch (e) {
      throw AuthException('Gagal mencari username: ${e.message}');
    }
  }

  // ============================================================
  // PROFIL USER YANG SEDANG LOGIN
  // ============================================================

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final User? user = _supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    final Map<String, dynamic>? profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return profile;
  }

  User? get currentUser {
    return _supabase.auth.currentUser;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // ============================================================
  // KONVERSI
  // ============================================================

  String _convertRole(String role) {
    switch (role) {
      case 'Admin':
        return 'admin';
      case 'Pengurus':
        return 'pengurus';
      case 'Pengasuh / Kyai':
        return 'pengasuh';
      default:
        throw Exception('Role tidak valid.');
    }
  }

  String _convertGender(String gender) {
    switch (gender) {
      case 'Laki-laki':
        return 'putra';
      case 'Perempuan':
        return 'putri';
      default:
        throw Exception('Jenis kelamin tidak valid.');
    }
  }
}