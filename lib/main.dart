import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/supabase/supabase_config.dart';
import 'pages/auth/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeSupabase();

  runApp(const ESantriApp());
}

class ESantriApp extends StatelessWidget {
  const ESantriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}