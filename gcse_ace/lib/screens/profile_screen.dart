import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/attempt.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditAccountSheet(BuildContext context, WidgetRef ref, String currentUsername) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditAccountSheet(currentUsername: currentUsername),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final theme = Theme.of(context);

    if (user == null) {
      return const AppScaffold(
        appBar: GlassAppBar(title: Text('Profile')),
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Not signed in',
          subtitle: 'Sign in to see your stats and attempt history.',
          gradient: AppColors.sunset,
        ),
      );
    }

    final displayName = ref.watch(userDisplayNameProvider);
    final attemptsAsync = ref.watch(attemptsProvider(user.id));

    return AppScaffold(
      appBar: const GlassAppBar(title: Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _IdentityCard(
            displayName: displayName,
            email: user.email ?? '',
            onEdit: () => _showEditAccountSheet(context, ref, displayName),
          ),
          const SizedBox(height: 20),
          attemptsAsync.when(
            loading: () => const _StatsSkeleton(),
            error: (_, _) => const SizedBox.shrink(),
            data: (attempts) => _StatsSection(attempts: attempts),
          ),
          const SizedBox(height: 24),
          attemptsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (attempts) => _AttemptHistory(attempts: attempts),
          ),
          const SizedBox(height: 24),
          GlassCard(
            radius: 24,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.manage_accounts_rounded,
                  iconColor: AppColors.primary,
                  title: 'Edit account',
                  subtitle: 'Update your username or password',
                  onTap: () => _showEditAccountSheet(context, ref, displayName),
                ),
                const Divider(height: 1, indent: 68),
                _InfoTile(
                  icon: Icons.school_rounded,
                  iconColor: AppColors.primary,
                  title: 'Exam board ready',
                  subtitle: 'Questions are graded locally, instantly.',
                ),
                const Divider(height: 1, indent: 68),
                _InfoTile(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: AppColors.secondary,
                  title: 'AI explanations',
                  subtitle: 'Get any wrong answer broken down step by step.',
                ),
                const Divider(height: 1, indent: 68),
                _InfoTile(
                  icon: Icons.history_rounded,
                  iconColor: AppColors.accent,
                  title: 'Full history',
                  subtitle: 'Every attempt is saved to your account.',
                  onTap: () => context.push('/history'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              await AuthService.instance.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'GCSE Ace',
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.displayName,
    required this.email,
    required this.onEdit,
  });

  final String displayName;
  final String email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim().characters.first.toUpperCase()
        : (email.isNotEmpty ? email.characters.first.toUpperCase() : 'S');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.aurora,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (email.isNotEmpty && email != displayName) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'SIGNED IN',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Edit account',
            onPressed: onEdit,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.attempts});

  final List<Attempt> attempts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = attempts.where((a) => a.isCompleted).toList();
    final count = completed.length;
    final averagePercent = count == 0
        ? 0
        : (completed.fold<double>(0, (acc, a) => acc + a.percentage) / count).round();

    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMPLETED',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.secondary,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count == 1 ? 'attempt' : 'attempts',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AVERAGE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$averagePercent%',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count == 0 ? 'no attempts yet' : 'overall score',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AttemptHistory extends StatelessWidget {
  const _AttemptHistory({required this.attempts});

  final List<Attempt> attempts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recent = attempts.take(5).toList();

    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent attempts',
                style: theme.textTheme.titleMedium,
              ),
              if (attempts.length > 5)
                TextButton(
                  onPressed: () => context.push('/history'),
                  child: const Text('View all'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No attempts yet. Pick a paper to start.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            )
          else
            for (var i = 0; i < recent.length; i++) ...[
              if (i > 0) const Divider(height: 20),
              _AttemptTile(attempt: recent[i]),
            ],
        ],
      ),
    );
  }
}

class _AttemptTile extends StatelessWidget {
  const _AttemptTile({required this.attempt});

  final Attempt attempt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateFormat('d MMM yyyy').format(attempt.startedAt);

    return InkWell(
      onTap: () => context.push('/results/${attempt.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attempt.paperTitle ?? 'Practice paper',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    date,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _ScoreBadge(percent: attempt.percent),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;

    if (percent >= 70) {
      bg = const Color(0xFF10B981).withValues(alpha: 0.16);
      fg = const Color(0xFF10B981);
    } else if (percent >= 50) {
      bg = const Color(0xFFF59E0B).withValues(alpha: 0.16);
      fg = const Color(0xFFF59E0B);
    } else {
      bg = const Color(0xFFEF4444).withValues(alpha: 0.16);
      fg = const Color(0xFFEF4444);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$percent%',
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: GlassCard(padding: EdgeInsets.all(24), child: SizedBox(height: 60))),
        SizedBox(width: 14),
        Expanded(child: GlassCard(padding: EdgeInsets.all(24), child: SizedBox(height: 60))),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

class _EditAccountSheet extends ConsumerStatefulWidget {
  const _EditAccountSheet({required this.currentUsername});

  final String currentUsername;

  @override
  ConsumerState<_EditAccountSheet> createState() => _EditAccountSheetState();
}

class _EditAccountSheetState extends ConsumerState<_EditAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUsername);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final newUsername = _usernameController.text.trim();
    final newPassword = _passwordController.text.trim();

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.updateProfile(
        username: newUsername.isNotEmpty ? newUsername : null,
        password: newPassword.isNotEmpty ? newPassword : null,
      );

      // Immediately reflect the updated username in UI
      if (newUsername.isNotEmpty) {
        ref.read(userDisplayNameProvider.notifier).updateName(newUsername);
      }

      // Refresh database profile cache
      ref.invalidate(userProfileProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account details updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.manage_accounts_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Account',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Update your username or password',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Username field
                TextFormField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Enter a username';
                    if (v.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Password divider & header
                Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Change Password',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Leave password blank if you only want to change your username.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),

                // New Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'New Password (optional)',
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (_passwordController.text.isNotEmpty &&
                        value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                GradientButton(
                  onPressed: _isSaving ? null : _save,
                  icon: Icons.save_rounded,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
