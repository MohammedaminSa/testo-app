import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/course.dart';
import '../../providers/data_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class CourseManagementScreen extends ConsumerStatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  ConsumerState<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends ConsumerState<CourseManagementScreen> {
  String? _filterDepartmentId;

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(departmentsProvider);
    final coursesAsync = ref.watch(coursesAllProvider);

    return AppScaffold(
      appBar: GlassAppBar(
        title: const Text('Courses'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GradientButton(
              onPressed: () => _promptCourseDialog(context),
              expanded: false,
              icon: Icons.add_rounded,
              child: const Text('Add'),
            ),
          ),
        ],
      ),
      body: departmentsAsync.when(
        loading: () => const LoadingState(label: 'Loading...'),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (departments) {
          final deptMap = {for (var d in departments) d.id: d.name};

          return coursesAsync.when(
            loading: () => const LoadingState(label: 'Loading courses...'),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (courses) {
              final displayedCourses = _filterDepartmentId == null
                  ? courses
                  : courses.where((c) => c.departmentId == _filterDepartmentId).toList();

              return Column(
                children: [
                  if (departments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        radius: 16,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _filterDepartmentId,
                            isExpanded: true,
                            hint: const Text('All Departments'),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All Departments'),
                              ),
                              ...departments.map((d) => DropdownMenuItem<String?>(
                                    value: d.id,
                                    child: Text(d.name),
                                  )),
                            ],
                            onChanged: (val) => setState(() => _filterDepartmentId = val),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: displayedCourses.isEmpty
                        ? const Center(
                            child: Text('No courses found. Tap Add to create one.'),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                            itemCount: displayedCourses.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final course = displayedCourses[index];
                              final deptName = deptMap[course.departmentId] ?? 'Unknown Dept';

                              return GlassCard(
                                padding: const EdgeInsets.all(16),
                                radius: 16,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  course.name,
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (course.code != null && course.code!.isNotEmpty) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blueAccent.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    course.code!,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.blueAccent,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            deptName,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          if (course.description != null && course.description!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              course.description!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
                                      onPressed: () => _promptCourseDialog(context, course: course),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                                      onPressed: () => _confirmDelete(context, course.id, course.departmentId),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _promptCourseDialog(BuildContext context, {Course? course}) async {
    final depts = await ref.read(departmentsProvider.future);
    if (!context.mounted) return;
    if (depts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one department first.')),
      );
      return;
    }

    String selectedDeptId = course?.departmentId ?? _filterDepartmentId ?? depts.first.id;
    final nameController = TextEditingController(text: course?.name ?? '');
    final codeController = TextEditingController(text: course?.code ?? '');
    final descController = TextEditingController(text: course?.description ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(course == null ? 'Add Course' : 'Edit Course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedDeptId,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: depts
                      .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedDeptId = val);
                  },
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(course == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && nameController.text.trim().isNotEmpty) {
      try {
        if (course == null) {
          await ref.read(dataServiceProvider).createCourse(
            departmentId: selectedDeptId,
            name: nameController.text.trim(),
            code: codeController.text.trim().isEmpty ? null : codeController.text.trim(),
            description: descController.text.trim().isEmpty ? null : descController.text.trim(),
          );
        } else {
          await ref.read(dataServiceProvider).updateCourse(course.id, {
            'department_id': selectedDeptId,
            'name': nameController.text.trim(),
            'code': codeController.text.trim().isEmpty ? null : codeController.text.trim(),
            'description': descController.text.trim().isEmpty ? null : descController.text.trim(),
          });
        }
        ref.invalidate(coursesAllProvider);
        ref.invalidate(coursesProvider(selectedDeptId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(course == null ? 'Course added' : 'Course updated')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  void _confirmDelete(BuildContext context, String courseId, String departmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: const Text('Are you sure you want to delete this course?'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(dataServiceProvider).deleteCourse(courseId);
              ref.invalidate(coursesAllProvider);
              ref.invalidate(coursesProvider(departmentId));
              if (context.mounted) context.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

