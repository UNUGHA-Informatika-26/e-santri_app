import 'package:flutter/foundation.dart';

/// Penanda di memori: bertambah setiap pengurus menekan "Selesai"
/// di layar Presensi Berhasil. Dashboard mendengarkan penanda ini.
final ValueNotifier<int> penandaPresensiSelesai = ValueNotifier<int>(0);

void tandaiPresensiSelesai() {
  penandaPresensiSelesai.value++;
}