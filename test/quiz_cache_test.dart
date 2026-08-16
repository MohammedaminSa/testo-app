import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testo/services/quiz_cache.dart';

import 'helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('QuizCache', () {
    test('saves and loads quizzes round-trip', () async {
      final cache = QuizCache();
      await cache.save([sampleQuiz()]);

      final loaded = await cache.load();
      expect(loaded, isNotNull);
      expect(loaded!.length, 1);
      expect(loaded.single.id, 'quiz-1');
      expect(loaded.single.title, 'Sample Quiz');
      expect(loaded.single.questions.single.text, 'What is 2 + 2?');
    });

    test('returns null when nothing is cached', () async {
      final loaded = await QuizCache().load();
      expect(loaded, isNull);
    });

    test('returns null on corrupted cache data', () async {
      SharedPreferences.setMockInitialValues({'cached_quizzes': 'not json'});
      final loaded = await QuizCache().load();
      expect(loaded, isNull);
    });

    test('overwrites the previous cache on save', () async {
      final cache = QuizCache();
      await cache.save([sampleQuiz(id: 'a')]);
      await cache.save([sampleQuiz(id: 'b')]);

      final loaded = await cache.load();
      expect(loaded!.single.id, 'b');
    });
  });
}