// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importar tus pantallas y providers
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/content/dashboard.dart';

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
  @override
  void initState() {
    super.initState();
    // Inicializar el listener de auth state
    ref.read(authStateNotifierProvider);
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
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          // Si hay usuario, va a Home, si no, a Login
          home: user == null ? const LoginScreen() : const DashboardPage(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const DashboardPage(),
          },
        );
      },
    );
  }
}
