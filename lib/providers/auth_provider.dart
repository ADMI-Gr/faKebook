// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

// 🔄 CAMBIO: Convertir a StateNotifierProvider
class UserNotifier extends StateNotifier<UserModel?> {
  final ProfileRepository _profileRepository;

  UserNotifier(this._profileRepository) : super(null);

  // Método para actualizar el usuario
  void setUser(UserModel? user) {
    state = user;
  }

  // Método para refrescar el usuario sin cerrar sesión
  Future<void> refreshUser() async {
    try {
      final updatedUser = await _profileRepository.getCurrentUser();
      if (updatedUser != null) {
        state = updatedUser;
      }
    } catch (e) {
      print('Error al refrescar usuario: $e');
      // No cambiar el state en caso de error, mantener el usuario actual
    }
  }

  // Método para limpiar el usuario (logout)
  void clearUser() {
    state = null;
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  final profileRepo = ref.read(profileRepositoryProvider);
  return UserNotifier(profileRepo);
});

// 🔒 Nuevo: Provider para inicializar la autenticación
final initializeAuthProvider = FutureProvider<UserModel?>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  final user = await repo.getCurrentUser();

  // Si hay un usuario, actualizar el userProvider
  if (user != null) {
    ref.read(userProvider.notifier).setUser(user);
  }

  return user;
});

// 🔒 Provider para escuchar cambios de autenticación
final authStateListenerProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return repo.authStateChanges;
});

// 🔒 Notifier para manejar cambios automáticos de auth
class AuthStateNotifier extends StateNotifier<void> {
  final Ref _ref;

  AuthStateNotifier(this._ref) : super(null) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    final supabase = Supabase.instance.client;
    supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;

      if (event == AuthChangeEvent.signedIn && data.session?.user != null) {
        // Usuario se logueó, cargar perfil
        final repo = _ref.read(authRepositoryProvider);
        final user = await repo.getCurrentUser();
        _ref.read(userProvider.notifier).setUser(user);
      } else if (event == AuthChangeEvent.signedOut) {
        // Usuario cerró sesión
        _ref.read(userProvider.notifier).clearUser();
      }
    });
  }
}

final authStateNotifierProvider =
    StateNotifierProvider<AuthStateNotifier, void>((ref) {
  return AuthStateNotifier(ref);
});

final registerUserProvider =
    FutureProvider.family<UserModel?, Map<String, String>>((ref, data) async {
  final repo = ref.read(authRepositoryProvider);
  final user = await repo.signUp(
    email: data['email']!,
    password: data['password']!,
    username: data['username']!,
    displayName: data['displayName'],
  );

  // Si el registro es exitoso, actualizar el userProvider
  if (user != null) {
    ref.read(userProvider.notifier).setUser(user);
  }

  return user;
});

// 🔒 Login actualizado
final loginUserProvider =
    FutureProvider.family<UserModel?, Map<String, String>>((ref, data) async {
  final repo = ref.read(authRepositoryProvider);
  try {
    final user = await repo.signIn(
      email: data['email']!,
      password: data['password']!,
    );

    // Si el login es exitoso, actualizar el userProvider
    if (user != null) {
      ref.read(userProvider.notifier).setUser(user);
    }

    return user;
  } on AuthException catch (e) {
    // Traducir errores comunes a mensajes más amigables
    if (e.message.toLowerCase().contains('invalid login credentials')) {
      throw Exception(
          'Email o contraseña incorrectos. Por favor, inténtalo de nuevo.');
    } else if (e.message.toLowerCase().contains('email not confirmed')) {
      throw Exception(
          'Por favor, confirma tu email para poder iniciar sesión.');
    }
    // Error genérico para otros casos
    throw Exception('Ha ocurrido un error al iniciar sesión.');
  }
});

// 🔒 Logout actualizado
final logoutUserProvider = FutureProvider<void>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  await repo.signOut();
  // El listener automáticamente pondrá userProvider en null
});

// 🔒 Provider para verificar si un username está disponible
final checkUsernameProvider =
    FutureProvider.family<bool, String>((ref, username) async {
  final repo = ref.read(authRepositoryProvider);
  return await repo.isUsernameAvailable(username);
});

// 🔒 Provider para actualizar perfil
final updateProfileProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, data) async {
  final repo = ref.read(profileRepositoryProvider);
  final currentUser = ref.read(userProvider);

  if (currentUser == null) throw Exception('No hay usuario logueado');

  await repo.updateUserProfile(
    currentUser.id,
    displayName: data['displayName'],
    bio: data['bio'],
    avatarUrl: data['avatarUrl'],
    metadata: data['metadata'],
  );

  // Recargar el usuario actualizado usando el nuevo método
  await ref.read(userProvider.notifier).refreshUser();
});

// 🔄 Provider para refrescar el usuario actual sin cerrar sesión
final refreshCurrentUserProvider = FutureProvider<void>((ref) async {
  final repo = ref.read(profileRepositoryProvider);
  final updatedUser = await repo.getCurrentUser();

  if (updatedUser != null) {
    ref.read(userProvider.notifier).state = updatedUser;
  }
});
