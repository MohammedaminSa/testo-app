import 'package:flutter/material.dart';

import 'shell/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const GcseAceApp());
}

class GcseAceApp extends StatelessWidget {
  const GcseAceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GCSE Ace',
      theme: AppTheme.light,
      home: const AppShell(),
    );
  }
}
