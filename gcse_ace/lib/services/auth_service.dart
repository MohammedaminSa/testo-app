import 'package:supabase_flutter/supabase_flutter.dart';

/// A thin wrapper around Supabase's auth so screens don't talk to the SDK
/// directly — they just call `signIn`, `signUp`, `signOut`.
class AuthService {
  AuthService._();

  /// Global access point. Everyone shares one Supabase client.
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Reacts to login/logout/session-refresh events. UI listens to this.
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// True if there is an active (logged-in) session.
  bool get isSignedIn => _client.auth.currentSession != null;

  /// The current user, or null when logged out.
  User? get currentUser => _client.auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
