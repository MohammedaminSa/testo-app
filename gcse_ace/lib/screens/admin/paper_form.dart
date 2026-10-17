import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  final _titleController = TextEditingController();
  final _yearController = TextEditingController();
  final _durationController = TextEditingController();
  final _marksController = TextEditingController();
  String? _selectedDepartmentId;
  bool _isLoading = false;
  List<Department> _departments = [];

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    if (widget.isEditing && widget.paperId != null) {
      _loadPaper();
    }
  }

  Future<void> _loadDepartments() async {
    final depts = await ref.read(departmentsProvider.future);
    if (mounted) {
      setState(() => _departments = depts);
    }
  }

  Future<void> _loadPaper() async {
    final paper = await ref
        .read(dataServiceProvider)
        .getAllPapers()
        .then(
          (list) => list.firstWhere(
            (p) => p.id == widget.paperId,
            orElse: () => throw Exception('Not found'),
          ),
        );
    if (mounted) {
      _titleController.text = paper.title;
      _yearController.text = paper.year.toString();
      _durationController.text = paper.durationMinutes.toString();
      _marksController.text = paper.totalMarks.toString();
      _selectedDepartmentId = paper.departmentId;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (widget.isEditing) {
        await ref.read(dataServiceProvider).updatePaper(widget.paperId!, {
          'department_id': _selectedDepartmentId,
          'title': _titleController.text,
          'year': int.parse(_yearController.text),
          'duration_minutes': int.parse(_durationController.text),
          'total_marks': int.parse(_marksController.text),
        });
      } else {
        await ref
            .read(dataServiceProvider)
            .createPaper(
              departmentId: _selectedDepartmentId!,
              title: _titleController.text,
              year: int.parse(_yearController.text),
              durationMinutes: int.parse(_durationController.text),
              totalMarks: int.parse(_marksController.text),
            );
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
                      DropdownButtonFormField<String>(
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
                        onChanged: (value) =>
                            setState(() => _selectedDepartmentId = value),
                        validator: (value) =>
                            value == null ? 'Select a department' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter title'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          prefixIcon: Icon(Icons.calendar_today_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Enter year';
                          if (int.tryParse(value) == null)
                            return 'Enter a valid year';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration (minutes)',
                          prefixIcon: Icon(Icons.timer_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Enter duration';
                          if (int.tryParse(value) == null)
                            return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _marksController,
                        decoration: const InputDecoration(
                          labelText: 'Total Marks',
                          prefixIcon: Icon(Icons.stars_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Enter marks';
                          if (int.tryParse(value) == null)
                            return 'Enter a valid number';
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
