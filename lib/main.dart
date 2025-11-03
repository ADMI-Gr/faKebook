// lib/main.dart
import 'package:fakebook/providers/notifications_provider.dart';
import 'package:fakebook/screens/auth/edit_profile_screen.dart';
import 'package:fakebook/widgets/deep_link_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importar tus pantallas y providers
import 'providers/auth_provider.dart';
import 'providers/chat_providers.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/content/dashboard.dart';
import 'screens/content/edit_badges_screen.dart';
import 'services/notification_service.dart';
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

  // Inicializar NotificationService
  await NotificationService().initialize();

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
    // ⭐ Guardar el ProviderContainer para las notificaciones
    NotificationService.providerContainer = ProviderScope.containerOf(context);

    // Debug: Verificar que el container está guardado
    print(
        '🔧 ProviderContainer guardado: ${NotificationService.providerContainer != null}');
    print(
        '🔧 NavigatorKey configurado: ${NotificationService.navigatorKey != null}');

    // Inicializar auth al construir
    final initializeAuth = ref.watch(initializeAuthProvider);

    return initializeAuth.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        // ⭐ Agregar navigatorKey aquí también
        navigatorKey: NotificationService.navigatorKey,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => MaterialApp(
        debugShowCheckedModeBanner: false,
        // ⭐ Agregar navigatorKey aquí también
        navigatorKey: NotificationService.navigatorKey,
        home: const LoginScreen(),
      ),
      data: (initialUser) {
        final user = ref.watch(userProvider);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "faKebook",
          theme: ref.watch(appThemeProvider),
          // ⭐ CRÍTICO: Agregar el navigatorKey aquí
          navigatorKey: NotificationService.navigatorKey,
          // Si hay usuario, va a Home, si no, a Login
          home: user == null
              ? const LoginScreen()
              : _AppWithDeepLinks(deepLinkHandler: _deepLinkHandler),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const DashboardPage(),
            '/profile/edit': (context) => const EditProfilePage(),
            '/profile/badges/edit': (context) {
              final userId =
                  ModalRoute.of(context)!.settings.arguments as String;
              return EditBadgesScreen(userId: userId);
            },
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.deepLinkHandler.init(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const AppNotificationListener(
      child: DashboardPage(),
    );
  }
}

// Widget para escuchar notificaciones
class AppNotificationListener extends ConsumerWidget {
  final Widget child;

  const AppNotificationListener({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    // Solo inicializar si el usuario está autenticado
    if (user != null) {
      // IMPORTANTE: Esto mantiene el listener activo
      ref.watch(realtimeNotificationsProvider(user.id));

      // Debug: Verificar que el listener está activo
      print(
          '🔔 Listener de notificaciones inicializado para usuario: ${user.id}');
    }

    return child;
  }
}
