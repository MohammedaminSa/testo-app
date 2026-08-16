import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initSupabase();
  runApp(const TestoApp());
}

class TestoApp extends StatelessWidget {
  const TestoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Testo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SessionGate(),
    );
  }
}

/// Picks the first screen based on the current auth session.
///
/// Reads the persisted session synchronously so the app never flashes the
/// sign-in screen for someone who is already logged in, and listens for auth
/// changes (sign in / out / session refresh) to swap screens accordingly.
class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  /// `null` while we are still checking the stored session.
  bool? _signedIn;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _signedIn = supabase.auth.currentSession != null;
    _authSub = supabase.auth.onAuthStateChange.listen((state) {
      if (!mounted) return;
      setState(() => _signedIn = state.session != null);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _signedIn;
    if (signedIn == null) return const SplashScreen();
    if (signedIn) return const HomeScreen();
    return const AuthScreen();
  }
}