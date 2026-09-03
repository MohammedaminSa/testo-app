import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/department_papers_screen.dart';
import '../screens/exam_screen.dart';
import '../screens/paper_detail_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../services/auth_service.dart';
import '../shell/app_shell.dart';

/// The app's navigation graph, with an auth guard.
///
/// The `redirect` runs before every navigation. If there's no user it forces
/// the user to `/signin`; once they're logged in they can reach `/` (the
/// shell). We recreate the router whenever auth state changes, which re-runs
/// the redirect and bounces the user to the right place automatically.
final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = AuthService.instance.currentUser;
      final loggingIn =
          state.matchedLocation == '/signin' ||
          state.matchedLocation == '/signup';

      if (user == null && !loggingIn) return '/signin';
      if (user != null && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AppShell()),
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/department/:departmentId',
        builder: (context, state) {
          final departmentId = state.pathParameters['departmentId']!;
          final departments = ref.read(departmentsProvider).value ?? [];
          final department = departments.firstWhere(
            (d) => d.id == departmentId,
            orElse: () => throw Exception('Department not found'),
          );
          return DepartmentPapersScreen(department: department);
        },
      ),
      GoRoute(
        path: '/paper/:paperId',
        builder: (context, state) {
          final paperId = state.pathParameters['paperId']!;
          return PaperDetailScreen(paperId: paperId);
        },
      ),
      GoRoute(
        path: '/exam/:paperId',
        builder: (context, state) {
          final paperId = state.pathParameters['paperId']!;
          return ExamScreen(paperId: paperId);
        },
      ),
    ],
  );
});
