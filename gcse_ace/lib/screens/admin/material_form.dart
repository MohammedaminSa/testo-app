import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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
  final _contentController = TextEditingController();
  String? _selectedDepartmentId;
  String? _selectedCourseId;
  String? _selectedCourseName;
  bool _isLoading = false;
  bool _loadingCourses = false;
  List<Department> _departments = [];
  List<Course> _courses = [];

  // PDF state
  Uint8List? _pdfBytes;
  String? _pdfFileName;
  int? _pdfFileSize;
  String? _existingPdfUrl;

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
    _contentController.dispose();
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

  Future<void> _loadMaterial() async {
    try {
      final material = await ref.read(dataServiceProvider).getMaterialById(widget.materialId!);
      if (mounted) {
        setState(() {
          _selectedDepartmentId = material.departmentId;
          _selectedCourseId = material.courseId;
          _selectedCourseName = material.courseName ?? material.title;
          _contentController.text = material.content;
          _existingPdfUrl = material.url;
        });
        await _loadCourses(material.departmentId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading material: $e')),
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
                hintText: 'e.g., Database Systems',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Course Code (optional)',
                hintText: 'e.g., CS301',
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

  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        if (file.bytes != null) {
          setState(() {
            _pdfBytes = file.bytes;
            _pdfFileName = file.name;
            _pdfFileSize = file.size;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not read the selected PDF bytes.')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error choosing PDF: $e')),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _computeTitle() {
    if (_selectedCourseName != null && _selectedCourseName!.trim().isNotEmpty) {
      return _selectedCourseName!.trim();
    }
    final dept = _departments.where((d) => d.id == _selectedDepartmentId).firstOrNull;
    if (dept != null) {
      return '${dept.name} Reading Material';
    }
    return 'Course Material';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department')),
      );
      return;
    }
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or add a course')),
      );
      return;
    }

    final hasNewPdf = _pdfBytes != null;
    final hasExistingPdf = _existingPdfUrl != null && _existingPdfUrl!.trim().isNotEmpty;

    if (!hasNewPdf && !hasExistingPdf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a PDF document from your computer.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? pdfUrl = _existingPdfUrl;

      if (hasNewPdf) {
        try {
          pdfUrl = await ref.read(dataServiceProvider).uploadMaterialPdf(
            fileName: _pdfFileName ?? 'document.pdf',
            bytes: _pdfBytes!,
          );
        } catch (storageError) {
          throw Exception(
            'Storage upload failed: $storageError. Make sure the "materials" bucket exists in Supabase Storage with public access enabled.',
          );
        }
      }

      final title = _computeTitle();
      final content = _contentController.text.trim().isNotEmpty
          ? _contentController.text.trim()
          : 'PDF lecture notes and reading material for $title.';

      if (widget.isEditing) {
        await ref.read(dataServiceProvider).updateMaterial(widget.materialId!, {
          'department_id': _selectedDepartmentId,
          'course_id': _selectedCourseId,
          'course_name': _selectedCourseName,
          'title': title,
          'content': content,
          'url': pdfUrl,
        });
      } else {
        await ref.read(dataServiceProvider).createMaterial(
          departmentId: _selectedDepartmentId!,
          courseId: _selectedCourseId,
          courseName: _selectedCourseName,
          title: title,
          content: content,
          url: pdfUrl,
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
              widget.isEditing ? 'Material updated' : 'Material added successfully',
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
            duration: const Duration(seconds: 5),
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
    final theme = Theme.of(context);

    return AppScaffold(
      appBar: GlassAppBar(title: Text(title)),
      body: _isLoading
          ? const LoadingState(label: 'Uploading and saving material...')
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

                      // Course / Module Selector (Replaces manual title)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey('course-$_selectedDepartmentId-$_selectedCourseId'),
                              initialValue: _selectedCourseId,
                              decoration: InputDecoration(
                                labelText: 'Course / Module (Sets Material Title)',
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
                                      final selected =
                                          _courses.where((c) => c.id == value).firstOrNull;
                                      setState(() {
                                        _selectedCourseId = value;
                                        _selectedCourseName = selected?.name;
                                      });
                                    },
                              validator: (value) =>
                                  value == null ? 'Select a course / module' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: IconButton.filledTonal(
                              tooltip: 'Add new course',
                              icon: const Icon(Icons.add_rounded),
                              onPressed:
                                  _selectedDepartmentId == null ? null : _promptAddCourse,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Auto-Assigned Title Preview
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.primary.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha(40),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'MATERIAL TITLE (AUTO-ASSIGNED)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
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
                      const SizedBox(height: 20),

                      // PDF File Upload from Computer
                      Text(
                        'PDF Document',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (_pdfBytes != null) ...[
                        // Selected new PDF card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withAlpha(20),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.redAccent.withAlpha(120),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withAlpha(40),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.picture_as_pdf_rounded,
                                      size: 32,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _pdfFileName ?? 'document.pdf',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (_pdfFileSize != null)
                                              Text(
                                                _formatFileSize(_pdfFileSize!),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withAlpha(30),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.check_circle_rounded,
                                                    size: 12,
                                                    color: Colors.green,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Ready to upload',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.green,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.refresh_rounded, size: 18),
                                    label: const Text('Change PDF'),
                                    onPressed: _pickPdfFile,
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    icon: const Icon(Icons.close_rounded,
                                        size: 18, color: Colors.redAccent),
                                    label: const Text(
                                      'Remove',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _pdfBytes = null;
                                        _pdfFileName = null;
                                        _pdfFileSize = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ] else if (_existingPdfUrl != null && _existingPdfUrl!.isNotEmpty) ...[
                        // Existing linked PDF card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withAlpha(30),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.picture_as_pdf_rounded,
                                  size: 28,
                                  color: Colors.redAccent,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Current PDF Document',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _existingPdfUrl!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.upload_file_rounded, size: 18),
                                label: const Text('Replace'),
                                onPressed: _pickPdfFile,
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Empty PDF Upload Area
                        InkWell(
                          onTap: _pickPdfFile,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withAlpha(15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.redAccent.withAlpha(80),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.file_upload_rounded,
                                    size: 32,
                                    color: Colors.redAccent,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Select PDF Document from Computer',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap here to browse your files (.pdf only)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Optional Notes / Description
                      TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: 'Study Guide Notes / Overview (optional)',
                          hintText: 'e.g., Chapter 1 to 4 lecture notes and review questions',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      GradientButton(
                        onPressed: _save,
                        icon: widget.isEditing
                            ? Icons.save_rounded
                            : Icons.cloud_upload_rounded,
                        child: Text(
                          widget.isEditing
                              ? 'Update Material'
                              : 'Upload PDF & Save Material',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
