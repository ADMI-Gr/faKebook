import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/badge_model.dart';

class BadgeRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // OBTENER TODAS LAS INSIGNIAS DISPONIBLES
  Future<List<BadgeModel>> getAllBadges() async {
    final response =
        await _supabase.from('badges').select().order('name', ascending: true);

    return (response as List)
        .map((badge) => BadgeModel.fromMap(badge))
        .toList();
  }

  // OBTENER UNA INSIGNIA POR ID
  Future<BadgeModel?> getBadgeById(String badgeId) async {
    final response =
        await _supabase.from('badges').select().eq('id', badgeId).maybeSingle();

    if (response == null) return null;
    return BadgeModel.fromMap(response);
  }

  // OBTENER MÚLTIPLES INSIGNIAS POR IDS
  Future<List<BadgeModel>> getBadgesByIds(List<String> badgeIds) async {
    if (badgeIds.isEmpty) return [];

    final response =
        await _supabase.from('badges').select().inFilter('id', badgeIds);

    return (response as List)
        .map((badge) => BadgeModel.fromMap(badge))
        .toList();
  }

  // BUSCAR INSIGNIAS POR NOMBRE
  Future<List<BadgeModel>> searchBadges(String query) async {
    final response = await _supabase
        .from('badges')
        .select()
        .ilike('name', '%$query%')
        .order('name', ascending: true);

    return (response as List)
        .map((badge) => BadgeModel.fromMap(badge))
        .toList();
  }
}
