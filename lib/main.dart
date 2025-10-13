// lib/main.dart
import 'package:fakebook/screens/auth/edit_profile_screen.dart';
import 'package:fakebook/widgets/deep_link_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importar tus pantallas y providers
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/content/dashboard.dart';
import 'package:fakebook/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  // Inicializar Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final DeepLinkHandler _deepLinkHandler = DeepLinkHandler();

  @override
  void initState() {
    super.initState();
    // Inicializar el listener de auth state
    ref.read(authStateNotifierProvider);
  }

  @override
  void dispose() {
    _deepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Inicializar auth al construir
    final initializeAuth = ref.watch(initializeAuthProvider);

    return initializeAuth.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const LoginScreen(),
      ),
      data: (initialUser) {
        final user = ref.watch(userProvider);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "faKebook",
          theme: ref.watch(appThemeProvider),
          // Si hay usuario, va a Home, si no, a Login
          home: user == null
              ? const LoginScreen()
              : _AppWithDeepLinks(deepLinkHandler: _deepLinkHandler),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const DashboardPage(),
            '/profile/edit': (context) => const EditProfilePage(),
          },
        );
      },
    );
  }
}

// Wrapper para inicializar deep links solo cuando el usuario está autenticado
class _AppWithDeepLinks extends ConsumerStatefulWidget {
  final DeepLinkHandler deepLinkHandler;

  const _AppWithDeepLinks({required this.deepLinkHandler});

  @override
  ConsumerState<_AppWithDeepLinks> createState() => _AppWithDeepLinksState();
}

class _AppWithDeepLinksState extends ConsumerState<_AppWithDeepLinks> {
  @override
  void initState() {
    super.initState();
    // Inicializar deep links después de que el widget se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.deepLinkHandler.init(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const DashboardPage();
  }
}
