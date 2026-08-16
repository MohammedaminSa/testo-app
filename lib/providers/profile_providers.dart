import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../repositories/profile_repository.dart';
import 'supabase_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseProvider)),
);

final profileProvider = FutureProvider<Profile>((ref) {
  return ref.watch(profileRepositoryProvider).fetchProfile();
});