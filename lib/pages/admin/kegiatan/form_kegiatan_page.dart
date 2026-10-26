import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/kegiatan_bloc.dart';
import '../../../core/constants/app_colors.dart';
import 'kegiatan_model.dart';
import 'kegiatan_service.dart';

/// Form kegiatan. Kalau [kegiatan] diisi, form berjalan dalam mode EDIT
/// (lengkap dengan tombol Hapus). Menutup halaman dengan hasil pesan String.
class FormKegiatanPage extends StatelessWidget {
  final Kegiatan? kegiatan;

  const FormKegiatanPage({super.key, this.kegiatan});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FormKegiatanBloc>(
      create: (_) => FormKegiatanBloc(
        service: KegiatanService(),
        kegiatan: kegiatan,
      ),
      child: _Tampilan(kegiatan: kegiatan),
    );
  }
}

class _Tampilan extends StatefulWidget {
  final Kegiatan? kegiatan;

  const _Tampilan({required this.kegiatan});

  @override
  State<_Tampilan> createState() => _TampilanState();
}

class _TampilanState extends State<_Tampilan> {
  // Urusan tampilan: isi kolom dan validasi form.
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nama = TextEditingController();
  final TextEditingController _deskripsi = TextEditingController();

  bool _aktif = true;

  bool get _modeEdit => widget.kegiatan != null;

  @override
  void initState() {
    super.initState();
    _nama.text = widget.kegiatan?.namaKegiatan ?? '';
    _deskripsi.text = widget.kegiatan?.deskripsi ?? '';
    _aktif = widget.kegiatan?.aktif ?? true;
  }

  @override
  void dispose() {
    _nama.dispose();
    _deskripsi.dispose();
    super.dispose();
  }

  // ============================================================
  // AKSI (dikirim ke Bloc)
  // ============================================================

  void _simpan(BuildContext context) {
    if (context.read<FormKegiatanBloc>().state.bekerja) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    context.read<FormKegiatanBloc>().add(
          FormKegiatanSimpanDitekan(
            nama: _nama.text,
            deskripsi: _deskripsi.text,
            aktif: _aktif,
          ),
        );
  }

  Future<void> _hapus(BuildContext context) async {
    final bloc = context.read<FormKegiatanBloc>();

    final bool? yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kegiatan?'),
        content: Text(
          'Kegiatan ${widget.kegiatan!.namaKegiatan} akan dihapus permanen dan tidak bisa dikembalikan. Kalau hanya ingin berhenti dipakai, lebih baik dinonaktifkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Hapus',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (yakin != true) return;

    bloc.add(const FormKegiatanHapusDitekan());
  }

  void _tanganiState(BuildContext context, FormKegiatanState s) {
    final selesai = s.selesai;
    if (selesai != null) {
      Navigator.pop(context, selesai);
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

  // ============================================================
  // KOMPONEN TAMPILAN
  // ============================================================

  Widget _kartuRingkasan() {
    final k = widget.kegiatan!;
    final Color warna = k.aktif ? hijau : Colors.grey.shade600;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hijauMuda.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  k.namaKegiatan,
                  style: const TextStyle(
                    color: hijauTua,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  k.labelDeskripsi,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              k.aktif ? 'Aktif' : 'Nonaktif',
              style: TextStyle(
                color: warna,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder garis(Color warna) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: warna),
        );

    InputDecoration hiasan(String label, {String? petunjuk}) {
      return InputDecoration(
        labelText: label,
        hintText: petunjuk,
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

    return BlocConsumer<FormKegiatanBloc, FormKegiatanState>(
      listenWhen: (a, b) => b.selesai != null || b.error != null,
      listener: _tanganiState,
      builder: (context, s) {
        final bekerja = s.bekerja;

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
                            bekerja ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: hijauTua),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _modeEdit
                                  ? 'Detail Kegiatan'
                                  : 'Tambah Kegiatan',
                              style: const TextStyle(
                                color: hijauTua,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _modeEdit
                                  ? 'Edit atau hapus'
                                  : 'Data kegiatan baru',
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
                          if (_modeEdit) ...[
                            _kartuRingkasan(),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _nama,
                            textCapitalization: TextCapitalization.words,
                            decoration: hiasan(
                              'Nama kegiatan',
                              petunjuk: 'Contoh: Sholat Subuh',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Nama kegiatan wajib diisi';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _deskripsi,
                            minLines: 2,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: hiasan(
                              'Deskripsi (boleh kosong)',
                              petunjuk: 'Contoh: Presensi jamaah seluruh kamar',
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<bool>(
                            // ignore: deprecated_member_use
                            value: _aktif,
                            isExpanded: true,
                            decoration: hiasan('Status'),
                            items: const [
                              DropdownMenuItem<bool>(
                                value: true,
                                child: Text('Aktif'),
                              ),
                              DropdownMenuItem<bool>(
                                value: false,
                                child: Text('Nonaktif'),
                              ),
                            ],
                            onChanged: bekerja
                                ? null
                                : (v) {
                                    setState(() {
                                      _aktif = v ?? true;
                                    });
                                  },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed:
                                        bekerja ? null : () => _simpan(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: hijau,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          hijau.withValues(alpha: 0.6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: bekerja
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Simpan Kegiatan',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              if (_modeEdit) ...[
                                const SizedBox(width: 10),
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed:
                                        bekerja ? null : () => _hapus(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade600,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
                                      'Hapus',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
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