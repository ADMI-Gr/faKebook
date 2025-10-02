import 'package:fakebook/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

final updateAvatarProvider =
    FutureProvider.family<void, ({String userId, String imagePath})>(
        (ref, params) async {
  final repo = ProfileRepository();
  await repo.updateAvatar(params.userId, params.imagePath);
  // Refrescar el usuario actual
  ref.invalidate(userProvider);
});
