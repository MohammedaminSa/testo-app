import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/department.dart';
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
