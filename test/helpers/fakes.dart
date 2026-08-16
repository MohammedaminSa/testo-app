import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:testo/models/models.dart';
import 'package:testo/repositories/auth_repository.dart';
import 'package:testo/repositories/progress_repository.dart';
import 'package:testo/repositories/quiz_repository.dart';

/// Shared fakes so widget/unit tests never touch a real Supabase project.
/// They extend the concrete repositories (all constructible with a dummy
/// client) and override only the network-touching behavior.

SupabaseClient dummyClient() => SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
      // Disable the auto-refresh ticker so no timers stay pending in tests.
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

Question sampleQuestion({String id = 'q1'}) => Question(
      id: id,
      text: 'What is 2 + 2?',
      options: const ['3', '4', '5'],
      correctIndex: 1,
      explanation: 'Two plus two equals four.',
      topic: 'Math',
    );

Quiz sampleQuiz({String id = 'quiz-1', int questionCount = 1}) => Quiz(
      id: id,
      title: 'Sample Quiz',
      description: 'A quiz used in tests.',
      category: 'General',
      difficulty: 'Beginner',
      questions: [
        for (var i = 0; i < questionCount; i++)
          sampleQuestion(id: 'q$i'),
      ],
    );

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(dummyClient());

  int signInCalls = 0;
  int signUpCalls = 0;
  String? lastSignInEmail;
  Object? _signInError;
  AuthResponse? _signUpResponse;

  set signInError(Object? error) => _signInError = error;

  set signUpResponse(AuthResponse? response) => _signUpResponse = response;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    lastSignInEmail = email;
    if (_signInError != null) throw _signInError!;
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    signUpCalls++;
    return _signUpResponse ?? AuthResponse();
  }
}

class FakeQuizRepository extends QuizRepository {
  FakeQuizRepository({this.quizzes = const []}) : super(dummyClient());

  List<Quiz> quizzes;
  Object? _fetchError;

  set fetchError(Object? error) => _fetchError = error;

  @override
  Future<List<Quiz>> fetchQuizzes() async {
    if (_fetchError != null) throw _fetchError!;
    return quizzes;
  }
}

class FakeProgressRepository extends ProgressRepository {
  FakeProgressRepository({this.attempts = const []}) : super(dummyClient());

  List<QuizAttempt> attempts;
  final List<QuizAttempt> savedAttempts = [];
  Object? _fetchError;

  set fetchError(Object? error) => _fetchError = error;

  @override
  Future<void> saveAttempt(QuizAttempt attempt) async {
    savedAttempts.add(attempt);
  }

  @override
  Future<List<QuizAttempt>> fetchAttempts({int limit = 100}) async {
    if (_fetchError != null) throw _fetchError!;
    return attempts.take(limit).toList();
  }
}