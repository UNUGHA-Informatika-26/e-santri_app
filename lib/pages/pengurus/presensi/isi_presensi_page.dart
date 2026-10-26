import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/isi_presensi_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/dashboard_widgets.dart';
import 'presensi_berhasil_page.dart';
import 'presensi_service.dart';

const _hari = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

const _bulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const _opsiStatus = ['hadir', 'izin', 'sakit', 'alfa'];

String _labelTanggal(DateTime t) {
  return '${_hari[t.weekday - 1]}, ${t.day} ${_bulan[t.month - 1]} ${t.year}';
}

String _labelStatus(String s) {
  return s.substring(0, 1).toUpperCase() + s.substring(1);
}

Color _warnaStatus(String s) {
  switch (s) {
    case 'hadir':
      return hijau;
    case 'izin':
      return Colors.blue.shade600;
    case 'sakit':
      return Colors.amber.shade700;
    default:
      return Colors.red.shade600;
  }
}

class IsiPresensiPage extends StatelessWidget {
  final String namaPengurus;

  const IsiPresensiPage({
    super.key,
    this.namaPengurus = 'Pengurus',
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<IsiPresensiBloc>(
      create: (_) => IsiPresensiBloc(service: PresensiService())
        ..add(const IsiPresensiDimuat()),
      child: _Tampilan(namaPengurus: namaPengurus),
    );
  }
}

class _Tampilan extends StatelessWidget {
  final String namaPengurus;

  const _Tampilan({required this.namaPengurus});

  void _snack(BuildContext context, String pesan) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: hijau,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _tanganiState(BuildContext context, IsiPresensiState s) {
    final pesan = s.pesan;
    if (pesan != null) {
      _snack(context, pesan);
    }

    final h = s.hasilSimpan;
    if (h != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PresensiBerhasilPage(
            tanggal: _labelTanggal(h.tanggal),
            kegiatan: h.kegiatan,
            kamar: h.kamar,
            pengurus: namaPengurus,
            hadir: h.hadir,
            izin: h.izin,
            sakit: h.sakit,
            alfa: h.alfa,
            menunggu: h.menunggu,
          ),
        ),
      );
    }
  }

  Future<void> _pilihTanggal(BuildContext context, IsiPresensiState s) async {
    final bloc = context.read<IsiPresensiBloc>();

    final hasil = await showDatePicker(
      context: context,
      initialDate: s.tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (hasil == null) return;
    bloc.add(IsiPresensiTanggalDipilih(hasil));
  }

  Future<void> _pilihKegiatan(
    BuildContext context,
    IsiPresensiState s,
  ) async {
    final bloc = context.read<IsiPresensiBloc>();

    final hasil = await showModalBottomSheet<KegiatanPilihan>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              for (final k in s.daftarKegiatan)
                ListTile(
                  title: Text(
                    k.nama,
                    style: const TextStyle(
                      color: hijauTua,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: k.id == s.kegiatan?.id
                      ? const Icon(Icons.check, color: hijau)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, k),
                ),
            ],
          ),
        );
      },
    );

    if (hasil == null) return;
    bloc.add(IsiPresensiKegiatanDipilih(hasil));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IsiPresensiBloc, IsiPresensiState>(
      listenWhen: (a, b) => b.pesan != null || b.hasilSimpan != null,
      listener: _tanganiState,
      builder: (context, s) {
        return PopScope(
          canPop: s.langkah == 1,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              context
                  .read<IsiPresensiBloc>()
                  .add(const IsiPresensiKembaliDitekan());
            }
          },
          child: Scaffold(
            backgroundColor: krem,
            body: SafeArea(
              child: Column(
                children: [
                  _header(context, s),
                  Expanded(child: _isi(context, s)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, IsiPresensiState s) {
    final judul = s.langkah == 1 ? 'Presensi Santri' : 'Daftar Santri';
    final sub = s.langkah == 1
        ? 'Langkah 1 dari 2'
        : 'Kamar ${s.kamar?.namaKamar ?? '-'} • ${s.santri.length} santri';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (s.langkah == 2) {
                context
                    .read<IsiPresensiBloc>()
                    .add(const IsiPresensiKembaliDitekan());
              } else {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.arrow_back, color: hijauTua),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: const TextStyle(
                    color: hijauTua,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _isi(BuildContext context, IsiPresensiState s) {
    if (s.memuat) {
      return const Center(child: CircularProgressIndicator(color: hijau));
    }

    if (s.error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: KartuPutih(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data gagal dimuat.',
                style: TextStyle(color: hijauTua, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                s.error!,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              TextButton(
                onPressed: () => context
                    .read<IsiPresensiBloc>()
                    .add(const IsiPresensiDimuat()),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (s.kamar == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: KartuPutih(
          child: Text(
            'Kamu belum ditugaskan ke kamar mana pun. '
            'Minta Admin mengatur Kamar Tugas di Data Pengurus.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    if (s.daftarKegiatan.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: KartuPutih(
          child: Text(
            'Belum ada kegiatan aktif. Minta Admin menambahkannya di Data Kegiatan.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return s.langkah == 1 ? _langkahSatu(context, s) : _langkahDua(context, s);
  }

  // ---------------- LANGKAH 1 ----------------

  Widget _label(String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 14),
      child: Text(
        teks,
        style: const TextStyle(color: Colors.black54, fontSize: 12),
      ),
    );
  }

  Widget _kotakPilihan({
    required IconData ikon,
    required String teks,
    VoidCallback? onTap,
    bool terkunci = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: terkunci ? Colors.grey.shade200 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(ikon, size: 18, color: Colors.black54),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                teks,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
            ),
            Icon(
              terkunci ? Icons.lock_outline : Icons.keyboard_arrow_down,
              size: 18,
              color: Colors.black45,
            ),
          ],
        ),
      ),
    );
  }

  Widget _baris(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          Text(
            nilai,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _langkahSatu(BuildContext context, IsiPresensiState s) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hijauMuda.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Siapkan presensi',
                style: TextStyle(
                  color: hijauTua,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tanggal dan kegiatan menentukan daftar santri. '
                'Kamar mengikuti tugas aktif Anda.',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        _label('Tanggal'),
        _kotakPilihan(
          ikon: Icons.calendar_today_outlined,
          teks: _labelTanggal(s.tanggal),
          onTap: () => _pilihTanggal(context, s),
        ),
        _label('Kegiatan'),
        _kotakPilihan(
          ikon: Icons.schedule,
          teks: s.kegiatan?.nama ?? 'Pilih kegiatan',
          onTap: () => _pilihKegiatan(context, s),
        ),
        _label('Kamar Tugas'),
        _kotakPilihan(
          ikon: Icons.bed_outlined,
          teks: 'Kamar ${s.kamar?.namaKamar ?? '-'}',
          terkunci: true,
        ),
        const SizedBox(height: 14),
        KartuPutih(
          child: Column(
            children: [
              _baris('Pengurus', namaPengurus),
              _baris('Jumlah Santri', '${s.santri.length}'),
              _baris(
                'Status laporan',
                s.laporanSudahAda ? 'Sudah disimpan' : 'Belum dibuat',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => context
                .read<IsiPresensiBloc>()
                .add(const IsiPresensiLanjutDitekan()),
            icon: const Icon(Icons.arrow_forward),
            label: const Text(
              'Lanjut ke Daftar Santri',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: hijau,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kamar Tugas otomatis dan terkunci sesuai penugasan Admin.',
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- LANGKAH 2 ----------------

  Widget _pilihanStatus(BuildContext context, IsiPresensiState s, String id) {
    final terpilih = s.status[id];

    return Row(
      children: [
        for (final opsi in _opsiStatus) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => context
                  .read<IsiPresensiBloc>()
                  .add(IsiPresensiStatusDipilih(id, opsi)),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: terpilih == opsi
                      ? _warnaStatus(opsi).withValues(alpha: 0.18)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: terpilih == opsi
                        ? _warnaStatus(opsi)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  _labelStatus(opsi),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: terpilih == opsi
                        ? _warnaStatus(opsi)
                        : Colors.black54,
                  ),
                ),
              ),
            ),
          ),
          if (opsi != _opsiStatus.last) const SizedBox(width: 6),
        ],
      ],
    );
  }

  Widget _kartuSantri(
    BuildContext context,
    IsiPresensiState st,
    SantriPresensi s,
  ) {
    final terpilih = st.status[s.id];
    final perluKeterangan = terpilih != null && terpilih != 'hadir';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: hijauMuda.withValues(alpha: 0.3),
                child: Text(
                  s.inisial,
                  style: const TextStyle(
                    color: hijauTua,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'NIS ${s.nis}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _pilihanStatus(context, st, s.id),
          if (perluKeterangan) ...[
            const SizedBox(height: 8),
            _KolomKeterangan(
              key: ValueKey('ket_${s.id}'),
              awal: st.keterangan[s.id] ?? '',
              onChanged: (teks) => context
                  .read<IsiPresensiBloc>()
                  .add(IsiPresensiKeteranganDiubah(s.id, teks)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _langkahDua(BuildContext context, IsiPresensiState s) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hijauMuda.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.kegiatan?.nama ?? '-',
                      style: const TextStyle(
                        color: hijauTua,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_labelTanggal(s.tanggal)} • Kamar ${s.kamar?.namaKamar ?? '-'}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${s.status.length}/${s.santri.length} terisi',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final santri in s.santri) _kartuSantri(context, s, santri),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: s.menyimpan
                ? null
                : () => context
                    .read<IsiPresensiBloc>()
                    .add(const IsiPresensiSimpanDitekan()),
            icon: s.menyimpan
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              s.menyimpan ? 'Menyimpan...' : 'Simpan Presensi',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: hijau,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Kolom keterangan dengan controller sendiri (urusan tampilan).
/// Teks dikirim ke Bloc setiap berubah.
class _KolomKeterangan extends StatefulWidget {
  final String awal;
  final ValueChanged<String> onChanged;

  const _KolomKeterangan({
    super.key,
    required this.awal,
    required this.onChanged,
  });

  @override
  State<_KolomKeterangan> createState() => _KolomKeteranganState();
}

class _KolomKeteranganState extends State<_KolomKeterangan> {
  late final TextEditingController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = TextEditingController(text: widget.awal);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctl,
      onChanged: widget.onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Keterangan (boleh dikosongkan)',
        hintStyle: const TextStyle(fontSize: 12),
        isDense: true,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}