import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'providers/message_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initSupabase();
  runApp(const ProviderScope(child: TestoApp()));
}

class TestoApp extends ConsumerWidget {
  const TestoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Testo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) =>
          MessageHost(child: child ?? const SizedBox.shrink()),
    );
  }
}

/// Displays every [messageControllerProvider] message as a snackbar, so
/// screens never scatter their own `ScaffoldMessenger` calls.
class MessageHost extends ConsumerStatefulWidget {
  const MessageHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MessageHost> createState() => _MessageHostState();
}

class _MessageHostState extends ConsumerState<MessageHost> {
  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(messageControllerProvider, (previous, next) {
      if (next == null || next == previous) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(next)));
      ref.read(messageControllerProvider.notifier).clear();
    });
    return widget.child;
  }
}