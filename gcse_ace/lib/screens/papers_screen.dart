import 'package:flutter/material.dart';

class PapersScreen extends StatelessWidget {
  const PapersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Papers')),
      body: const Center(child: Text('Past papers coming soon')),
    );
  }
}
