import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/supabase/supabase_config.dart';
import '../../services/auth_service.dart';
import '../admin/admin_dashboard_page.dart';
import '../pengasuh/pengasuh_dashboard_page.dart';
import '../pengurus/pengurus_dashboard_page.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _mulai();
  }

  /// Tunggu minimal 3 detik (tampilan splash) sambil memeriksa session.
  Future<void> _mulai() async {
    final hasil = await Future.wait<Widget>([
      _tentukanHalaman(),
      Future<Widget>.delayed(
        const Duration(seconds: 3),
        () => const SizedBox.shrink(),
      ),
    ]);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => hasil.first),
    );
  }

  /// Tentukan halaman tujuan berdasarkan session yang tersimpan.
  Future<Widget> _tentukanHalaman() async {
    // Tidak ada session tersimpan -> login.
    if (supabase.auth.currentSession == null) {
      return const LoginPage();
    }

    final authService = AuthService();

    try {
      final profile = await authService
          .getCurrentProfile()
          .timeout(const Duration(seconds: 15));

      if (profile == null) {
        await authService.logout();
        return const LoginPage();
      }

      final status = profile['status']?.toString().toLowerCase();
      final role = profile['role']?.toString().toLowerCase();
      const allowedRoles = {'admin', 'pengurus', 'pengasuh'};

      // Akun tidak aktif / role tidak valid -> hapus session.
      if (status != 'active' ||
          role == null ||
          !allowedRoles.contains(role)) {
        await authService.logout();
        return const LoginPage();
      }

      final nama = profile['full_name']?.toString().trim() ?? '';

      if (role == 'admin') {
        return AdminDashboardPage(
          namaLengkap: nama.isEmpty ? 'Admin' : nama,
        );
      }

      if (role == 'pengurus') {
        return PengurusDashboardPage(
          namaLengkap: nama.isEmpty ? 'Pengurus' : nama,
        );
      }

      return PengasuhDashboardPage(
        namaLengkap: nama.isEmpty ? 'Pengasuh' : nama,
      );
    } catch (_) {
      // Gagal (misalnya tidak ada internet): session tidak dihapus,
      // arahkan ke halaman login.
      return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hijauTua,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.mosque,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'e-Santri',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Presensi & Monitoring Santri\nPondok Pesantren',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}