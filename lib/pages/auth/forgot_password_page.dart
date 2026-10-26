import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/input_decorations.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  bool _mengirim = false;
  bool _berhasil = false;
  String? _pesanError;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _kirimPermintaan() async {
    final email = emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      setState(() => _pesanError = 'Email wajib diisi.');
      return;
    }

    setState(() {
      _mengirim = true;
      _pesanError = null;
    });

    try {
      final client = Supabase.instance.client;

      // Cari user berdasarkan email
      final profil = await client
          .from('profiles')
          .select('id, full_name, email')
          .eq('email', email)
          .maybeSingle();

      if (profil == null) {
        setState(() {
          _pesanError =
              'Email tidak ditemukan. Pastikan email yang dipakai saat mendaftar.';
          _mengirim = false;
        });
        return;
      }

      final userId = profil['id'] as String;

      // Cek apakah sudah ada request pending
      final existing = await client
          .from('password_reset_requests')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'pending')
          .maybeSingle();

      if (existing != null) {
        setState(() {
          _pesanError =
              'Permintaan reset sudah dikirim sebelumnya. Silakan tunggu konfirmasi Admin.';
          _mengirim = false;
        });
        return;
      }

      // Buat request baru
      await client.from('password_reset_requests').insert({
        'user_id': userId,
        'identifier': email,
        'status': 'pending',
        'requested_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (!mounted) return;
      setState(() {
        _berhasil = true;
        _mengirim = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Tampilkan error asli supaya kita tahu penyebabnya
        _pesanError = 'Gagal: $e';
        _mengirim = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: krem,
      appBar: AppBar(
        backgroundColor: krem,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: hijauTua),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Icon(Icons.lock_reset, size: 80, color: hijau),
              ),
              const SizedBox(height: 25),
              const Center(
                child: Text(
                  'Lupa Password?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: hijauTua,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Masukkan email yang terdaftar. Permintaan akan dikirim ke Admin untuk diverifikasi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 15),
                ),
              ),
              const SizedBox(height: 30),

              if (_berhasil) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: hijauMuda.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: hijauMuda),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, color: hijau),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Permintaan berhasil dikirim.\nSilakan hubungi Admin untuk mendapatkan password sementara.',
                          style: TextStyle(
                            color: hijauTua,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
              ] else ...[
                if (_pesanError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _pesanError!,
                      style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                    ),
                  ),
                ],
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_mengirim,
                  decoration: loginDecoration('Email', Icons.email_outlined),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _mengirim ? null : _kirimPermintaan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hijauTua,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _mengirim
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Kirim Permintaan ke Admin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 15),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Kembali ke Login',
                    style: TextStyle(
                      color: hijau,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}