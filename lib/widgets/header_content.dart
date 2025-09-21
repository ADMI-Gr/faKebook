import 'package:flutter/material.dart';
import 'package:fakebook/screens/content/dashboard.dart';
import 'package:fakebook/screens/content/follow_screen.dart';

enum HeaderTab { popular, siguiendo }

/// ESTE ES EL HEADER QUE APARECE EN LA PANTALLA PRINCIPAL Y EN LA PANTALLA DE SIGUIENDO
/// AL HACER EL SCROL APARECE LA ALERTA DE LOS PIXELES PERO EN ESTE CASO ES FALSO NEGATIVO YA QUE
/// LA ANIMACION HACE Q SE VEA ASI (se puede cambiar si no les gusta)
class HeaderContent extends StatefulWidget {
  const HeaderContent({
    super.key,
    this.selectedTab = HeaderTab.popular,
    this.onActionTap,
    this.onSearchTap,
  });

  final HeaderTab selectedTab;
  final VoidCallback? onActionTap;
  final VoidCallback? onSearchTap;

  @override
  State<HeaderContent> createState() => _HeaderContentState();
}

class _HeaderContentState extends State<HeaderContent> {
  late HeaderTab _current;

  static const Color _accent = Color(0xFF6C63FF);
  static const Color _pillBg = Color(0xFFF2F3F7);

  @override
  void initState() {
    super.initState();
    _current = widget.selectedTab;
  }

  @override
  void didUpdateWidget(covariant HeaderContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTab != widget.selectedTab) {
      _current = widget.selectedTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Material(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: widget.onSearchTap,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: _pillBg,
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: _accent.withOpacity(0.9)),
                            const SizedBox(width: 10),
                            Text(
                              'Buscar',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.onActionTap,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: _pillBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.black87, size: 20),
                    ),
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
                    label: 'Popular',
                    selected: _current == HeaderTab.popular,
                    onTap: () => _onTabTap(HeaderTab.popular),
                  ),
                  const SizedBox(width: 20),
                  _Segment(
                    label: 'Siguiendo',
                    selected: _current == HeaderTab.siguiendo,
                    onTap: () => _onTabTap(HeaderTab.siguiendo),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
          ],
        ),
      );
    });
  }

  void _onTabTap(HeaderTab tab) {
    if (_current == tab) return;
    setState(() => _current = tab);

    if (tab == HeaderTab.popular) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const FollowScreen()),
      );
    }
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1EEFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF6C63FF) : Colors.grey.withOpacity(0.7),
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Solo deslizamos hacia arriba sin efecto de opacidad
    return ClipRect(
      child: Transform.translate(
        offset: Offset(0, -shrinkOffset),
        child: child,
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