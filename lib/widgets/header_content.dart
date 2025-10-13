import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/screens/content/dashboard.dart';
import 'package:fakebook/screens/content/follow_screen.dart';
import '../providers/auth_provider.dart';

enum HeaderTab { nuevo, siguiendo }

/// ESTE ES EL HEADER QUE APARECE EN LA PANTALLA PRINCIPAL Y EN LA PANTALLA DE SIGUIENDO
/// AL HACER EL SCROL APARECE LA ALERTA DE LOS PIXELES PERO EN ESTE CASO ES FALSO NEGATIVO YA QUE
/// LA ANIMACION HACE Q SE VEA ASI (se puede cambiar si no les gusta)
class HeaderContent extends ConsumerWidget {
  const HeaderContent({
    super.key,
    this.selectedTab = HeaderTab.nuevo,
  });

  final HeaderTab selectedTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Material(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  backgroundColor: Colors.grey.shade200,
                  child: user?.avatarUrl == null
                      ? Icon(Icons.person, color: Colors.grey.shade600)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      'En qué estás pensando...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Flexible(
                          child: _buildActionChip(
                              Icons.photo_library_outlined, 'Fotos')),
                      Flexible(
                          child:
                              _buildActionChip(Icons.attach_file, 'Adjuntar')),
                      Flexible(
                          child: _buildActionChip(
                              Icons.person_add_alt_1_outlined, 'Etiquetar')),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implementar lógica de publicación
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Publicar'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Segment(
                  label: 'Nuevo',
                  selected: selectedTab == HeaderTab.nuevo,
                  onTap: () =>
                      _onTabTap(context, HeaderTab.nuevo, selectedTab),
                ),
                const SizedBox(width: 8),
                _Segment(
                  label: 'Siguiendo',
                  selected: selectedTab == HeaderTab.siguiendo,
                  onTap: () =>
                      _onTabTap(context, HeaderTab.siguiendo, selectedTab),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  void _onTabTap(BuildContext context, HeaderTab tab, HeaderTab currentTab) {
    if (currentTab == tab) return;

    if (tab == HeaderTab.nuevo) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const FollowScreen()),
      );
    }
  }

  Widget _buildActionChip(IconData icon, String label) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 20, color: Colors.grey[700]),
      label: Text(
        label,
        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withOpacity(0.7),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// ---------------- Sliver Delegate ----------------
class HeaderSliver extends SliverPersistentHeaderDelegate {
  HeaderSliver({
    required this.child,
    required this.maxHeight,
    this.minHeight = 0,
  });

  final Widget child;
  final double maxHeight;
  final double minHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: Colors.white,
      child: Stack(
        children: [
          ClipRect(
            child: Transform.translate(
              offset: Offset(0, -shrinkOffset),
              child: child,
            ),
          ),
          if (shrinkOffset <= 0.0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 1,
                color: Colors.grey.shade200,
              ),
            ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant HeaderSliver oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.minHeight != minHeight;
  }
}
