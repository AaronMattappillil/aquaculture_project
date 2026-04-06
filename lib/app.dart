import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';

// User
import 'screens/user/ponds_list_screen.dart';
import 'screens/user/pond_shell_screen.dart';
import 'screens/user/add_pond_screen.dart';
import 'screens/user/data_visualization_screen.dart';
import 'screens/user/alerts_screen.dart';
import 'screens/user/alert_report_screen.dart';
import 'screens/user/support_screen.dart';
import 'screens/user/ticket_detail_screen.dart';
import 'screens/user/reports_list_screen.dart';
import 'screens/user/pond_settings_screen.dart';
import 'screens/user/profile_screen.dart';
import 'screens/user/manage_profile_screen.dart';
import 'screens/user/notification_settings_screen.dart';
import 'screens/user/help_faq_screen.dart';
import 'screens/user/about_app_screen.dart';

// Admin
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/admin_user_detail_screen.dart';
import 'screens/admin/admin_complaint_detail_screen.dart';

import 'models/user_model.dart';

final authStateProvider = StateProvider<UserModel?>((ref) => null); 
final appInitializedProvider = StateProvider<bool>((ref) => false);

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
    _ref.listen(appInitializedProvider, (previous, next) {
      notifyListeners();
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final user = _ref.read(authStateProvider);
    final isInitialized = _ref.read(appInitializedProvider);
    
    final isSplash = state.matchedLocation == '/splash';
    final isAuthRoute = state.matchedLocation.startsWith('/auth');
    
    // If not initialized, stay on splash
    if (!isInitialized) {
      return isSplash ? null : '/splash';
    }

    // If initialized and on splash/auth routes, decide where to go
    if (isSplash || isAuthRoute) {
      if (user == null) {
        return isAuthRoute ? null : '/auth/login';
      }
      return user.role == 'admin' ? '/admin/users' : '/user/ponds';
    }

    // Protection for other routes
    if (user == null) return '/auth/login';
    
    return null;
  }
}

final routerNotifierProvider = Provider((ref) => RouterNotifier(ref));

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/auth/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/auth/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/auth/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      
      // User routes
      GoRoute(path: '/user/ponds', builder: (context, state) => const PondsListScreen()),
      GoRoute(path: '/user/add-pond', builder: (context, state) => const AddPondScreen()),
      GoRoute(path: '/user/dashboard/:id', builder: (context, state) => PondShellScreen(pondId: state.pathParameters['id']!)),
      GoRoute(path: '/user/data/:id', builder: (context, state) => DataVisualizationScreen(pondId: state.pathParameters['id']!)),
      GoRoute(path: '/user/reports/:id', builder: (context, state) => ReportsListScreen(pondId: state.pathParameters['id']!)),
      GoRoute(path: '/user/settings/:id', builder: (context, state) => PondSettingsScreen(pondId: state.pathParameters['id']!)),
      GoRoute(path: '/user/alerts', builder: (context, state) => const AlertsScreen()),
      GoRoute(path: '/user/alert-report/:id', builder: (context, state) => AlertReportScreen(alertId: state.pathParameters['id']!)),
      GoRoute(path: '/user/support', builder: (context, state) => const SupportScreen()),
      GoRoute(path: '/user/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/manage-profile', builder: (context, state) => const ManageProfileScreen()),
      GoRoute(path: '/notification-settings', builder: (context, state) => const NotificationSettingsScreen()),
      GoRoute(path: '/help-faq', builder: (context, state) => const HelpFaqScreen()),
      GoRoute(path: '/about-aquasense', builder: (context, state) => const AboutAppScreen()),
      GoRoute(path: '/user/ticket/:id', builder: (context, state) => TicketDetailScreen(ticketId: state.pathParameters['id']!)),
      
      // Admin routes
      GoRoute(path: '/admin/users', builder: (context, state) => const AdminUsersScreen()),
      GoRoute(path: '/admin/user/:id', builder: (context, state) => AdminUserDetailScreen(userId: state.pathParameters['id']!)),
      GoRoute(path: '/admin/complaint/:id', builder: (context, state) => AdminComplaintDetailScreen(ticketId: state.pathParameters['id']!)),
    ],
  );
});

class AquaSenseApp extends ConsumerWidget {
  const AquaSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'AquaSense',
      theme: appTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
