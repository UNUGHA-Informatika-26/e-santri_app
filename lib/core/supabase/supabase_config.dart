import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl =
    'https://krupdsnjimlocdsvyeqz.supabase.co';

const String supabasePublishableKey =
    'sb_publishable_lb8jgXczSHIf41Y5BDVdZQ_A007KlR3';

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
}

SupabaseClient get supabase {
  return Supabase.instance.client;
}