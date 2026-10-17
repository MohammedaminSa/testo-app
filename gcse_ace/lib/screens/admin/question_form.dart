import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/option.dart';
import '../../providers/data_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class QuestionFormScreen extends ConsumerStatefulWidget {
  const QuestionFormScreen({
    super.key,
    required this.isEditing,
    this.questionId,
    required this.paperId,
  });

  final bool isEditing;
  final String? questionId;
  final String paperId;

  @override
  ConsumerState<QuestionFormScreen> createState() => _QuestionFormScreenState();
}

class _QuestionFormScreenState extends ConsumerState<QuestionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _marksController = TextEditingController();
  final _typeController = TextEditingController();
  final _correctAnswerController = TextEditingController();
  final _explanationController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(4, (_) => TextEditingController());
  final List<bool> _isCorrect = List.filled(4, false);
  bool _isLoading = false;
  List<Option> _existingOptions = [];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.questionId != null) {
      _loadQuestion();
    }
  }

  Future<void> _loadQuestion() async {
    final question = await ref.read(dataServiceProvider).getQuestions(widget.questionId!).then(
          (list) => list.firstWhere((q) => q.id == widget.questionId, orElse: () => throw Exception('Not found')),
        );
    final options = await ref.read(dataServiceProvider).getOptions(widget.questionId!);
    if (mounted) {
      setState(() {
        _existingOptions = options;
        _textController.text = question.text;
        _marksController.text = question.marks.toString();
        _typeController.text = question.questionType;
        _explanationController.text = question.explanation ?? '';
        final correctOpt = options.isNotEmpty
            ? options.firstWhere((o) => o.isCorrect, orElse: () => options.first)
            : null;
        if (correctOpt != null) {
          _correctAnswerController.text = correctOpt.letter;
        }
        for (int i = 0; i < options.length && i < 4; i++) {
          _optionControllers[i].text = options[i].text;
          _isCorrect[i] = options[i].isCorrect;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      String? newQuestionId;
      if (widget.isEditing) {
        final updatedQ = await ref.read(dataServiceProvider).updateQuestion(
          widget.questionId!,
          {
            'text': _textController.text,
            'marks': int.parse(_marksController.text),
            'question_type': _typeController.text,
            'correct_answer': _correctAnswerController.text,
            'explanation': _explanationController.text.isEmpty ? null : _explanationController.text,
          },
        );
        newQuestionId = updatedQ.id;
        for (int i = 0; i < _optionControllers.length; i++) {
          final text = _optionControllers[i].text.trim();
          if (text.isNotEmpty) {
            final optionId = _existingOptions.length > i ? _existingOptions[i].id : null;
            if (optionId != null) {
              await ref.read(dataServiceProvider).updateOption(
                optionId,
                {
                  'text': text,
                  'is_correct': _isCorrect[i],
                },
              );
            } else {
              await ref.read(dataServiceProvider).createOption(
                questionId: newQuestionId,
                letter: String.fromCharCode(65 + i),
                text: text,
                isCorrect: _isCorrect[i],
              );
            }
          }
        }
      } else {
        final createdQ = await ref.read(dataServiceProvider).createQuestion(
          paperId: widget.paperId,
          text: _textController.text,
          orderNumber: 1,
          marks: int.parse(_marksController.text),
          questionType: _typeController.text,
          correctAnswer: _correctAnswerController.text,
          explanation: _explanationController.text.isEmpty ? null : _explanationController.text,
        );
        newQuestionId = createdQ.id;
        for (int i = 0; i < _optionControllers.length; i++) {
          final text = _optionControllers[i].text.trim();
          if (text.isNotEmpty) {
            await ref.read(dataServiceProvider).createOption(
              questionId: newQuestionId,
              letter: String.fromCharCode(65 + i),
              text: text,
              isCorrect: _isCorrect[i],
            );
          }
        }
      }
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing ? 'Question updated' : 'Question added',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit Question' : 'Add Question';
    return AppScaffold(
      appBar: GlassAppBar(title: Text(title)),
      body: _isLoading
          ? const LoadingState(label: 'Saving...')
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: GlassCard(
                padding: const EdgeInsets.all(24),
                radius: 20,
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          labelText: 'Question Text',
                          prefixIcon: Icon(Icons.question_answer_rounded),
                        ),
                        maxLines: 3,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Enter question' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _marksController,
                        decoration: const InputDecoration(
                          labelText: 'Marks',
                          prefixIcon: Icon(Icons.stars_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter marks';
                          if (int.tryParse(value) == null) return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _typeController,
                        decoration: const InputDecoration(
                          labelText: 'Question Type (e.g., Multiple Choice)',
                          prefixIcon: Icon(Icons.category_rounded),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Enter type' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _correctAnswerController,
                        decoration: const InputDecoration(
                          labelText: 'Correct Answer (Letter)',
                          prefixIcon: Icon(Icons.check_circle_rounded),
                          hintText: 'e.g., A, B, C, D',
                        ),
                        maxLength: 1,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Enter correct letter' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _explanationController,
                        decoration: const InputDecoration(
                          labelText: 'Explanation (optional)',
                          prefixIcon: Icon(Icons.description_rounded),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Options (A-D)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(4, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                child: Text('${String.fromCharCode(65 + index)})'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _optionControllers[index],
                                  decoration: const InputDecoration(
                                    labelText: 'Option text',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Checkbox(
                                value: _isCorrect[index],
                                onChanged: (value) => setState(() => _isCorrect[index] = value ?? false),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                      GradientButton(
                        onPressed: _save,
                        icon: widget.isEditing ? Icons.save_rounded : Icons.add_rounded,
                        child: Text(widget.isEditing ? 'Update' : 'Add'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}