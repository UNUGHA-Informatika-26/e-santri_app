import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/input_decorations.dart';

import 'forgot_password_page.dart';
import 'register_page.dart';
import '../admin/admin_dashboard_page.dart';
import '../pengurus/pengurus_dashboard_page.dart';
import '../pengasuh/pengasuh_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  String peran = 'Admin';

  bool sembunyikanPassword = true;

  /// Hanya dipakai di dalam build (memantau state Bloc).
  bool get sedangLogin => context.watch<AuthBloc>().state is AuthLoading;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOGIN: kirim event ke AuthBloc
  // ============================================================

  void login() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final bloc = context.read<AuthBloc>();

    if (bloc.state is AuthLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    bloc.add(
      AuthLoginRequested(
        identifier: usernameController.text.trim(),
        password: passwordController.text,
      ),
    );
  }

  // ============================================================
  // HASIL DARI BLOC
  // ============================================================

  void _tanganiState(BuildContext context, AuthState state) {
    if (state is AuthError) {
      showLoginError(state.message);
      return;
    }

    if (state is! AuthAuthenticated) {
      return;
    }

    final String? roleDatabase = state.profile['role']?.toString();

    if (!_cekRoleSesuai(roleDatabase, peran)) {
      showLoginError('Role akun tidak sesuai dengan pilihan login.');
      context.read<AuthBloc>().add(const AuthLogoutRequested());
      return;
    }

    final String nama =
        state.profile['full_name']?.toString().trim() ?? '';

    // ROUTING BERDASARKAN ROLE DATABASE
    if (roleDatabase == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminDashboardPage(
            namaLengkap: nama.isEmpty ? 'Admin' : nama,
          ),
        ),
      );
      return;
    }

    if (roleDatabase == 'pengurus') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PengurusDashboardPage(
            namaLengkap: nama.isEmpty ? 'Pengurus' : nama,
          ),
        ),
      );
      return;
    }

    if (roleDatabase == 'pengasuh') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PengasuhDashboardPage(
            namaLengkap: nama.isEmpty ? 'Pengasuh' : nama,
          ),
        ),
      );
      return;
    }

    showLoginError('Role akun tidak dikenali.');
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  // ============================================================
  // CEK ROLE
  // ============================================================

  bool _cekRoleSesuai(String? roleDatabase, String rolePilihan) {
    switch (rolePilihan) {
      case 'Admin':
        return roleDatabase == 'admin';

      case 'Pengurus':
        return roleDatabase == 'pengurus';

      case 'Pengasuh / Kyai':
        return roleDatabase == 'pengasuh';

      default:
        return false;
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void showLoginError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // ROLE BUTTON
  // ============================================================

  Widget roleButton(String value) {
    final bool selected = peran == value;

    return ChoiceChip(
      label: Text(value),
      selected: selected,
      selectedColor: hijau,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : hijauTua,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: selected ? hijau : Colors.grey.shade300,
      ),
      onSelected: sedangLogin
          ? null
          : (selectedValue) {
              if (selectedValue) {
                setState(() {
                  peran = value;
                });
              }
            },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _tanganiState,
      child: Scaffold(
        backgroundColor: krem,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 25,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  Image.asset(
                    'assets/images/logo.png',
                    width: 130,
                    height: 130,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Selamat Datang',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: hijauTua,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Masuk ke akun E-Santri',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // USERNAME / EMAIL
                  TextFormField(
                    controller: usernameController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: loginDecoration(
                      'Username / Email',
                      Icons.person_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username atau email wajib diisi';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // PASSWORD
                  TextFormField(
                    controller: passwordController,
                    obscureText: sembunyikanPassword,
                    decoration: loginDecoration(
                      'Password',
                      Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          sembunyikanPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: hijau,
                        ),
                        onPressed: sedangLogin
                            ? null
                            : () {
                                setState(() {
                                  sembunyikanPassword =
                                      !sembunyikanPassword;
                                });
                              },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password wajib diisi';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 10),

                  // LUPA PASSWORD
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: sedangLogin
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordPage(),
                                ),
                              );
                            },
                      child: const Text(
                        'Lupa Password?',
                        style: TextStyle(
                          color: hijau,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ROLE
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Masuk sebagai',
                      style: TextStyle(
                        color: hijauTua,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      roleButton('Admin'),
                      roleButton('Pengurus'),
                      roleButton('Pengasuh / Kyai'),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // TOMBOL LOGIN
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: sedangLogin ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hijauTua,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            hijauTua.withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: sedangLogin
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // DAFTAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                      TextButton(
                        onPressed: sedangLogin
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterPage(),
                                  ),
                                );
                              },
                        child: const Text(
                          'Daftar',
                          style: TextStyle(
                            color: hijau,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}