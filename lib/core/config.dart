import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR-PROJECT.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR-ANON-KEY',
  );

  static bool get isConfigured =>
      supabaseUrl.contains('YOUR-PROJECT') == false &&
      supabaseAnonKey.contains('YOUR-ANON-KEY') == false;

  static Future<void> initSupabase() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }
}

SupabaseClient get supabase => Supabase.instance.client;
