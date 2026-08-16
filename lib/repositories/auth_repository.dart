import 'package:supabase_flutter/supabase_flutter.dart';

/// All auth operations go through here so screens never touch Supabase
/// directly. Backed by a single injected [SupabaseClient].
class AuthRepository {
  final SupabaseClient _client;

  const AuthRepository(this._client);

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) {
    return _client.auth.signUp(email: email, password: password, data: data);
  }

  Future<void> signInWithOAuth(OAuthProvider provider) {
    return _client.auth.signInWithOAuth(provider);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> resetPasswordForEmail(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }
}