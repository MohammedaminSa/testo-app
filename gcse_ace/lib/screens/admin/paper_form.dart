import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/course.dart';
import '../../models/department.dart';
import '../../providers/data_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class PaperFormScreen extends ConsumerStatefulWidget {
  const PaperFormScreen({super.key, required this.isEditing, this.paperId});

  final bool isEditing;
  final String? paperId;

  @override
  ConsumerState<PaperFormScreen> createState() => _PaperFormScreenState();
}

class _PaperFormScreenState extends ConsumerState<PaperFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController();
  final _durationController = TextEditingController();
  final _marksController = TextEditingController();
  String? _selectedDepartmentId;
  String? _selectedCourseId;
  String? _selectedCourseName;
  String _selectedExamType = 'mock'; // 'mock' or 'exit_exam'
  bool _isLoading = false;
  List<Department> _departments = [];
  List<Course> _courses = [];
  bool _loadingCourses = false;

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

  Future<void> _loadCourses(String departmentId) async {
    setState(() => _loadingCourses = true);
    try {
      final courses = await ref.read(dataServiceProvider).getCourses(departmentId: departmentId);
      if (mounted) {
        setState(() {
          _courses = courses;
          _loadingCourses = false;
          // If current selected course is not in this department, clear selection
          if (_selectedCourseId != null && !courses.any((c) => c.id == _selectedCourseId)) {
            _selectedCourseId = null;
            _selectedCourseName = null;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingCourses = false);
      }
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
          _selectedCourseId = paper.courseId;
          _selectedCourseName = paper.courseName;
          _selectedExamType = paper.examType;
        });
        await _loadCourses(paper.departmentId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading paper: $e')),
        );
      }
    }
  }

  Future<void> _promptAddCourse() async {
    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department first.')),
      );
      return;
    }

    final nameController = TextEditingController();
    final codeController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Course Name',
                hintText: 'e.g., Data Structures & Algorithms',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Course Code (optional)',
                hintText: 'e.g., CS201',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add Course'),
          ),
        ],
      ),
    );

    if (created == true && nameController.text.trim().isNotEmpty) {
      try {
        final newCourse = await ref.read(dataServiceProvider).createCourse(
          departmentId: _selectedDepartmentId!,
          name: nameController.text.trim(),
          code: codeController.text.trim().isEmpty ? null : codeController.text.trim(),
        );
        ref.invalidate(coursesProvider(_selectedDepartmentId));
        ref.invalidate(coursesAllProvider);
        if (mounted) {
          setState(() {
            _courses = [..._courses, newCourse];
            _selectedCourseId = newCourse.id;
            _selectedCourseName = newCourse.name;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add course: $e')),
          );
        }
      }
    }
  }

  String _computeTitle() {
    final examTypeLabel = _selectedExamType == 'exit_exam' ? 'Exit Exam' : 'Mock Exam';
    final subject = (_selectedCourseName != null && _selectedCourseName!.trim().isNotEmpty)
        ? _selectedCourseName!.trim()
        : (_departments.where((d) => d.id == _selectedDepartmentId).firstOrNull?.name ?? 'General');
    final year = _yearController.text.trim();
    if (year.isEmpty) {
      return '$subject - $examTypeLabel';
    }
    return '$subject - $examTypeLabel $year';
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
          'course_id': _selectedCourseId,
          'course_name': _selectedCourseName,
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
              courseId: _selectedCourseId,
              courseName: _selectedCourseName,
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
                          labelText: 'Department / Subject Area',
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
                          if (value != null) {
                            _loadCourses(value);
                          }
                        },
                        validator: (value) =>
                            value == null ? 'Select a department' : null,
                      ),
                      const SizedBox(height: 16),

                      // Course Selector
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey('course-$_selectedDepartmentId-$_selectedCourseId'),
                              initialValue: _selectedCourseId,
                              decoration: InputDecoration(
                                labelText: 'Course / Module',
                                prefixIcon: const Icon(Icons.menu_book_rounded),
                                helperText: _selectedDepartmentId == null
                                    ? 'Select department first'
                                    : (_courses.isEmpty && !_loadingCourses
                                        ? 'No courses yet (add one with +)'
                                        : null),
                              ),
                              items: _courses.map((course) {
                                final label = course.code != null && course.code!.isNotEmpty
                                    ? '${course.name} (${course.code})'
                                    : course.name;
                                return DropdownMenuItem(
                                  value: course.id,
                                  child: Text(
                                    label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: _selectedDepartmentId == null
                                  ? null
                                  : (value) {
                                      final selected = _courses.where((c) => c.id == value).firstOrNull;
                                      setState(() {
                                        _selectedCourseId = value;
                                        _selectedCourseName = selected?.name;
                                      });
                                    },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: IconButton.filledTonal(
                              tooltip: 'Add new course',
                              icon: const Icon(Icons.add_rounded),
                              onPressed: _selectedDepartmentId == null ? null : _promptAddCourse,
                            ),
                          ),
                        ],
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
                                      letterSpacing: 0.8,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _computeTitle(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
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
                          prefixIcon: Icon(Icons.stars_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter marks';
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
                        icon: widget.isEditing
                            ? Icons.save_rounded
                            : Icons.add_rounded,
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

