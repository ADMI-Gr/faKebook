import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/screens/content/dashboard.dart';
import 'package:fakebook/screens/content/follow_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/social_provider.dart';

enum HeaderTab { nuevo, siguiendo }

/// ESTE ES EL HEADER QUE APARECE EN LA PANTALLA PRINCIPAL Y EN LA PANTALLA DE SIGUIENDO
/// AL HACER EL SCROL APARECE LA ALERTA DE LOS PIXELES PERO EN ESTE CASO ES FALSO NEGATIVO YA QUE
/// LA ANIMACION HACE Q SE VEA ASI (se puede cambiar si no les gusta)
class HeaderContent extends ConsumerStatefulWidget {
  const HeaderContent({
    super.key,
    this.selectedTab = HeaderTab.nuevo,
  });

  final HeaderTab selectedTab;

  @override
  ConsumerState<HeaderContent> createState() => _HeaderContentState();
}

class _HeaderContentState extends ConsumerState<HeaderContent> {
  static const int _maxChars = 280;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isPublishing = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _publish() async {
    final hasContent = _textController.text.trim().isNotEmpty;
    if (!hasContent) {
      _showSnack('Escribe algo para publicar');
      return;
    }

    setState(() => _isPublishing = true);

    try {
      await ref.read(createPostProvider(
        (
          content: _textController.text.trim(),
          imageFile: null,
        ),
      ).future);

      if (!mounted) return;

      setState(() {
        _textController.clear();
        _isPublishing = false;
      });

      _focusNode.unfocus();
      _showSnack('¡Publicado con éxito!');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error al publicar: $e');
      setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Material(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 60,
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        maxLines: null,
                        minLines: 1,
                        maxLength: _maxChars,
                        enabled: !_isPublishing,
                        decoration: InputDecoration(
                          hintText: 'En qué estás pensando...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: InputBorder.none,
                          isDense: true,
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          disabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        style: const TextStyle(fontSize: 15),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_textController.text.length}/$_maxChars',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textController.text.length > _maxChars * 0.9
                        ? Colors.red
                        : Colors.grey[600],
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      _textController.text.trim().isNotEmpty && !_isPublishing
                          ? _publish
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _textController.text.trim().isNotEmpty
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary.withOpacity(0.35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    disabledBackgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.35),
                    disabledForegroundColor: Colors.white.withOpacity(0.6),
                  ),
                  child: _isPublishing
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Publicar',
                          style: TextStyle(fontWeight: FontWeight.w600),
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
                  label: 'Nuevo',
                  selected: widget.selectedTab == HeaderTab.nuevo,
                  onTap: () =>
                      _onTabTap(context, HeaderTab.nuevo, widget.selectedTab),
                ),
                const SizedBox(width: 8),
                _Segment(
                  label: 'Siguiendo',
                  selected: widget.selectedTab == HeaderTab.siguiendo,
                  onTap: () => _onTabTap(
                      context, HeaderTab.siguiendo, widget.selectedTab),
                ),
              ],
            ),
          ),
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
