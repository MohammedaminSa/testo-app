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

class MaterialFormScreen extends ConsumerStatefulWidget {
  const MaterialFormScreen({
    super.key,
    required this.isEditing,
    this.materialId,
  });

  final bool isEditing;
  final String? materialId;

  @override
  ConsumerState<MaterialFormScreen> createState() => _MaterialFormScreenState();
}

class _MaterialFormScreenState extends ConsumerState<MaterialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _urlController = TextEditingController();
  String? _selectedDepartmentId;
  bool _isLoading = false;
  List<Department> _departments = [];

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    if (widget.isEditing && widget.materialId != null) {
      _loadMaterial();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    final depts = await ref.read(departmentsProvider.future);
    if (mounted) {
      setState(() => _departments = depts);
    }
  }

  Future<void> _loadMaterial() async {
    try {
      final material = await ref.read(dataServiceProvider).getMaterialById(widget.materialId!);
      if (mounted) {
        setState(() {
          _titleController.text = material.title;
          _contentController.text = material.content;
          _urlController.text = material.url ?? '';
          _selectedDepartmentId = material.departmentId;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading material: $e')),
        );
      }
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
        await ref.read(dataServiceProvider).updateMaterial(widget.materialId!, {
          'department_id': _selectedDepartmentId,
          'title': _titleController.text,
          'content': _contentController.text,
          'url': _urlController.text.isEmpty ? null : _urlController.text,
        });
      } else {
        await ref
            .read(dataServiceProvider)
            .createMaterial(
              departmentId: _selectedDepartmentId!,
              title: _titleController.text,
              content: _contentController.text,
              url: _urlController.text.isEmpty ? null : _urlController.text,
            );
      }
      ref.invalidate(materialsAllProvider);
      ref.invalidate(materialsProvider(null));
      if (_selectedDepartmentId != null) {
        ref.invalidate(materialsProvider(_selectedDepartmentId));
      }
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing ? 'Material updated' : 'Material added',
            ),
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
    final title = widget.isEditing ? 'Edit Material' : 'Add Material';
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
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: 'Content',
                          prefixIcon: Icon(Icons.description_rounded),
                        ),
                        maxLines: 6,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter content'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'URL (optional)',
                          prefixIcon: Icon(Icons.link_rounded),
                        ),
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
