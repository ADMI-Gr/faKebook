import 'package:fakebook/screens/content/search_screen.dart';
import 'package:fakebook/screens/content/image_preview_screen.dart';
import 'package:fakebook/widgets/explore_post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

// PANTALLA DE EXPLORAR CON GRID
class ExploreGridScreen extends StatelessWidget {
  const ExploreGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // IMAGENES DEMO PARA LA PANTALLA
    final List<String> imageUrls = List.generate(
      14, // 
      (index) => 'https://picsum.photos/seed/$index/600/600',
    );
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),
            const Text(
              'Explorar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: Colors.white70),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Buscar...',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.white),
                        textInputAction: TextInputAction.search,
                        // NAVEGACION A LA PANTALLA DE BUSQUEDA
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SearchScreen(),
                                settings:
                                    const RouteSettings(name: '/search')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(2),
        child: imageUrls.isEmpty
            ? _buildEmptyState(context)
            : SingleChildScrollView(
                child: StaggeredGrid.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                  children: _buildPattern(context, imageUrls),
                ),
              ),
      ),
    );
  }

  // CONSTRUCCION DEL PATRON DEL GRID
  List<Widget> _buildPattern(BuildContext context, List<String> images) {
    List<Widget> tiles = [];

    for (int i = 0; i < images.length; i += 5) {
      final remaining = images.length - i;
      final int blockIndex = (i ~/ 5);

      if (remaining >= 5) {
        if (blockIndex % 2 == 0) {
          tiles.addAll([
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 2,
              child: _buildPostCard(context, images[i]),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _buildPostCard(context, images[i + 1]),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _buildPostCard(context, images[i + 2]),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _buildPostCard(context, images[i + 3]),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _buildPostCard(context, images[i + 4]),
            ),
          ]);
        } else {
          tiles.addAll([
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _buildPostCard(context, images[i]),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _buildPostCard(context, images[i + 1]),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 2,
              child: _buildPostCard(context, images[i + 2]),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _buildPostCard(context, images[i + 3]),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _buildPostCard(context, images[i + 4]),
            ),
          ]);
        }
      } else {
        // SI NO HAY 5 IMAGENES PARA EL GRID SE COLOCAN NORMALES
        for (int j = i; j < images.length; j++) {
          tiles.add(
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: _buildPostCard(context, images[j]),
            ),
          );
        }
      }
    }

    return tiles;
  }

  // VER LA PUBLICACION DE LA IMG Y DAR LIKE
  Widget _buildPostCard(BuildContext context, String url) {
    final int likeCount = (url.hashCode.abs() % 997) + 1;
    // NAVEGAR A LA PANTALLA DE PREVIEW DE LA IMAGEN
    return ExplorePostCard(
      imageUrl: url,
      likeCount: likeCount,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ImagePreviewScreen(
              imageUrl: url,
              likeCount: likeCount,
            ),
          ),
        );
      },
    );
  }

  // MENSAJE EN CASO DE NO HABER PUBLICACIONES Q MOSTRARSE
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grid_view_rounded,
                size: 56, color: Colors.grey.withOpacity(0.7)),
            const SizedBox(height: 12),
            Text(
              'Aun no hay publicaciones para mostrar',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Vuelve mas tarde para ver las publicaciones nuevas',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
