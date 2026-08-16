import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  final _nameController = TextEditingController();

  Profile? _profile;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final profile = await _profileService.fetchProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
        _nameController.text = profile.displayName;
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || name == _profile?.displayName) return;

    setState(() => _saving = true);
    try {
      await _profileService.updateDisplayName(name);
      if (mounted) {
        setState(() => _profile = Profile(
              id: _profile!.id,
              displayName: name,
              createdAt: _profile!.createdAt,
            ));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update name. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final emailConfirmed = user?.emailConfirmedAt != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 16),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    _initial(),
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
                    _profile?.displayName.isNotEmpty == true
                        ? _profile!.displayName
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
                          color: emailConfirmed
                              ? AppTheme.success
                              : Colors.orange,
                        ),
                        title: Text(
                          emailConfirmed
                              ? 'Email verified'
                              : 'Email not verified',
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
            ),
    );
  }

  String _initial() {
    final name = _profile?.displayName.trim() ?? '';
    if (name.isEmpty) {
      final email = supabase.auth.currentUser?.email ?? 'T';
      return email.isNotEmpty ? email[0].toUpperCase() : 'T';
    }
    return name[0].toUpperCase();
  }
}