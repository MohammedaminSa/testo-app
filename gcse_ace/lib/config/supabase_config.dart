import 'package:supabase_flutter/supabase_flutter.dart';

/// Central place for Supabase connection details.
///
/// The publishable key is a *public* key designed to be embedded in client
/// apps — it is not a secret like the service-role key. It only grants access
/// to what Row Level Security allows.
abstract final class SupabaseConfig {
  static const String url = 'https://wpxkwxoalubibrnbdejo.supabase.co';
  static const String publishableKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndweGt3eG9hbHViaWJybmJkZWpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc2NjE5MDIsImV4cCI6MjEwMzIzNzkwMn0.J1NNige8BMDxDgdrVfo9Q_-cg4nvR0JvepDlkwYnZxo';

  /// Wires up the global Supabase client. Call once before [WidgetsFlutterBinding].
  static Future<void> initialize() {
    return Supabase.initialize(url: url, publishableKey: publishableKey);
  }
}
