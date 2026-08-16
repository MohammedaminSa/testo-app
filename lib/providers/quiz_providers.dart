import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../data/demo_quizzes.dart';
import '../models/models.dart';
import '../repositories/quiz_repository.dart';
import '../services/quiz_cache.dart';
import 'supabase_provider.dart';

final quizCacheProvider = Provider<QuizCache>((ref) => QuizCache());

final quizRepositoryProvider = Provider<QuizRepository>(
  (ref) => QuizRepository(ref.watch(supabaseProvider)),
);

/// Whether the app points at a real Supabase backend. Tests override this to
/// exercise the network/cache path instead of the demo fallback.
final backendConfiguredProvider =
    Provider<bool>((ref) => AppConfig.isConfigured);

/// Loads the quiz catalog. Shows the offline cache instantly when available
/// and refreshes in the background; falls back to the cache when offline and
/// rethrows only when there is nothing to show.
class QuizListNotifier extends AsyncNotifier<List<Quiz>> {
  @override
  Future<List<Quiz>> build() async {
    if (!ref.read(backendConfiguredProvider)) return DemoQuizzes.quizzes;
    final repo = ref.read(quizRepositoryProvider);

    final cached = await ref.read(quizCacheProvider).load();
    if (cached != null && cached.isNotEmpty) {
      // Return the cache now, then refresh from the network silently.
      Future(() => refresh());
      return cached;
    }
    return _fetch(repo);
  }

  Future<List<Quiz>> _fetch(QuizRepository repo) async {
    final quizzes = await repo.fetchQuizzes();
    await ref.read(quizCacheProvider).save(quizzes);
    return quizzes;
  }

  Future<void> refresh() async {
    if (!ref.read(backendConfiguredProvider)) return;
    try {
      final quizzes = await _fetch(ref.read(quizRepositoryProvider));
      state = AsyncData(quizzes);
    } catch (_) {
      // Keep the cached data when the network is unavailable.
    }
  }
}

final quizListProvider =
    AsyncNotifierProvider<QuizListNotifier, List<Quiz>>(QuizListNotifier.new);
