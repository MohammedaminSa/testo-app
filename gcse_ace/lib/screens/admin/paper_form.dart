import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/department.dart';
import '../../providers/data_provider.dart';
import '../../services/data_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/empty_state.dart';

class PaperFormScreen extends ConsumerStatefulWidget {
  final String? paperId;
  final bool isEditing;

  const PaperFormScreen({super.key, this.paperId, this.isEditing = false});

  @override
  ConsumerState<PaperFormScreen> createState() => _PaperFormScreenState();
}

class _PaperFormScreenState extends ConsumerState<PaperFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController();
  final _durationController = TextEditingController();
  final _marksController = TextEditingController();
  String? _selectedDepartmentId;
  String _selectedExamType = 'mock'; // 'mock' or 'exit_exam'
  bool _isLoading = false;
  List<Department> _departments = [];

  @override
  void initState() {
    super.initState();
    _yearController.addListener(_onYearChanged);
    _loadDepartments();
    if (widget.isEditing && widget.paperId != null) {
      _loadPaper();
    }
  }

  void _onYearChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _yearController.removeListener(_onYearChanged);
    _yearController.dispose();
    _durationController.dispose();
    _marksController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    final depts = await ref.read(departmentsProvider.future);
    if (mounted) {
      setState(() => _departments = depts);
    }
  }

  Future<void> _loadPaper() async {
    try {
      final paper = await ref.read(dataServiceProvider).getPaperById(widget.paperId!);
      if (mounted) {
        setState(() {
          _yearController.text = paper.year.toString();
          _durationController.text = paper.durationMinutes.toString();
          _marksController.text = paper.totalMarks.toString();
          _selectedDepartmentId = paper.departmentId;
          _selectedExamType = paper.examType;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading paper: $e')),
        );
      }
    }
  }

  String _computeTitle() {
    final examTypeLabel = _selectedExamType == 'exit_exam' ? 'Exit Exam' : 'Mock Exam';
    final deptName = _departments.where((d) => d.id == _selectedDepartmentId).firstOrNull?.name ?? 'Department';
    final year = _yearController.text.trim();
    if (year.isEmpty) {
      return '$deptName - $examTypeLabel';
    }
    return '$deptName - $examTypeLabel $year';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department')),
      );
      return;
    }
    final generatedTitle = _computeTitle();
    setState(() => _isLoading = true);
    try {
      if (widget.isEditing) {
        await ref.read(dataServiceProvider).updatePaper(widget.paperId!, {
          'department_id': _selectedDepartmentId,
          'exam_type': _selectedExamType,
          'title': generatedTitle,
          'year': int.parse(_yearController.text),
          'duration_minutes': int.parse(_durationController.text),
          'total_marks': int.parse(_marksController.text),
        });
      } else {
        await ref
            .read(dataServiceProvider)
            .createPaper(
              departmentId: _selectedDepartmentId!,
              examType: _selectedExamType,
              title: generatedTitle,
              year: int.parse(_yearController.text),
              durationMinutes: int.parse(_durationController.text),
              totalMarks: int.parse(_marksController.text),
            );
      }
      ref.invalidate(papersAllProvider);
      ref.invalidate(papersProvider(null));
      if (_selectedDepartmentId != null) {
        ref.invalidate(papersProvider(_selectedDepartmentId));
      }
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Paper updated' : 'Paper added'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit Paper' : 'Add Paper';
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
                      // Department Selector
                      DropdownButtonFormField<String>(
                        key: ValueKey('dept-$_selectedDepartmentId'),
                        initialValue: _selectedDepartmentId,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          prefixIcon: Icon(Icons.school_rounded),
                        ),
                        items: _departments.map((dept) {
                          return DropdownMenuItem(
                            value: dept.id,
                            child: Text(dept.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartmentId = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Select a department' : null,
                      ),
                      const SizedBox(height: 16),

                      // Exam Type Selector (Mock vs Exit Exam)
                      DropdownButtonFormField<String>(
                        key: ValueKey('exam-type-$_selectedExamType'),
                        initialValue: _selectedExamType,
                        decoration: const InputDecoration(
                          labelText: 'Exam Type',
                          prefixIcon: Icon(Icons.assignment_turned_in_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'mock',
                            child: Row(
                              children: [
                                Icon(Icons.quiz_outlined, size: 20, color: Colors.blueAccent),
                                SizedBox(width: 10),
                                Text('Mock Exam'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'exit_exam',
                            child: Row(
                              children: [
                                Icon(Icons.workspace_premium_rounded, size: 20, color: Colors.amber),
                                SizedBox(width: 10),
                                Text('Exit Exam'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedExamType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Year
                      TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          prefixIcon: Icon(Icons.calendar_today_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter year';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Enter a valid year';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Auto-generated Title Preview
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withAlpha(40),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'AUTO-GENERATED TITLE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _computeTitle(),
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Duration
                      TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration (minutes)',
                          prefixIcon: Icon(Icons.timer_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter duration';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Total Marks
                      TextFormField(
                        controller: _marksController,
                        decoration: const InputDecoration(
                          labelText: 'Total Marks',
                          prefixIcon: Icon(Icons.grade_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter total marks';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      GradientButton(
                        onPressed: _save,
                        icon: Icons.check_rounded,
                        child: Text(widget.isEditing ? 'Update Paper' : 'Create Paper'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
