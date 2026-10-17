import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/data_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class DepartmentFormScreen extends ConsumerStatefulWidget {
  const DepartmentFormScreen({
    super.key,
    required this.isEditing,
    this.departmentId,
  });

  final bool isEditing;
  final String? departmentId;

  @override
  ConsumerState<DepartmentFormScreen> createState() => _DepartmentFormScreenState();
}

class _DepartmentFormScreenState extends ConsumerState<DepartmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.departmentId != null) {
      _loadDepartment();
    }
  }

  Future<void> _loadDepartment() async {
    final dept = await ref.read(dataServiceProvider).getDepartments().then(
          (list) => list.firstWhere((d) => d.id == widget.departmentId, orElse: () => throw Exception('Not found')),
        );
    if (mounted) {
      _nameController.text = dept.name;
      _slugController.text = dept.slug;
      _descriptionController.text = dept.description ?? '';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (widget.isEditing) {
        await ref.read(dataServiceProvider).updateDepartment(
          widget.departmentId!,
          {
            'name': _nameController.text,
            'slug': _slugController.text,
            'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
          },
        );
      } else {
        await ref.read(dataServiceProvider).createDepartment(
          name: _nameController.text,
          slug: _slugController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        );
      }
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing ? 'Department updated' : 'Department added',
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
    final title = widget.isEditing ? 'Edit Department' : 'Add Department';
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
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _slugController,
                        decoration: const InputDecoration(
                          labelText: 'Slug (URL-friendly identifier)',
                          prefixIcon: Icon(Icons.text_fields_rounded),
                          hintText: 'e.g., maths, english-science',
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Enter slug' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          prefixIcon: Icon(Icons.description_rounded),
                        ),
                        maxLines: 4,
                      ),
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