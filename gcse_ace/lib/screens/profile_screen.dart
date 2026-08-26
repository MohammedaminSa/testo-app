import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Signed in as:', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            user?.email ?? 'Unknown',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 32),
          FilledButton.tonal(
            onPressed: () async {
              await AuthService.instance.signOut();
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
