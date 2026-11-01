import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

/// The current logged-in user, or null when logged out.
///
/// This is the single source of truth for "who is logged in". It's a
/// [StreamProvider], so it rebuilds automatically whenever the underlying auth
/// stream fires (login, logout, token refresh) — nothing to refresh manually.
final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.instance.onAuthStateChange.map(
    (event) => event.session?.user,
  );
});

/// Whether the current user is an admin.
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return false;
  return await AuthService.instance.isCurrentUserAdmin();
});

/// Fetches the profile record for the logged-in user.
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(authStateProvider).value ?? Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  try {
    return await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
  } catch (_) {
    return null;
  }
});

class UserDisplayNameNotifier extends Notifier<String> {
  @override
  String build() {
    final user = ref.watch(authStateProvider).value ?? Supabase.instance.client.auth.currentUser;
    if (user == null) return 'Student';

    // 1. Check loaded profile row from public.profiles
    final profile = ref.watch(userProfileProvider).value;
    if (profile != null) {
      final username = (profile['username'] as String?)?.trim();
      if (username != null && username.isNotEmpty) return username;
      final fullName = (profile['full_name'] as String?)?.trim();
      if (fullName != null && fullName.isNotEmpty) return fullName;
    }

    // 2. Check auth user metadata
    final liveUser = Supabase.instance.client.auth.currentUser ?? user;
    final metadata = liveUser.userMetadata;
    if (metadata != null) {
      final username = (metadata['username'] as String?)?.trim();
      if (username != null && username.isNotEmpty) return username;
      final fullName = (metadata['full_name'] as String?)?.trim();
      if (fullName != null && fullName.isNotEmpty) return fullName;
    }

    // 3. Fallback to email prefix (before '@')
    final email = liveUser.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'Student';
  }

  void updateName(String newName) {
    if (newName.trim().isNotEmpty) {
      state = newName.trim();
    }
  }
}

/// Reactive display name for the user (username, full_name, email prefix, or 'Student').
final userDisplayNameProvider = NotifierProvider<UserDisplayNameNotifier, String>(
  UserDisplayNameNotifier.new,
);
