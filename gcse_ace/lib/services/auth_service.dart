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

  /// Returns the current user's display name or username.
  String get currentDisplayName {
    final user = currentUser;
    if (user == null) return 'Student';
    final metadata = user.userMetadata;
    if (metadata != null) {
      final username = metadata['username'] as String?;
      if (username != null && username.trim().isNotEmpty) return username.trim();
      final fullName = metadata['full_name'] as String?;
      if (fullName != null && fullName.trim().isNotEmpty) return fullName.trim();
    }
    return user.email?.split('@').first ?? 'Student';
  }

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
        final name = (user?.userMetadata?['username'] as String?)?.trim() ??
            (user?.userMetadata?['full_name'] as String?)?.trim();
        final fallbackName = (name != null && name.isNotEmpty)
            ? name
            : (user?.email?.split('@').first ?? 'Student');
        await _client.from('profiles').upsert({
          'id': userId,
          'username': fallbackName,
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
    String? username,
    String? fullName,
  }) async {
    final chosenName = (username != null && username.trim().isNotEmpty)
        ? username.trim()
        : (fullName != null && fullName.trim().isNotEmpty ? fullName.trim() : null);

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: chosenName != null
          ? {
              'username': chosenName,
              'full_name': chosenName,
            }
          : null,
    );

    final user = response.user;
    if (user != null) {
      try {
        final displayName = chosenName ?? email.split('@').first;
        await _client.from('profiles').upsert({
          'id': user.id,
          'username': displayName,
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

  /// Updates the user's username in metadata/profiles and optionally changes password.
  Future<void> updateProfile({
    String? username,
    String? password,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');

    final trimmedUsername = username?.trim();
    final trimmedPassword = password?.trim();

    final hasUsername = trimmedUsername != null && trimmedUsername.isNotEmpty;
    final hasPassword = trimmedPassword != null && trimmedPassword.isNotEmpty;

    if (!hasUsername && !hasPassword) return;

    // 1. Update auth user attributes (metadata and/or password) in GoTrue
    await _client.auth.updateUser(
      UserAttributes(
        password: hasPassword ? trimmedPassword : null,
        data: hasUsername
            ? {
                'username': trimmedUsername,
                'full_name': trimmedUsername,
              }
            : null,
      ),
    );

    // 2. Synchronize username with public.profiles table
    if (hasUsername) {
      try {
        final res = await _client.from('profiles').update({
          'username': trimmedUsername,
          'full_name': trimmedUsername,
        }).eq('id', user.id).select();

        if (res.isEmpty) {
          await _client.from('profiles').insert({
            'id': user.id,
            'username': trimmedUsername,
            'full_name': trimmedUsername,
            'role': 'student',
          });
        }
      } catch (e) {
        // Fallback for setups where profiles table doesn't have a username column
        try {
          await _client.from('profiles').update({
            'full_name': trimmedUsername,
          }).eq('id', user.id);
        } catch (_) {}
      }
    }
  }
}
