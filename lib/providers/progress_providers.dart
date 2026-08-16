import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../repositories/progress_repository.dart';
import 'supabase_provider.dart';

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(supabaseProvider)),
);

final attemptsProvider = FutureProvider<List<QuizAttempt>>((ref) {
  return ref.watch(progressRepositoryProvider).fetchAttempts();
});

/// Aggregated stats derived from attempts. Falls back to zeroed stats when
/// the history can't be loaded (e.g. offline), so the home screen never
/// hard-fails just to show a progress card.
final statsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final attempts = await ref.watch(attemptsProvider.future);
    return ProgressRepository.computeStats(attempts);
  } catch (_) {
    return ProgressRepository.computeStats(const []);
  }
});
