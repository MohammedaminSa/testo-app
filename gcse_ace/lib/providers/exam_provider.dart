import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/question.dart';
import '../models/option.dart';

class ExamState {
  final String paperId;
  final List<Question> questions;
  final Map<String, String> answers;
  final int currentIndex;
  final int remainingSeconds;
  final bool isSubmitted;

  const ExamState({
    required this.paperId,
    required this.questions,
    this.answers = const {},
    this.currentIndex = 0,
    required this.remainingSeconds,
    this.isSubmitted = false,
  });

  Question get currentQuestion => questions[currentIndex];

  bool get isLastQuestion => currentIndex == questions.length - 1;

  bool get isFirstQuestion => currentIndex == 0;

  int get answeredCount => answers.length;

  int get totalQuestions => questions.length;

  ExamState copyWith({
    Map<String, String>? answers,
    int? currentIndex,
    int? remainingSeconds,
    bool? isSubmitted,
  }) {
    return ExamState(
      paperId: paperId,
      questions: questions,
      answers: answers ?? this.answers,
      currentIndex: currentIndex ?? this.currentIndex,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }

  int calculateScore() {
    int score = 0;
    for (final question in questions) {
      final selectedOptionId = answers[question.id];
      if (selectedOptionId != null && question.options != null) {
        final selectedOption = question.options!.firstWhere(
          (o) => o.id == selectedOptionId,
          orElse: () => Option(
            id: '',
            questionId: question.id,
            letter: '',
            text: '',
            isCorrect: false,
          ),
        );
        if (selectedOption.isCorrect) {
          score += question.marks;
        }
      }
    }
    return score;
  }
}

class ExamController extends Notifier<ExamState> {
  Timer? _timer;

  @override
  ExamState build() {
    return ExamState(
      paperId: '',
      questions: [],
      remainingSeconds: 0,
    );
  }

  void configure({
    required String paperId,
    required List<Question> questions,
    required int durationMinutes,
  }) {
    _timer?.cancel();
    state = ExamState(
      paperId: paperId,
      questions: questions,
      remainingSeconds: durationMinutes * 60,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds <= 0 || state.isSubmitted) {
        timer.cancel();
        if (!state.isSubmitted) {
          submit();
        }
        return;
      }
      state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
    });
  }

  void selectAnswer(String questionId, String optionId) {
    if (state.isSubmitted) return;
    final newAnswers = Map<String, String>.from(state.answers);
    newAnswers[questionId] = optionId;
    state = state.copyWith(answers: newAnswers);
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < state.questions.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  void nextQuestion() {
    if (!state.isLastQuestion) {
      goToQuestion(state.currentIndex + 1);
    }
  }

  void previousQuestion() {
    if (!state.isFirstQuestion) {
      goToQuestion(state.currentIndex - 1);
    }
  }

  void submit() {
    _timer?.cancel();
    state = state.copyWith(isSubmitted: true);
  }

  void dispose() {
    _timer?.cancel();
  }
}

final examProvider = NotifierProvider<ExamController, ExamState>(
  ExamController.new,
);
