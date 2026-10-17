import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attempt.dart';
import '../models/department.dart';
import '../models/material.dart';
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

  Future<List<Paper>> getAllPapers() async {
    final data = await _client.from('papers').select().order('year', ascending: false);
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

  Future<List<StudyMaterial>> getMaterials({String? departmentId}) async {
    var query = _client.from('materials').select();
    if (departmentId != null) {
      query = query.eq('department_id', departmentId);
    }
    final data = await query.order('created_at', ascending: false);
    return (data as List).map((json) => StudyMaterial.fromJson(json)).toList();
  }

  Future<List<StudyMaterial>> getAllMaterials() async {
    final data = await _client.from('materials').select().order('created_at', ascending: false);
    return (data as List).map((json) => StudyMaterial.fromJson(json)).toList();
  }

  Future<List<Attempt>> getAttempts(String userId) async {
    final data = await _client
        .from('attempts')
        .select('*, papers(title, departments(name))')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((json) => Attempt.fromJson(json)).toList();
  }

  // Department management (Admin)
  Future<Department> createDepartment({
    required String name,
    required String slug,
    String? description,
  }) async {
    final result = await _client
        .from('departments')
        .insert({
          'name': name,
          'slug': slug,
          'description': description,
        })
        .select()
        .single();
    return Department.fromJson(result);
  }

  Future<Department> updateDepartment(String id, Map<String, dynamic> updates) async {
    final result = await _client
        .from('departments')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return Department.fromJson(result);
  }

  Future<void> deleteDepartment(String id) async {
    await _client.from('departments').delete().eq('id', id);
  }

  // Paper management (Admin)
  Future<Paper> createPaper({
    required String departmentId,
    required String title,
    required int year,
    required int durationMinutes,
    required int totalMarks,
  }) async {
    final result = await _client
        .from('papers')
        .insert({
          'department_id': departmentId,
          'title': title,
          'year': year,
          'duration_minutes': durationMinutes,
          'total_marks': totalMarks,
        })
        .select()
        .single();
    return Paper.fromJson(result);
  }

  Future<Paper> updatePaper(String id, Map<String, dynamic> updates) async {
    final result = await _client
        .from('papers')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return Paper.fromJson(result);
  }

  Future<void> deletePaper(String id) async {
    await _client.from('papers').delete().eq('id', id);
  }

  // Question management (Admin)
  Future<Question> createQuestion({
    required String paperId,
    required String text,
    required int orderNumber,
    required int marks,
    required String questionType,
    String? correctAnswer,
    String? explanation,
  }) async {
    final result = await _client
        .from('questions')
        .insert({
          'paper_id': paperId,
          'text': text,
          'order_number': orderNumber,
          'marks': marks,
          'question_type': questionType,
          'correct_answer': correctAnswer,
          'explanation': explanation,
        })
        .select()
        .single();
    return Question.fromJson(result);
  }

  Future<Question> updateQuestion(String id, Map<String, dynamic> updates) async {
    final result = await _client
        .from('questions')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return Question.fromJson(result);
  }

  Future<void> deleteQuestion(String id) async {
    await _client.from('questions').delete().eq('id', id);
  }

  // Option management (Admin)
  Future<Option> createOption({
    required String questionId,
    required String letter,
    required String text,
    bool isCorrect = false,
  }) async {
    final result = await _client
        .from('options')
        .insert({
          'question_id': questionId,
          'letter': letter,
          'text': text,
          'is_correct': isCorrect,
        })
        .select()
        .single();
    return Option.fromJson(result);
  }

  Future<Option> updateOption(String id, Map<String, dynamic> updates) async {
    final result = await _client
        .from('options')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return Option.fromJson(result);
  }

  Future<void> deleteOption(String id) async {
    await _client.from('options').delete().eq('id', id);
  }

  // Study material management (Admin)
  Future<StudyMaterial> createMaterial({
    required String departmentId,
    required String title,
    required String content,
    String? url,
  }) async {
    final result = await _client
        .from('materials')
        .insert({
          'department_id': departmentId,
          'title': title,
          'content': content,
          'url': url,
        })
        .select()
        .single();
    return StudyMaterial.fromJson(result);
  }

  Future<StudyMaterial> updateMaterial(String id, Map<String, dynamic> updates) async {
    final result = await _client
        .from('materials')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return StudyMaterial.fromJson(result);
  }

  Future<void> deleteMaterial(String id) async {
    await _client.from('materials').delete().eq('id', id);
  }

  Future<String> saveAttempt({
    required String userId,
    required String paperId,
    required int score,
    required int totalMarks,
    required Map<String, String> answers,
  }) async {
    final result = await _client
        .from('attempts')
        .insert({
          'user_id': userId,
          'paper_id': paperId,
          'score': score,
          'total_marks': totalMarks,
          'answers': answers,
          'started_at': DateTime.now().toIso8601String(),
          'submitted_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return result['id'] as String;
  }
}
