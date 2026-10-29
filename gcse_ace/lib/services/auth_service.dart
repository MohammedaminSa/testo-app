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

  /// Get the role of a user from the profiles table.
  ///
  /// Uses `.maybeSingle()` so a missing row does not throw an unhandled
  /// PostgrestException. If no profile exists yet, it creates a default
  /// student record as a graceful fallback.
  Future<String?> getUserRole(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        // Fallback: If trigger hasn't fired yet or wasn't set up, ensure profile exists
        final user = currentUser;
        final name = (user?.userMetadata?['full_name'] as String?)?.trim();
        final fallbackName = (name != null && name.isNotEmpty)
            ? name
            : (user?.email?.split('@').first ?? 'Student');
        await _client.from('profiles').upsert({
          'id': userId,
          'full_name': fallbackName,
          'role': 'student',
        });
        return 'student';
      }

      return data['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Convenience: check if current user is admin.
  Future<bool> isCurrentUserAdmin() async {
    final user = currentUser;
    if (user == null) return false;
    final role = await getUserRole(user.id);
    return role == 'admin';
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null && fullName.isNotEmpty
          ? {'full_name': fullName}
          : null,
    );

    final user = response.user;
    if (user != null) {
      try {
        final displayName = (fullName != null && fullName.isNotEmpty)
            ? fullName
            : email.split('@').first;
        await _client.from('profiles').upsert({
          'id': user.id,
          'full_name': displayName,
          'role': 'student',
        });
      } catch (_) {
        // Trigger on_auth_user_created handles this if client insert fails
      }
    }

    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
