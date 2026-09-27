import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/course_input/presentation/screens/course_input_screen.dart';
import '../../features/pdf_upload/presentation/screens/pdf_upload_screen.dart';
import '../../features/summary/presentation/screens/summary_screen.dart';
import '../../features/quiz/presentation/screens/quiz_screen.dart';
import '../../features/quiz/presentation/screens/quiz_result_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/exam_generator/presentation/screens/exam_generator_screen.dart';
import '../../features/exam_generator/presentation/screens/exam_details_screen.dart';
import '../../features/mindmap/presentation/screens/mindmap_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/saved/presentation/screens/saved_summaries_screen.dart';
import '../../features/splash/splash_screen.dart';

/// Provider gérant la navigation et les routes de l'application
final appRouterProvider = Provider<GoRouter>((ref) {
  // Écoute l'état de l'authentification pour rediriger l'utilisateur
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/splash', // Page de démarrage
    redirect: (context, state) {
      final isLoggedIn = authState.hasValue && authState.value != null;
      final isLoggingIn = state.uri.path == '/login' || state.uri.path == '/register';
      final isSplash = state.uri.path == '/splash';
      
      // Permet d'afficher l'écran de splash au début
      if (isSplash) {
        return null;
      }
      
      // Redirige vers la connexion si l'utilisateur n'est pas authentifié
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      
      // Redirige vers le tableau de bord si l'utilisateur est déjà connecté
      if (isLoggedIn && isLoggingIn) {
        return '/dashboard';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/course-input',
        builder: (context, state) => const CourseInputScreen(),
      ),
      GoRoute(
        path: '/pdf-upload',
        builder: (context, state) => const PdfUploadScreen(),
      ),
      GoRoute(
        path: '/summary/:id',
        builder: (context, state) {
          final summaryId = state.pathParameters['id']!;
          return SummaryScreen(summaryId: summaryId);
        },
      ),
      GoRoute(
        path: '/quiz/:id',
        builder: (context, state) {
          final quizId = state.pathParameters['id']!;
          return QuizScreen(quizId: quizId);
        },
      ),
      GoRoute(
        path: '/quiz-result/:id',
        builder: (context, state) {
          final quizId = state.pathParameters['id']!;
          final score = int.parse(state.uri.queryParameters['score'] ?? '0');
          final total = int.parse(state.uri.queryParameters['total'] ?? '1');
          return QuizResultScreen(
            quizId: quizId,
            score: score,
            total: total,
          );
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/exam-generator',
        builder: (context, state) => const ExamGeneratorScreen(),
      ),
      GoRoute(
        path: '/mindmap',
        builder: (context, state) => const MindMapScreen(),
      ),
      GoRoute(
        path: '/mindmap/:id',
        builder: (context, state) {
          final mindMapId = state.pathParameters['id']!;
          return MindMapScreen(mindMapId: mindMapId);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/saved-summaries',
        builder: (context, state) => const SavedSummariesScreen(),
      ),
      GoRoute(
        path: '/exam/:id',
        builder: (context, state) {
          final examId = state.pathParameters['id']!;
          return ExamDetailsScreen(examId: examId);
        },
      ),
    ],
  );
});
