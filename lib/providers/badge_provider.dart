import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/badge_model.dart';
import '../repositories/badge_repository.dart';
import '../repositories/profile_repository.dart';

// Provider del repositorio de insignias
final badgeRepositoryProvider = Provider<BadgeRepository>((ref) {
  return BadgeRepository();
});

// Provider del repositorio de perfiles
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

// Provider para obtener todas las insignias disponibles
final allBadgesProvider = FutureProvider<List<BadgeModel>>((ref) async {
  final repo = ref.watch(badgeRepositoryProvider);
  return await repo.getAllBadges();
});

// Provider para obtener una insignia específica por ID
final badgeByIdProvider =
    FutureProvider.family<BadgeModel?, String>((ref, badgeId) async {
  final repo = ref.watch(badgeRepositoryProvider);
  return await repo.getBadgeById(badgeId);
});

// Provider para obtener múltiples insignias por IDs
final badgesByIdsProvider =
    FutureProvider.family<List<BadgeModel>, List<String>>(
        (ref, badgeIds) async {
  final repo = ref.watch(badgeRepositoryProvider);
  return await repo.getBadgesByIds(badgeIds);
});

// Provider para buscar insignias por nombre
final searchBadgesProvider =
    FutureProvider.family<List<BadgeModel>, String>((ref, query) async {
  final repo = ref.watch(badgeRepositoryProvider);
  return await repo.searchBadges(query);
});

// Provider para obtener las insignias destacadas de un usuario
final userFeaturedBadgesProvider =
    FutureProvider.family<List<String>, String>((ref, userId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return await repo.getFeaturedBadges(userId);
});

// Provider para obtener todas las insignias de un usuario (solo lectura)
final userAllBadgesProvider =
    FutureProvider.family<List<String>, String>((ref, userId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return await repo.getAllUserBadges(userId);
});

// Provider para obtener los modelos completos de las insignias destacadas de un usuario
final userFeaturedBadgeModelsProvider =
    FutureProvider.family<List<BadgeModel>, String>((ref, userId) async {
  final badgeIds = await ref.watch(userFeaturedBadgesProvider(userId).future);
  if (badgeIds.isEmpty) return [];
  return await ref.watch(badgesByIdsProvider(badgeIds).future);
});

// Provider para obtener los modelos completos de todas las insignias de un usuario
final userAllBadgeModelsProvider =
    FutureProvider.family<List<BadgeModel>, String>((ref, userId) async {
  final badgeIds = await ref.watch(userAllBadgesProvider(userId).future);
  if (badgeIds.isEmpty) return [];
  return await ref.watch(badgesByIdsProvider(badgeIds).future);
});

// Provider para actualizar insignias destacadas
final updateFeaturedBadgesProvider =
    FutureProvider.family<void, ({String userId, List<String> badgeIds})>(
        (ref, params) async {
  final repo = ref.watch(profileRepositoryProvider);
  await repo.updateFeaturedBadges(params.userId, params.badgeIds);

  // Invalidar los providers relacionados para refrescar los datos
  ref.invalidate(userFeaturedBadgesProvider(params.userId));
  ref.invalidate(userFeaturedBadgeModelsProvider(params.userId));
});
