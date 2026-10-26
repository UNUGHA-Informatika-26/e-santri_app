import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/auth/auth_bloc.dart';
import 'core/constants/app_colors.dart';
import 'core/offline/presensi_offline.dart';
import 'core/supabase/supabase_config.dart';
import 'pages/auth/splash_page.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeSupabase();

  // Mulai pantau internet & kirim antrean yang menunggu
  // (aman dipanggil meski user belum login / belum buka Isi Presensi).
  SinkronPresensi.instance.mulai();

  runApp(const ESantriApp());
}

class ESantriApp extends StatelessWidget {
  const ESantriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => AuthBloc(authService: AuthService()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'E-Santri',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: krem,
          colorScheme: ColorScheme.fromSeed(
            seedColor: hijauTua,
          ),
          fontFamily: 'Roboto',
        ),
        home: const SplashPage(),
      ),
    );
  }
}