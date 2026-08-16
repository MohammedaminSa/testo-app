import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testo/data/demo_quizzes.dart';
import 'package:testo/providers/quiz_providers.dart';
import 'package:testo/services/quiz_cache.dart';

import 'helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('QuizListNotifier', () {
    test('returns demo quizzes when Supabase is not configured', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final quizzes = await container.read(quizListProvider.future);
      expect(quizzes, DemoQuizzes.quizzes);
    });

    test('fetches from the repository and populates the cache', () async {
      final repo = FakeQuizRepository(quizzes: [sampleQuiz()]);
      final cache = QuizCache();
      final container = ProviderContainer(
        overrides: [
          backendConfiguredProvider.overrideWithValue(true),
          quizRepositoryProvider.overrideWithValue(repo),
          quizCacheProvider.overrideWithValue(cache),
        ],
      );
      addTearDown(container.dispose);

      final quizzes = await container.read(quizListProvider.future);
      expect(quizzes.single.id, 'quiz-1');

      final cached = await cache.load();
      expect(cached!.single.id, 'quiz-1');
    });

    test('serves the offline cache when the network fails', () async {
      final cache = QuizCache();
      await cache.save([sampleQuiz()]);

      final repo = FakeQuizRepository()..fetchError = Exception('offline');
      final container = ProviderContainer(
        overrides: [
          backendConfiguredProvider.overrideWithValue(true),
          quizRepositoryProvider.overrideWithValue(repo),
          quizCacheProvider.overrideWithValue(cache),
        ],
      );
      addTearDown(container.dispose);

      final quizzes = await container.read(quizListProvider.future);
      expect(quizzes.single.id, 'quiz-1');

      // Let the silently-scheduled background refresh settle before disposal.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
    });
  });
}