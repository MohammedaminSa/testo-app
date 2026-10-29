import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/department.dart';
import '../models/material.dart';
import '../providers/data_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class MaterialsScreen extends ConsumerStatefulWidget {
  const MaterialsScreen({super.key});

  @override
  ConsumerState<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends ConsumerState<MaterialsScreen> {
  String? _openDepartmentId;

  @override
  Widget build(BuildContext context) {
    final departmentsAsync = ref.watch(departmentsProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      appBar: const GlassAppBar(title: Text('Study materials')),
      body: departmentsAsync.when(
        loading: () => const LoadingState(label: 'Loading materials...'),
        error: (_, _) => const EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Could not load materials',
          subtitle: 'Check your connection and try again.',
          gradient: AppColors.ember,
        ),
        data: (departments) {
          if (departments.isEmpty) {
            return const EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No subjects yet',
              subtitle: 'Reading notes appear here once subjects are added.',
              gradient: AppColors.sunset,
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Text(
                'Bite-sized reading notes, organised by subject.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < departments.length; i++) ...[
                _DepartmentSection(
                  department: departments[i],
                  accent: AppColors.accentFor(i),
                  expanded: _openDepartmentId == departments[i].id,
                  onToggle: () => setState(() {
                    _openDepartmentId = _openDepartmentId == departments[i].id
                        ? null
                        : departments[i].id;
                  }),
                ),
                const SizedBox(height: 14),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DepartmentSection extends StatelessWidget {
  const _DepartmentSection({
    required this.department,
    required this.accent,
    required this.expanded,
    required this.onToggle,
  });

  final Department department;
  final Gradient accent;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: EdgeInsets.zero,
      radius: 24,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GradientIcon(
                    icon: Icons.menu_book_rounded,
                    size: 46,
                    iconSize: 21,
                    gradient: accent,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          department.name,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          department.description ?? 'Reading notes',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(
                    children: [
                      const Divider(),
                      _MaterialsList(departmentId: department.id),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _MaterialsList extends ConsumerWidget {
  const _MaterialsList({required this.departmentId});

  final String departmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(materialsProvider(departmentId));
    final theme = Theme.of(context);

    return materialsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Could not load notes', style: theme.textTheme.bodyMedium),
      ),
      data: (materials) {
        if (materials.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Text(
              'No notes for this subject yet.',
              style: theme.textTheme.bodySmall,
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
          child: Column(
            children: [
              for (final material in materials)
                _MaterialTile(
                  material: material,
                  onTap: () => _showMaterialDetail(context, material),
                  onOpenUrl: material.url != null && material.url!.trim().isNotEmpty
                      ? () => _openExternalUrl(context, material.url!)
                      : null,
                ),
            ],
          ),
        );
      },
    );
  }

  void _showMaterialDetail(BuildContext context, StudyMaterial material) {
    final theme = Theme.of(context);
    final hasUrl = material.url != null && material.url!.trim().isNotEmpty;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'READING NOTE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                        ),
                      ),
                      if (hasUrl) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.link_rounded, size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Has Link',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(material.title, style: theme.textTheme.headlineSmall),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.content,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                    ),
                    if (hasUrl) ...[
                      const SizedBox(height: 24),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        radius: 18,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.open_in_new_rounded,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'External Resource',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    material.url!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (hasUrl)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: GradientButton(
                    onPressed: () => _openExternalUrl(context, material.url!),
                    icon: Icons.open_in_browser_rounded,
                    child: const Text('Open external resource'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openExternalUrl(BuildContext context, String rawUrl) async {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return;

  final uri = Uri.tryParse(
    trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : 'https://$trimmed',
  );

  if (uri == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid resource link')),
      );
    }
    return;
  }

  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link in browser')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening link: $e')),
      );
    }
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({
    required this.material,
    required this.onTap,
    this.onOpenUrl,
  });

  final StudyMaterial material;
  final VoidCallback onTap;
  final VoidCallback? onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUrl = material.url != null && material.url!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  hasUrl ? Icons.link_rounded : Icons.article_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      material.content.isNotEmpty
                          ? material.content
                          : (material.url ?? ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (hasUrl && onOpenUrl != null)
                IconButton(
                  tooltip: 'Open link',
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  onPressed: onOpenUrl,
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
