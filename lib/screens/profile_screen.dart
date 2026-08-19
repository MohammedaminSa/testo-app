import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../providers/auth_providers.dart';
import '../providers/message_controller.dart';
import '../providers/profile_providers.dart';

const _legalBase = 'https://github.com/MohammedaminSa/testo-app/blob/main/';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateDisplayName(name);
      ref.invalidate(profileProvider);
      ref.read(messageControllerProvider.notifier).show('Name updated');
    } catch (_) {
      ref
          .read(messageControllerProvider.notifier)
          .show('Could not update name. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }

  Future<void> _openLegal(String fileName) async {
    final uri = Uri.parse('$_legalBase$fileName');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      ref
          .read(messageControllerProvider.notifier)
          .show('Could not open the link.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final user = ref.watch(currentUserProvider).value ??
        ref.read(authRepositoryProvider).currentUser;

    // Sync the text field whenever the profile loads or changes.
    ref.listen<AsyncValue<Profile>>(profileProvider, (previous, next) {
      final nextName = next.value?.displayName;
      if (nextName != null &&
          (previous?.value?.displayName ?? '') != nextName) {
        _nameController.text = nextName;
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _buildLoadError(user),
        data: (profile) => _buildBody(context, profile, user),
      ),
    );
  }

  Widget _buildLoadError(User? user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.black26),
          const SizedBox(height: 12),
          const Text(
            'Could not load your profile.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(profileProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, Profile profile, User? user) {
    final emailConfirmed = user?.emailConfirmedAt != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        CircleAvatar(
          radius: 40,
          backgroundColor: AppTheme.primary,
          child: Text(
            _initial(profile, user),
            style: const TextStyle(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            profile.displayName.isNotEmpty
                ? profile.displayName
                : user?.email ?? 'Testo user',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Account',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(user?.email ?? ''),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  emailConfirmed
                      ? Icons.verified_user_outlined
                      : Icons.mark_email_unread_outlined,
                  color: emailConfirmed ? AppTheme.success : Colors.orange,
                ),
                title: Text(
                  emailConfirmed ? 'Email verified' : 'Email not verified',
                ),
                subtitle: emailConfirmed
                    ? null
                    : const Text('Check your inbox for a confirmation link.'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Display name',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _saving ? null : _saveName,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save name'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Legal',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openLegal('PRIVACY_POLICY.md'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openLegal('TERMS_OF_SERVICE.md'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            foregroundColor: AppTheme.error,
          ),
        ),
      ],
    );
  }

  String _initial(Profile profile, User? user) {
    final name = profile.displayName.trim();
    if (name.isNotEmpty) return name[0].toUpperCase();
    final email = user?.email ?? '';
    return email.isNotEmpty ? email[0].toUpperCase() : 'T';
  }
}