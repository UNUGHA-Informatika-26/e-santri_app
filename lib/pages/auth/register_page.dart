import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/input_decorations.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController namaController =
      TextEditingController();

  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController hpController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController konfirmasiController =
      TextEditingController();

  final AuthService _authService = AuthService();

  String jenisKelamin = 'Laki-laki';
  String role = 'Pengurus';

  bool sembunyikanPassword = true;
  bool sembunyikanKonfirmasi = true;
  bool sedangRegister = false;

  @override
  void dispose() {
    namaController.dispose();
    usernameController.dispose();
    emailController.dispose();
    hpController.dispose();
    passwordController.dispose();
    konfirmasiController.dispose();

    super.dispose();
  }

  // ============================================================
  // VALIDASI PASSWORD
  // ============================================================

  bool passwordValid(String password) {
    final hasUppercase =
        password.contains(RegExp(r'[A-Z]'));

    final hasLowercase =
        password.contains(RegExp(r'[a-z]'));

    final hasNumber =
        password.contains(RegExp(r'[0-9]'));

    return password.length >= 8 &&
        hasUppercase &&
        hasLowercase &&
        hasNumber;
  }

  // ============================================================
  // VALIDASI EMAIL
  // ============================================================

  bool emailValid(String email) {
    final emailRegex = RegExp(
      r'^[\w\.-]+@[\w\.-]+\.\w+$',
    );

    return emailRegex.hasMatch(email.trim());
  }

  // ============================================================
  // UPLOAD FOTO
  // ============================================================

  void uploadFoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Fitur upload foto akan kita hubungkan ke penyimpanan foto.',
        ),
        backgroundColor: hijau,
      ),
    );
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (sedangRegister) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      sedangRegister = true;
    });

    try {
      final response = await _authService.register(
        namaLengkap: namaController.text.trim(),
        username: usernameController.text.trim(),
        email: emailController.text.trim(),
        nomorHp: hpController.text.trim(),
        jenisKelamin: jenisKelamin,
        role: role,
        password: passwordController.text,
      );

      if (!mounted) {
        return;
      }

      if (response.user == null) {
        showError(
          'Pendaftaran gagal. Data akun tidak berhasil dibuat.',
        );
        return;
      }

      /*
       * Jika Supabase tidak menggunakan email confirmation,
       * signUp dapat langsung menghasilkan session.
       *
       * Karena sistem E-Santri menggunakan persetujuan Admin,
       * akun yang baru dibuat tidak boleh tetap login.
       */
      if (response.session != null) {
        await _authService.logout();
      }

      if (!mounted) {
        return;
      }

      showSuccess(
        'Pendaftaran berhasil. Akun menunggu persetujuan Admin.',
      );

      await Future.delayed(
        const Duration(milliseconds: 1000),
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }

      final message = e.message.toLowerCase();

      if (message.contains('already registered') ||
          message.contains('already been registered') ||
          message.contains('user already registered')) {
        showError(
          'Email tersebut sudah terdaftar. Silakan gunakan email lain.',
        );
      } else if (message.contains('invalid email')) {
        showError(
          'Format email tidak valid.',
        );
      } else if (message.contains('password')) {
        showError(
          'Password tidak memenuhi ketentuan Supabase.',
        );
      } else if (message.contains('rate limit') ||
          message.contains('too many requests')) {
        showError(
          'Terlalu banyak percobaan. Silakan coba lagi nanti.',
        );
      } else {
        showError(
          e.message,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      showError(
        'Terjadi kesalahan saat membuat akun.',
      );
    } finally {
      if (mounted) {
        setState(() {
          sedangRegister = false;
        });
      }
    }
  }

  // ============================================================
  // PESAN BERHASIL
  // ============================================================

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: hijau,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // PESAN ERROR
  // ============================================================

  void showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: krem,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: krem,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: hijauTua,
          ),
          onPressed: sedangRegister
              ? null
              : () {
                  Navigator.pop(context);
                },
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 25,
            vertical: 10,
          ),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 700,
              ),

              child: Form(
                key: _formKey,

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.center,

                  children: [
                    const SizedBox(height: 10),

                    // ==================================================
                    // JUDUL
                    // ==================================================

                    const Text(
                      'Buat Akun Baru',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: hijauTua,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ==================================================
                    // DESKRIPSI
                    // ==================================================

                    const Text(
                      'Daftarkan akun untuk menggunakan E-Santri.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ==================================================
                    // FOTO PROFIL
                    // ==================================================

                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hijauMuda,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        size: 52,
                        color: hijau,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // ==================================================
                    // UPLOAD FOTO
                    // ==================================================

                    TextButton.icon(
                      onPressed:
                          sedangRegister ? null : uploadFoto,
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        size: 19,
                      ),
                      label: const Text(
                        'Upload Foto',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: hijau,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // NAMA LENGKAP
                    // ==================================================

                    TextFormField(
                      controller: namaController,
                      textInputAction:
                          TextInputAction.next,
                      decoration: registerDecoration(
                        'Nama Lengkap',
                        Icons.person_outline,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Nama lengkap wajib diisi';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // USERNAME
                    // ==================================================

                    TextFormField(
                      controller: usernameController,
                      textInputAction:
                          TextInputAction.next,
                      decoration: registerDecoration(
                        'Username',
                        Icons.account_circle_outlined,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Username wajib diisi';
                        }

                        if (value.trim().length < 4) {
                          return 'Username minimal 4 karakter';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // EMAIL
                    // ==================================================

                    TextFormField(
                      controller: emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      textInputAction:
                          TextInputAction.next,
                      decoration: registerDecoration(
                        'Email',
                        Icons.email_outlined,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Email wajib diisi';
                        }

                        if (!emailValid(value)) {
                          return 'Format email tidak valid';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // NOMOR HP
                    // ==================================================

                    TextFormField(
                      controller: hpController,
                      keyboardType:
                          TextInputType.phone,
                      textInputAction:
                          TextInputAction.next,
                      decoration: registerDecoration(
                        'Nomor HP',
                        Icons.phone_outlined,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Nomor HP wajib diisi';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // JENIS KELAMIN
                    // ==================================================

                    DropdownButtonFormField<String>(
                      initialValue: jenisKelamin,
                      decoration: registerDecoration(
                        'Jenis Kelamin',
                        Icons.wc_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Laki-laki',
                          child: Text(
                            'Laki-laki',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Perempuan',
                          child: Text(
                            'Perempuan',
                          ),
                        ),
                      ],
                      onChanged: sedangRegister
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  jenisKelamin = value;
                                });
                              }
                            },
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // ROLE
                    // ==================================================

                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: registerDecoration(
                        'Role',
                        Icons.admin_panel_settings_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Pengurus',
                          child: Text(
                            'Pengurus',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Pengasuh / Kyai',
                          child: Text(
                            'Pengasuh / Kyai',
                          ),
                        ),
                      ],
                      onChanged: sedangRegister
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  role = value;
                                });
                              }
                            },
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // PASSWORD
                    // ==================================================

                    TextFormField(
                      controller: passwordController,
                      obscureText:
                          sembunyikanPassword,
                      textInputAction:
                          TextInputAction.next,
                      decoration: registerDecoration(
                        'Password',
                        Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            sembunyikanPassword
                                ? Icons
                                    .visibility_off_outlined
                                : Icons
                                    .visibility_outlined,
                            color: hijau,
                          ),
                          onPressed: sedangRegister
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
                        if (value == null ||
                            value.isEmpty) {
                          return 'Password wajib diisi';
                        }

                        if (!passwordValid(value)) {
                          return 'Minimal 8 karakter, huruf besar, kecil, dan angka';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // KONFIRMASI PASSWORD
                    // ==================================================

                    TextFormField(
                      controller:
                          konfirmasiController,
                      obscureText:
                          sembunyikanKonfirmasi,
                      textInputAction:
                          TextInputAction.done,
                      decoration: registerDecoration(
                        'Konfirmasi Password',
                        Icons.lock_reset_outlined,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            sembunyikanKonfirmasi
                                ? Icons
                                    .visibility_off_outlined
                                : Icons
                                    .visibility_outlined,
                            color: hijau,
                          ),
                          onPressed: sedangRegister
                              ? null
                              : () {
                                  setState(() {
                                    sembunyikanKonfirmasi =
                                        !sembunyikanKonfirmasi;
                                  });
                                },
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Konfirmasi password wajib diisi';
                        }

                        if (value !=
                            passwordController.text) {
                          return 'Password tidak sama';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 25),

                    // ==================================================
                    // TOMBOL DAFTAR
                    // ==================================================

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            sedangRegister ? null : register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hijauTua,
                          foregroundColor:
                              Colors.white,
                          disabledBackgroundColor:
                              hijauTua.withValues(
                            alpha: 0.6,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                        child: sedangRegister
                            ? const SizedBox(
                                width: 23,
                                height: 23,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Daftar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}