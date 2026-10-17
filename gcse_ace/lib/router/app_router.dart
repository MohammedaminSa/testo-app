import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/admin/admin_home.dart';
import '../screens/admin/department_form.dart';
import '../screens/admin/department_management.dart';
import '../screens/admin/material_form.dart';
import '../screens/admin/material_management.dart';
import '../screens/admin/paper_form.dart';
import '../screens/admin/paper_management.dart';
import '../screens/admin/question_form.dart';
import '../screens/admin/question_management.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/department_papers_screen.dart';
import '../screens/exam_screen.dart';
import '../screens/history_screen.dart';
import '../screens/paper_detail_screen.dart';
import '../screens/review_screen.dart';
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
      GoRoute(
        path: '/review/:paperId',
        builder: (context, state) {
          final paperId = state.pathParameters['paperId']!;
          return ReviewScreen(paperId: paperId);
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      // Admin routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/admin/departments',
        builder: (context, state) => const DepartmentManagementScreen(),
      ),
      GoRoute(
        path: '/admin/departments/add',
        builder: (context, state) => const DepartmentFormScreen(isEditing: false),
      ),
      GoRoute(
        path: '/admin/departments/:id/edit',
        builder: (context, state) => const DepartmentFormScreen(isEditing: true),
      ),
      GoRoute(
        path: '/admin/papers',
        builder: (context, state) => const PaperManagementScreen(),
      ),
      GoRoute(
        path: '/admin/papers/add',
        builder: (context, state) => const PaperFormScreen(isEditing: false),
      ),
      GoRoute(
        path: '/admin/papers/:id/edit',
        builder: (context, state) => const PaperFormScreen(isEditing: true),
      ),
      GoRoute(
        path: '/admin/questions',
        builder: (context, state) => const QuestionManagementScreen(),
      ),
      GoRoute(
        path: '/admin/questions/add/:paperId',
        builder: (context, state) => QuestionFormScreen(
          isEditing: false,
          paperId: state.pathParameters['paperId']!,
        ),
      ),
      GoRoute(
        path: '/admin/questions/:id/edit',
        builder: (context, state) => QuestionFormScreen(
          isEditing: true,
          questionId: state.pathParameters['id'],
          paperId: '', // paperId needed but we can fetch from question; for simplicity we'll pass empty and load later
        ),
      ),
      GoRoute(
        path: '/admin/materials',
        builder: (context, state) => const MaterialManagementScreen(),
      ),
      GoRoute(
        path: '/admin/materials/add',
        builder: (context, state) => const MaterialFormScreen(isEditing: false),
      ),
      GoRoute(
        path: '/admin/materials/:id/edit',
        builder: (context, state) => const MaterialFormScreen(isEditing: true),
      ),
    ],
  );
});
