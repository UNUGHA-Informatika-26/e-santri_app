import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'santri_model.dart';
import 'santri_service.dart';

/// Form santri. Kalau [santri] diisi, form berjalan dalam mode EDIT.
class TambahSantriPage extends StatefulWidget {
  final Santri? santri;

  const TambahSantriPage({super.key, this.santri});

  @override
  State<TambahSantriPage> createState() => _TambahSantriPageState();
}

class _TambahSantriPageState extends State<TambahSantriPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nama = TextEditingController();
  final TextEditingController _nis = TextEditingController();
  final TextEditingController _noHp = TextEditingController();
  final TextEditingController _alamat = TextEditingController();

  final SantriService _service = SantriService();

  String? _gender; // putra / putri
  String? _kamarId;

  List<KamarPilihan> _kamar = [];
  bool _memuatKamar = true;
  bool _menyimpan = false;

  bool get _modeEdit => widget.santri != null;

  @override
  void initState() {
    super.initState();

    final s = widget.santri;
    if (s != null) {
      _nama.text = s.namaLengkap;
      _nis.text = s.nis;
      _noHp.text = s.noHp ?? '';
      _alamat.text = s.alamat ?? '';
      _gender = (s.gender == 'putra' || s.gender == 'putri') ? s.gender : null;
      _kamarId = s.kamarId;
    }

    _muatKamar();
  }

  @override
  void dispose() {
    _nama.dispose();
    _nis.dispose();
    _noHp.dispose();
    _alamat.dispose();
    super.dispose();
  }

  // ============================================================
  // MUAT KAMAR (opsional: kalau gagal, form tetap bisa dipakai)
  // ============================================================

  Future<void> _muatKamar() async {
    try {
      var data = await _service.ambilKamarAktif();

      // Mode edit: kalau kamar santri sekarang sudah nonaktif, tetap
      // tampilkan supaya pilihan dropdown tidak error.
      final s = widget.santri;
      if (s != null &&
          s.kamarId != null &&
          !data.any((k) => k.id == s.kamarId)) {
        data = [
          ...data,
          KamarPilihan(
            id: s.kamarId!,
            nama: '${s.namaKamar ?? 'Kamar lama'} (nonaktif)',
          ),
        ];
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _kamar = data;
        _memuatKamar = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _memuatKamar = false;
      });
    }
  }

  // ============================================================
  // SIMPAN
  // ============================================================

  Future<void> _simpan() async {
    if (_menyimpan) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _menyimpan = true;
    });

    final noHp = _noHp.text.replaceAll(RegExp(r'[\s\-]'), '');

    try {
      if (_modeEdit) {
        await _service.perbarui(
          id: widget.santri!.id,
          nis: _nis.text,
          namaLengkap: _nama.text,
          gender: _gender!,
          kamarId: _kamarId,
          noHp: noHp,
          alamat: _alamat.text,
        );
      } else {
        await _service.tambah(
          nis: _nis.text,
          namaLengkap: _nama.text,
          gender: _gender!,
          kamarId: _kamarId,
          noHp: noHp,
          alamat: _alamat.text,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } on SantriException catch (e) {
      if (!mounted) {
        return;
      }

      _tampilkanError(e.pesan);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _tampilkanError('Terjadi kesalahan saat menyimpan santri.');
    } finally {
      if (mounted) {
        setState(() {
          _menyimpan = false;
        });
      }
    }
  }

  void _tampilkanError(String pesan) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // TAMPILAN
  // ============================================================

  InputDecoration _dekorasi(String label, {String? hint}) {
    OutlineInputBorder garis(Color warna) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: warna),
        );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Colors.black54),
      floatingLabelStyle: const TextStyle(color: hijau),
      enabledBorder: garis(Colors.grey.shade300),
      focusedBorder: garis(hijau),
      errorBorder: garis(Colors.red.shade700),
      focusedErrorBorder: garis(Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        _menyimpan ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: hijauTua),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _modeEdit ? 'Edit Santri' : 'Tambah Santri',
                          style: const TextStyle(
                            color: hijauTua,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _modeEdit
                              ? 'Ubah data identitas dan wali'
                              : 'Data identitas dan wali',
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
                        decoration:
                            _dekorasi('Nama lengkap', hint: 'Nama santri'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Nama lengkap wajib diisi';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nis,
                        decoration: _dekorasi('NIS', hint: 'Contoh: 2026012'),
                        validator: (v) {
                          final nilai = v?.trim() ?? '';

                          if (nilai.isEmpty) {
                            return 'NIS wajib diisi';
                          }

                          if (nilai.contains(' ')) {
                            return 'NIS tidak boleh berisi spasi';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: _dekorasi('Jenis kelamin'),
                        items: const [
                          DropdownMenuItem(
                            value: 'putra',
                            child: Text('Laki-laki'),
                          ),
                          DropdownMenuItem(
                            value: 'putri',
                            child: Text('Perempuan'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _gender = v;
                          });
                        },
                        validator: (v) {
                          if (v == null) {
                            return 'Pilih jenis kelamin';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        // Key berubah setelah kamar selesai dimuat, supaya
                        // nilai awal (mode edit) terpasang dengan benar.
                        key: ValueKey('kamar-$_memuatKamar'),
                        initialValue:
                            _kamar.any((k) => k.id == _kamarId)
                                ? _kamarId
                                : null,
                        decoration: _dekorasi(
                          'Kamar',
                          hint: _memuatKamar
                              ? 'Memuat kamar…'
                              : (_kamar.isEmpty
                                  ? 'Belum ada kamar aktif'
                                  : 'Pilih kamar (opsional)'),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Belum ditentukan'),
                          ),
                          for (final k in _kamar)
                            DropdownMenuItem<String>(
                              value: k.id,
                              child: Text(k.nama),
                            ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _kamarId = v;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _noHp,
                        keyboardType: TextInputType.phone,
                        decoration: _dekorasi(
                          'Nomor HP wali',
                          hint: 'Contoh: 081234567890',
                        ),
                        validator: (v) {
                          final nilai =
                              (v ?? '').replaceAll(RegExp(r'[\s\-]'), '');

                          if (nilai.isEmpty) {
                            return null;
                          }

                          if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(nilai)) {
                            return 'Nomor HP harus 9–15 angka';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _alamat,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _dekorasi('Alamat'),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _menyimpan ? null : _simpan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hijau,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                hijau.withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _menyimpan
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
                                      : 'Simpan Santri',
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
  }
}