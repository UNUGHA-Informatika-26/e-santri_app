import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class ResetPasswordPage extends StatefulWidget {
  final String? email;
  final String? username;

  const ResetPasswordPage({
    super.key,
    this.email,
    this.username,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final passwordController = TextEditingController();
  final konfirmasiController = TextEditingController();

  bool sembunyikanPassword = true;
  bool sembunyikanKonfirmasi = true;

  @override
  void dispose() {
    passwordController.dispose();
    konfirmasiController.dispose();
    super.dispose();
  }

  bool get passwordMinimal {
    return passwordController.text.length >= 8;
  }

  bool get memilikiHuruf {
    return RegExp(r'[A-Za-z]').hasMatch(passwordController.text);
  }

  bool get memilikiAngka {
    return RegExp(r'[0-9]').hasMatch(passwordController.text);
  }

  bool get konfirmasiSama {
    return passwordController.text.isNotEmpty &&
        passwordController.text == konfirmasiController.text;
  }

  bool get passwordValid {
    return passwordMinimal &&
        memilikiHuruf &&
        memilikiAngka &&
        konfirmasiSama;
  }

  void _perbaruiPassword() {
    FocusScope.of(context).unfocus();

    setState(() {});

    if (passwordController.text.isEmpty ||
        konfirmasiController.text.isEmpty) {
      _tampilkanPesan('Silakan isi password terlebih dahulu.');
      return;
    }

    if (!passwordValid) {
      _tampilkanPesan('Pastikan semua syarat password sudah terpenuhi.');
      return;
    }

    // Proses perubahan password Supabase akan disambungkan
    // setelah mekanisme approval reset password selesai.

    _tampilkanPesan(
      'Password sudah memenuhi semua syarat.',
    );
  }

  void _tampilkanPesan(String pesan) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        behavior: SnackBarBehavior.floating,
        backgroundColor: hijauTua,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ukuran = MediaQuery.of(context).size;
    final lebarForm = ukuran.width > 600 ? 430.0 : ukuran.width * 0.88;

    final akun = widget.email?.isNotEmpty == true
        ? widget.email!
        : widget.username?.isNotEmpty == true
            ? widget.username!
            : 'Akun yang ditemukan';

    return Scaffold(
      backgroundColor: krem,
      appBar: AppBar(
        backgroundColor: krem,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: hijauTua,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Reset Password',
          style: TextStyle(
            color: hijauTua,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              24,
              8,
              24,
              32,
            ),
            child: SizedBox(
              width: lebarForm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Buat password baru',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Badge PEMULIHAN
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: hijauMuda.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PEMULIHAN',
                      style: TextStyle(
                        color: hijauTua,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'Akun Ditemukan',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Informasi akun
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: hijauMuda.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: hijauTua.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: hijauTua,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            akun,
                            style: const TextStyle(
                              color: hijauTua,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Password baru
                  const Text(
                    'Password Baru',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 7),

                  TextField(
                    controller: passwordController,
                    obscureText: sembunyikanPassword,
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Masukkan password baru',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        size: 19,
                        color: Colors.grey,
                      ),
                      suffixIcon: IconButton(
                        tooltip: sembunyikanPassword
                            ? 'Tampilkan password'
                            : 'Sembunyikan password',
                        icon: Icon(
                          sembunyikanPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            sembunyikanPassword =
                                !sembunyikanPassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.25),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(
                          color: hijau,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Konfirmasi password
                  const Text(
                    'Konfirmasi Password Baru',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 7),

                  TextField(
                    controller: konfirmasiController,
                    obscureText: sembunyikanKonfirmasi,
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Ulangi password baru',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        size: 19,
                        color: Colors.grey,
                      ),
                      suffixIcon: IconButton(
                        tooltip: sembunyikanKonfirmasi
                            ? 'Tampilkan password'
                            : 'Sembunyikan password',
                        icon: Icon(
                          sembunyikanKonfirmasi
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            sembunyikanKonfirmasi =
                                !sembunyikanKonfirmasi;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.25),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(
                          color: hijau,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Syarat password
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      14,
                      13,
                      14,
                      13,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Syarat password',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 9),

                        _SyaratPassword(
                          terpenuhi: passwordMinimal,
                          teks: 'Minimal 8 karakter',
                        ),

                        const SizedBox(height: 6),

                        _SyaratPassword(
                          terpenuhi: memilikiHuruf && memilikiAngka,
                          teks: 'Memiliki huruf dan angka',
                        ),

                        const SizedBox(height: 6),

                        _SyaratPassword(
                          terpenuhi: konfirmasiSama,
                          teks: 'Konfirmasi harus sama',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Tombol perbarui password
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _perbaruiPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hijau,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text(
                        'Perbarui Password',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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

class _SyaratPassword extends StatelessWidget {
  final bool terpenuhi;
  final String teks;

  const _SyaratPassword({
    required this.terpenuhi,
    required this.teks,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          terpenuhi
              ? Icons.check_circle_outline
              : Icons.radio_button_unchecked,
          size: 15,
          color: terpenuhi ? hijau : Colors.grey,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            teks,
            style: TextStyle(
              color: terpenuhi ? hijauTua : Colors.grey[700],
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}