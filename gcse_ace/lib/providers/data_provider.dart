import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attempt.dart';
import '../models/department.dart';
import '../models/material.dart';
import '../models/paper.dart';
import '../models/question.dart';
import '../models/option.dart';
import '../services/data_service.dart';

final departmentsProvider = FutureProvider<List<Department>>((ref) async {
  return DataService.instance.getDepartments();
});

final papersProvider =
    FutureProvider.family<List<Paper>, String?>((ref, departmentId) async {
  return DataService.instance.getPapers(departmentId: departmentId);
});

final questionsProvider =
    FutureProvider.family<List<Question>, String>((ref, paperId) async {
  return DataService.instance.getQuestions(paperId);
});

final optionsProvider =
    FutureProvider.family<List<Option>, String>((ref, questionId) async {
  return DataService.instance.getOptions(questionId);
});

final questionsWithOptionsProvider =
    FutureProvider.family<List<Question>, String>((ref, paperId) async {
  return DataService.instance.getQuestionsWithOptions(paperId);
});

final materialsProvider =
    FutureProvider.family<List<StudyMaterial>, String?>((ref, departmentId) async {
  return DataService.instance.getMaterials(departmentId: departmentId);
});

final attemptsProvider =
    FutureProvider.family<List<Attempt>, String>((ref, userId) async {
  return DataService.instance.getAttempts(userId);
});
