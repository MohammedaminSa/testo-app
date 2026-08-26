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
