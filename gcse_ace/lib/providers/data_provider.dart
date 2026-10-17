import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attempt.dart';
import '../models/department.dart';
import '../models/material.dart';
import '../models/paper.dart';
import '../models/question.dart';
import '../models/option.dart';
import '../services/data_service.dart';

final dataServiceProvider = Provider<DataService>((ref) => DataService.instance);

final departmentsProvider = FutureProvider<List<Department>>((ref) async {
  return ref.read(dataServiceProvider).getDepartments();
});

final papersProvider =
    FutureProvider.family<List<Paper>, String?>((ref, departmentId) async {
  return ref.read(dataServiceProvider).getPapers(departmentId: departmentId);
});

final papersAllProvider = FutureProvider<List<Paper>>((ref) async {
  return ref.read(dataServiceProvider).getAllPapers();
});

final questionsProvider =
    FutureProvider.family<List<Question>, String>((ref, paperId) async {
  return ref.read(dataServiceProvider).getQuestions(paperId);
});

final optionsProvider =
    FutureProvider.family<List<Option>, String>((ref, questionId) async {
  return ref.read(dataServiceProvider).getOptions(questionId);
});

final questionsWithOptionsProvider =
    FutureProvider.family<List<Question>, String>((ref, paperId) async {
  return ref.read(dataServiceProvider).getQuestionsWithOptions(paperId);
});

final materialsProvider =
    FutureProvider.family<List<StudyMaterial>, String?>((ref, departmentId) async {
  return ref.read(dataServiceProvider).getMaterials(departmentId: departmentId);
});

final materialsAllProvider = FutureProvider<List<StudyMaterial>>((ref) async {
  return ref.read(dataServiceProvider).getAllMaterials();
});

final attemptsProvider =
    FutureProvider.family<List<Attempt>, String>((ref, userId) async {
  return ref.read(dataServiceProvider).getAttempts(userId);
});

// Admin action providers (returns a future that resolves when action completes)
final createDepartmentProvider =
    FutureProvider.family<Department, Map<String, dynamic>>((ref, data) async {
  return ref.read(dataServiceProvider).createDepartment(
    name: data['name'] as String,
    slug: data['slug'] as String,
    description: data['description'] as String?,
  );
});

final updateDepartmentProvider =
    FutureProvider.family<Department, Map<String, dynamic>>((ref, data) async {
  final id = data['id'] as String;
  final updates = Map<String, dynamic>.from(data);
  updates.remove('id');
  return ref.read(dataServiceProvider).updateDepartment(id, updates);
});

final deleteDepartmentProvider =
    FutureProvider.autoDispose.family<void, String>((ref, id) async {
  await ref.read(dataServiceProvider).deleteDepartment(id);
});

// Similar for papers
final createPaperProvider =
    FutureProvider.family<Paper, Map<String, dynamic>>((ref, data) async {
  return ref.read(dataServiceProvider).createPaper(
    departmentId: data['departmentId'] as String,
    title: data['title'] as String,
    year: data['year'] as int,
    durationMinutes: data['durationMinutes'] as int,
    totalMarks: data['totalMarks'] as int,
  );
});

final updatePaperProvider =
    FutureProvider.family<Paper, Map<String, dynamic>>((ref, data) async {
  final id = data['id'] as String;
  final updates = Map<String, dynamic>.from(data);
  updates.remove('id');
  return ref.read(dataServiceProvider).updatePaper(id, updates);
});

final deletePaperProvider =
    FutureProvider.autoDispose.family<void, String>((ref, id) async {
  await ref.read(dataServiceProvider).deletePaper(id);
});

// Question providers
final createQuestionProvider =
    FutureProvider.family<Question, Map<String, dynamic>>((ref, data) async {
  return ref.read(dataServiceProvider).createQuestion(
    paperId: data['paperId'] as String,
    text: data['text'] as String,
    orderNumber: data['orderNumber'] as int,
    marks: data['marks'] as int,
    questionType: data['questionType'] as String,
    correctAnswer: data['correctAnswer'] as String?,
    explanation: data['explanation'] as String?,
  );
});

final updateQuestionProvider =
    FutureProvider.family<Question, Map<String, dynamic>>((ref, data) async {
  final id = data['id'] as String;
  final updates = Map<String, dynamic>.from(data);
  updates.remove('id');
  return ref.read(dataServiceProvider).updateQuestion(id, updates);
});

final deleteQuestionProvider =
    FutureProvider.autoDispose.family<void, String>((ref, id) async {
  await ref.read(dataServiceProvider).deleteQuestion(id);
});

// Option providers
final createOptionProvider =
    FutureProvider.family<Option, Map<String, dynamic>>((ref, data) async {
  return ref.read(dataServiceProvider).createOption(
    questionId: data['questionId'] as String,
    letter: data['letter'] as String,
    text: data['text'] as String,
    isCorrect: data['isCorrect'] as bool? ?? false,
  );
});

final updateOptionProvider =
    FutureProvider.family<Option, Map<String, dynamic>>((ref, data) async {
  final id = data['id'] as String;
  final updates = Map<String, dynamic>.from(data);
  updates.remove('id');
  return ref.read(dataServiceProvider).updateOption(id, updates);
});

final deleteOptionProvider =
    FutureProvider.autoDispose.family<void, String>((ref, id) async {
  await ref.read(dataServiceProvider).deleteOption(id);
});

// Material providers
final createMaterialProvider =
    FutureProvider.family<StudyMaterial, Map<String, dynamic>>((ref, data) async {
  return ref.read(dataServiceProvider).createMaterial(
    departmentId: data['departmentId'] as String,
    title: data['title'] as String,
    content: data['content'] as String,
    url: data['url'] as String?,
  );
});

final updateMaterialProvider =
    FutureProvider.family<StudyMaterial, Map<String, dynamic>>((ref, data) async {
  final id = data['id'] as String;
  final updates = Map<String, dynamic>.from(data);
  updates.remove('id');
  return ref.read(dataServiceProvider).updateMaterial(id, updates);
});

final deleteMaterialProvider =
    FutureProvider.autoDispose.family<void, String>((ref, id) async {
  await ref.read(dataServiceProvider).deleteMaterial(id);
});
