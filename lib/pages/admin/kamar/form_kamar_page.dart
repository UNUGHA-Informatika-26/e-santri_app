import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/kamar_bloc.dart';
import '../../../core/constants/app_colors.dart';
import 'kamar_model.dart';
import 'kamar_service.dart';

/// Form kamar. Kalau [kamar] diisi, form berjalan dalam mode EDIT.
class FormKamarPage extends StatelessWidget {
  final Kamar? kamar;

  const FormKamarPage({super.key, this.kamar});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FormKamarBloc>(
      create: (_) => FormKamarBloc(service: KamarService(), kamar: kamar)
        ..add(const FormKamarDimuat()),
      child: _Tampilan(kamar: kamar),
    );
  }
}

class _Tampilan extends StatefulWidget {
  final Kamar? kamar;

  const _Tampilan({required this.kamar});

  @override
  State<_Tampilan> createState() => _TampilanState();
}

class _TampilanState extends State<_Tampilan> {
  // Urusan tampilan: isi kolom nama dan validasi form.
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nama = TextEditingController();

  bool get _modeEdit => widget.kamar != null;

  @override
  void initState() {
    super.initState();
    _nama.text = widget.kamar?.namaKamar ?? '';
  }

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  void _simpan(BuildContext context) {
    final bloc = context.read<FormKamarBloc>();

    if (bloc.state.menyimpan) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    bloc.add(FormKamarSimpanDitekan(_nama.text));
  }

  void _tanganiState(BuildContext context, FormKamarState s) {
    if (s.selesai) {
      Navigator.pop(context, true);
      return;
    }

    final error = s.error;
    if (error != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _bagianGender(
    BuildContext context,
    FormKamarState s,
    OutlineInputBorder Function(Color) garis,
  ) {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: s.gender,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Jenis kamar',
        helperText:
            _modeEdit ? 'Jenis kamar tidak bisa diubah setelah dibuat.' : null,
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Colors.black54),
        floatingLabelStyle: const TextStyle(color: hijau),
        enabledBorder: garis(Colors.grey.shade300),
        focusedBorder: garis(hijau),
        errorBorder: garis(Colors.red.shade700),
        focusedErrorBorder: garis(Colors.red.shade700),
      ),
      items: const [
        DropdownMenuItem<String>(value: 'putra', child: Text('Putra')),
        DropdownMenuItem<String>(value: 'putri', child: Text('Putri')),
      ],
      onChanged: (s.menyimpan || _modeEdit)
          ? null
          : (v) => context.read<FormKamarBloc>().add(FormKamarGenderDiubah(v)),
      validator: (v) {
        if (v == null) {
          return 'Pilih jenis kamar: Putra atau Putri';
        }

        return null;
      },
    );
  }

  Widget _bagianPengurus(
    BuildContext context,
    FormKamarState s,
    OutlineInputBorder Function(Color) garis,
  ) {
    if (s.memuatPengurus) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: hijau),
          ),
        ),
      );
    }

    if (!s.pengurusTermuat) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          'Daftar pengurus gagal dimuat. ${s.errorPengurus ?? ''}',
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      );
    }

    if (s.gender == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text(
          'Pilih jenis kamar dulu untuk melihat pengurus yang sesuai.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      );
    }

    final daftar = s.pengurusSesuai;

    // Kalau pengurus saat ini tidak ada di daftar, dropdown tampil kosong
    // tanpa error, dan pilihan awal tetap tidak berubah.
    final nilai = daftar.any((p) => p.id == s.pengurusDipilih)
        ? s.pengurusDipilih
        : null;

    return DropdownButtonFormField<String?>(
      // ignore: deprecated_member_use
      value: nilai,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Pengurus kamar',
        helperText: daftar.isEmpty
            ? 'Belum ada pengurus ${s.gender == 'putri' ? 'putri' : 'putra'} yang aktif.'
            : null,
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Colors.black54),
        floatingLabelStyle: const TextStyle(color: hijau),
        enabledBorder: garis(Colors.grey.shade300),
        focusedBorder: garis(hijau),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Belum ada pengurus'),
        ),
        ...daftar.map((p) {
          final dikamarLain =
              p.kamarId != null && p.kamarId != widget.kamar?.id;

          return DropdownMenuItem<String?>(
            value: p.id,
            child: Text(
              dikamarLain ? '${p.nama} (memegang kamar lain)' : p.nama,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
      onChanged: s.menyimpan
          ? null
          : (v) => context
              .read<FormKamarBloc>()
              .add(FormKamarPengurusDipilih(v)),
    );
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder garis(Color warna) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: warna),
        );

    return BlocConsumer<FormKamarBloc, FormKamarState>(
      listenWhen: (a, b) => b.selesai || b.error != null,
      listener: _tanganiState,
      builder: (context, s) {
        return Scaffold(
          backgroundColor: krem,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed:
                            s.menyimpan ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: hijauTua),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _modeEdit ? 'Edit Kamar' : 'Tambah Kamar',
                              style: const TextStyle(
                                color: hijauTua,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _modeEdit
                                  ? 'Ubah nama dan pengurus kamar'
                                  : 'Data kamar baru',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nama,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Nama kamar',
                              hintText: 'Contoh: A-01',
                              filled: true,
                              fillColor: Colors.white,
                              labelStyle:
                                  const TextStyle(color: Colors.black54),
                              floatingLabelStyle:
                                  const TextStyle(color: hijau),
                              enabledBorder: garis(Colors.grey.shade300),
                              focusedBorder: garis(hijau),
                              errorBorder: garis(Colors.red.shade700),
                              focusedErrorBorder: garis(Colors.red.shade700),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Nama kamar wajib diisi';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _bagianGender(context, s, garis),
                          const SizedBox(height: 16),
                          _bagianPengurus(context, s, garis),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed:
                                  s.menyimpan ? null : () => _simpan(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hijau,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    hijau.withValues(alpha: 0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: s.menyimpan
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _modeEdit
                                          ? 'Simpan Perubahan'
                                          : 'Simpan Kamar',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}