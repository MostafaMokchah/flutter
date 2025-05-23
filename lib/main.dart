import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:mon_sirh_mobile/models/user.dart';
import 'package:mon_sirh_mobile/providers/auth_provider.dart';
import 'package:mon_sirh_mobile/providers/conge_provider.dart';
import 'package:mon_sirh_mobile/screens/calendrier_screen.dart';
import 'package:mon_sirh_mobile/screens/dashboard_screen.dart';
import 'package:mon_sirh_mobile/screens/demandes_screen.dart';
import 'package:mon_sirh_mobile/screens/fiche_employe_screen.dart';
import 'package:mon_sirh_mobile/screens/login_screen.dart';
import 'package:mon_sirh_mobile/screens/pdf_viewer_screen.dart';
import 'package:mon_sirh_mobile/services/api_service.dart';
import 'package:mon_sirh_mobile/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mon_sirh_mobile/screens/RegisterScreen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBjxJU78ljMGUJBFbH-mUi0H_9WMyzmTAo",
      authDomain: "flutterproject-dda3c.firebaseapp.com",
      projectId: "flutterproject-dda3c",
      storageBucket: "flutterproject-dda3c.appspot.com",
      messagingSenderId: "751693656378",
      appId: "1:751693656378:web:300958ed49271d578ba003",
      measurementId: "G-P8TLN55HW3",
    ),
  );

  final authService = AuthService();

runApp(MyApp(authService: authService));

}

class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authService)..tryAutoLogin(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CongeProvider>(
          create: (context) => CongeProvider(
            Provider.of<AuthProvider>(context, listen: false).currentUser ?? _placeholderUser(),
          ),
          update: (context, authProvider, previous) => CongeProvider(
            authProvider.currentUser ?? _placeholderUser(),
          ),
        ),
      ],
      child: const AppRouter(),
    );
  }

  static User _placeholderUser() =>
      User(id: '', email: '', name: '', role: UserRole.employee);
}


class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    final router = GoRouter(
  initialLocation: '/login',
  refreshListenable: authProvider,
  redirect: (context, state) {
    final isLoggedIn = authProvider.isAuthenticated;
    final isLoading = authProvider.isLoading;
    final isAtLogin = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (isLoading) {
      return isAtLogin ? null : '/login';
    }

    if (!isLoggedIn && !isAtLogin) {
      return '/login';
    }

    if (isLoggedIn && state.matchedLocation == '/login') {
      return '/dashboard';
    }

    return null;
  },
  routes: [
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
      routes: [
        GoRoute(
          path: 'profile',
          builder: (context, state) => const FicheEmployeScreen(),
        ),
        GoRoute(
          path: 'demandes',
          builder: (context, state) => const DemandesScreen(),
        ),
        GoRoute(
          path: 'calendrier',
          builder: (context, state) => const CalendrierScreen(),
        ),
        GoRoute(
          path: 'documents',
          builder: (context, state) => const PdfViewerScreen(
            pdfUrl: 'https://example.com/sample.pdf',
            title: 'Sample PDF',
          ),
        ),
        GoRoute(
          path: 'pdf-view',
          builder: (context, state) {
            final url = state.uri.queryParameters['url'];
            final path = state.uri.queryParameters['path'];
            final title = state.uri.queryParameters['title'] ?? 'Document PDF';
            return PdfViewerScreen(pdfUrl: url, pdfPath: path, title: title);
          },
        ),
        GoRoute(
          path: 'team',
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Gestion Équipe'),
          redirect: (context, state) =>
              _roleGuard(context, [UserRole.manager, UserRole.rhAdmin]),
        ),
        GoRoute(
          path: 'rh-dashboard',
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Tableau de Bord RH'),
          redirect: (context, state) =>
              _roleGuard(context, [UserRole.rhAdmin]),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Erreur')),
    body: Center(child: Text('Page non trouvée: ${state.error}')),
  ),
);

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => MaterialApp.router(
        title: 'Mon SIRH Mobile',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  String? _roleGuard(BuildContext context, List<UserRole> allowedRoles) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
      return '/login';
    }
    if (!allowedRoles.contains(authProvider.currentUser!.role)) {
      return '/dashboard';
    }
    return null;
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title - À implémenter')),
    );
  }
}
