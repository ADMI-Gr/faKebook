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

final userProvider = StateProvider<UserModel?>((ref) => null);

// 🔑 Nuevo: Provider para inicializar la autenticación
final initializeAuthProvider = FutureProvider<UserModel?>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  final user = await repo.getCurrentUser();

  // Si hay un usuario, actualizar el userProvider
  if (user != null) {
    ref.read(userProvider.notifier).state = user;
  }

  return user;
});

// 🔑 Provider para escuchar cambios de autenticación
final authStateListenerProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return repo.authStateChanges;
});

// 🔑 Notifier para manejar cambios automáticos de auth
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
        _ref.read(userProvider.notifier).state = user;
      } else if (event == AuthChangeEvent.signedOut) {
        // Usuario cerró sesión
        _ref.read(userProvider.notifier).state = null;
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
    ref.read(userProvider.notifier).state = user;
  }

  return user;
});

// 🔑 Login actualizado
final loginUserProvider =
    FutureProvider.family<UserModel?, Map<String, String>>((ref, data) async {
  final repo = ref.read(authRepositoryProvider);
  final user = await repo.signIn(
    email: data['email']!,
    password: data['password']!,
  );

  // Si el login es exitoso, actualizar el userProvider
  if (user != null) {
    ref.read(userProvider.notifier).state = user;
  }

  return user;
});

// 🔑 Logout actualizado
final logoutUserProvider = FutureProvider<void>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  await repo.signOut();
  // El listener automáticamente pondrá userProvider en null
});

// 🔑 Provider para verificar si un username está disponible
final checkUsernameProvider =
    FutureProvider.family<bool, String>((ref, username) async {
  final repo = ref.read(authRepositoryProvider);
  return await repo.isUsernameAvailable(username);
});

// 🔑 Provider para actualizar perfil
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

  // Recargar el usuario actualizado
  final updatedUser = await repo.getCurrentUser();
  if (updatedUser != null) {
    ref.read(userProvider.notifier).state = updatedUser;
  }
});
