import 'dart:convert';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:http/http.dart' as http;

/// Satu-satunya kode offline untuk SEMUA data yang dibaca dari Supabase.
/// Permintaan baca (GET ke /rest/v1/) disimpan ke Hive saat online,
/// dan dibaca dari Hive saat internet putus.
class CacheHttpClient extends http.BaseClient {
  final http.Client _inner;

  CacheHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  static const _kotak = 'cache_http';
  static Future<void>? _siap;

  static Future<void> _init() {
    return _siap ??= () async {
      await Hive.initFlutter();
      await Hive.openBox(_kotak);
    }();
  }

  // Kunci Hive dibatasi 255 karakter, jadi alamat panjang di-hash.
  static String _kunci(String url) {
    var a = 0x811c9dc5;
    var b = 0x01000193;
    for (final c in url.codeUnits) {
      a = ((a ^ c) * 16777619) & 0xFFFFFFFF;
      b = ((b + c) * 31 + a) & 0xFFFFFFFF;
    }
    return '${a.toRadixString(16)}_${b.toRadixString(16)}_${url.length}';
  }

  bool _bisaDicache(http.BaseRequest r) =>
      r.method == 'GET' && r.url.path.contains('/rest/v1/');

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!_bisaDicache(request)) {
      return _inner.send(request);
    }

    final kunci = _kunci(request.url.toString());

    try {
      final res = await _inner.send(request);
      final bytes = await res.stream.toBytes();

      if (res.statusCode == 200) {
        try {
          await _init();
          await Hive.box(_kotak).put(
            kunci,
            jsonEncode({
              'body': utf8.decode(bytes),
              'range': res.headers['content-range'],
            }),
          );
        } catch (_) {
          // Cache hanya bonus.
        }
      }

      return http.StreamedResponse(
        Stream.value(bytes),
        res.statusCode,
        contentLength: bytes.length,
        request: request,
        headers: res.headers,
        reasonPhrase: res.reasonPhrase,
      );
    } catch (e) {
      // Gagal (misalnya tidak ada internet): pakai salinan terakhir.
      try {
        await _init();
        final v = Hive.box(_kotak).get(kunci);
        if (v == null) rethrow;

        final m = jsonDecode(v as String) as Map;
        final bytes = utf8.encode(m['body'] as String);

        return http.StreamedResponse(
          Stream.value(bytes),
          200,
          contentLength: bytes.length,
          request: request,
          headers: {
            'content-type': 'application/json; charset=utf-8',
            if (m['range'] != null) 'content-range': m['range'] as String,
          },
        );
      } catch (_) {
        throw e;
      }
    }
  }
}