import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';
import 'supabase_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseProvider)),
);

/// The signed-in user, reactive to auth changes. Null while signed out.
final currentUserProvider = StreamProvider<User?>((ref) {
  return ref
      .watch(authRepositoryProvider)
      .onAuthStateChange
      .map((state) => state.session?.user);
});
