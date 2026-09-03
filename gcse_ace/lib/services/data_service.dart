import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/department.dart';
import '../models/paper.dart';
import '../models/question.dart';
import '../models/option.dart';

class DataService {
  DataService._();

  static final DataService instance = DataService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Department>> getDepartments() async {
    final data = await _client.from('departments').select();
    return (data as List).map((json) => Department.fromJson(json)).toList();
  }

  Future<List<Paper>> getPapers({String? departmentId}) async {
    var query = _client.from('papers').select();
    if (departmentId != null) {
      query = query.eq('department_id', departmentId);
    }
    final data = await query.order('year', ascending: false);
    return (data as List).map((json) => Paper.fromJson(json)).toList();
  }

  Future<List<Question>> getQuestions(String paperId) async {
    final data = await _client
        .from('questions')
        .select()
        .eq('paper_id', paperId)
        .order('order_number');
    return (data as List).map((json) => Question.fromJson(json)).toList();
  }

  Future<List<Option>> getOptions(String questionId) async {
    final data = await _client
        .from('options')
        .select()
        .eq('question_id', questionId)
        .order('letter');
    return (data as List).map((json) => Option.fromJson(json)).toList();
  }

  Future<Map<String, List<Option>>> getOptionsForQuestions(
    List<String> questionIds,
  ) async {
    final data = await _client
        .from('options')
        .select()
        .inFilter('question_id', questionIds)
        .order('letter');

    final map = <String, List<Option>>{};
    for (final json in data as List) {
      final option = Option.fromJson(json);
      map.putIfAbsent(option.questionId, () => []).add(option);
    }
    return map;
  }

  Future<List<Question>> getQuestionsWithOptions(String paperId) async {
    final questions = await getQuestions(paperId);
    final questionIds = questions.map((q) => q.id).toList();
    final optionsMap = await getOptionsForQuestions(questionIds);

    return questions.map((q) {
      return Question(
        id: q.id,
        paperId: q.paperId,
        orderNumber: q.orderNumber,
        text: q.text,
        marks: q.marks,
        questionType: q.questionType,
        correctAnswer: q.correctAnswer,
        explanation: q.explanation,
        options: optionsMap[q.id] ?? [],
      );
    }).toList();
  }
}
