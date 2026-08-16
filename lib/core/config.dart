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

  static const String posthogApiKey = String.fromEnvironment(
    'POSTHOG_API_KEY',
    defaultValue: '',
  );

  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  static bool get isConfigured =>
      supabaseUrl.contains('YOUR-PROJECT') == false &&
      supabaseAnonKey.contains('YOUR-ANON-KEY') == false;

  static bool get analyticsConfigured => posthogApiKey.isNotEmpty;

  static bool get crashReportingConfigured => sentryDsn.isNotEmpty;

  static Future<void> initSupabase() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }
}

SupabaseClient get supabase => Supabase.instance.client;
