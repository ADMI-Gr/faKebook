import 'package:fakebook/widgets/badge_tile.dart';
import 'package:fakebook/screens/content/post_publish_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class PostItem {
  final String username;
  final String identifier;
  final String content;
  final String? imageUrl;
  final String? avatarUrl;
  final bool isMine;

  const PostItem({
    required this.username,
    required this.identifier,
    required this.content,
    this.imageUrl,
    this.avatarUrl,
    this.isMine = false,
  });
}

// AQUI SE RECIBE LA LISTA DE LOS POSTS DESDE EL DASHBOARD
class PostList extends StatelessWidget {
  final List<PostItem> posts;

  const PostList({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.post_add_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '¡Todavia no hay publicaciones!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Animate a ser el primero en publicar\n'
                    'o comienza a seguir a tus amigos para ver sus posts.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      backgroundColor: const Color(0xFF6C63FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PostPublishScreen()),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 20, color: Colors.white),
                    label: const Text(
                      'Crear tu primera publicacion',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final p = posts[index];
          return _PostCard(
            username: p.username,
            identifier: p.identifier,
            content: p.content,
            imageUrl: p.imageUrl,
            avatarUrl: p.avatarUrl,
            isMine: p.isMine,
          );
        },
        childCount: posts.length,
      ),
    );
  }
}

// CLASE PARA EL POST Y SU DISEÑO
class _PostCard extends StatelessWidget {
  final String username;
  final String identifier;
  final String content;
  final String? imageUrl;
  final String? avatarUrl;
  final bool isMine;

  const _PostCard({
    required this.username,
    required this.identifier,
    required this.content,
    this.imageUrl,
    this.avatarUrl,
    this.isMine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          (avatarUrl != null && avatarUrl!.isNotEmpty)
                              ? NetworkImage(avatarUrl!)
                              : null,
                      backgroundColor:
                          (avatarUrl != null && avatarUrl!.isNotEmpty)
                              ? Colors.transparent
                              : Colors.grey[300],
                      child: (avatarUrl == null || avatarUrl!.isEmpty)
                          ? Text(
                              username.isNotEmpty
                                  ? username[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    // INSIGNIAS DEL USUARIO
                    const Column(
                      children: [
                        Row(
                          children: [
                            BadgeTile(
                                icon: Icons.verified,
                                active: true,
                                size: 24,
                                radius: 4),
                            SizedBox(width: 4),
                            BadgeTile(
                                icon: Icons.star,
                                active: false,
                                size: 24,
                                radius: 4),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            BadgeTile(
                                icon: Icons.flash_on,
                                active: true,
                                size: 24,
                                radius: 4),
                            SizedBox(width: 4),
                            BadgeTile(
                                icon: Icons.favorite,
                                active: false,
                                size: 24,
                                radius: 4),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            BadgeTile(
                                icon: Icons.lock,
                                active: false,
                                size: 24,
                                radius: 4),
                            SizedBox(width: 4),
                            BadgeTile(
                                icon: Icons.settings,
                                active: false,
                                size: 24,
                                radius: 4),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // INFORMACION DEL USUARIO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$username ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  TextSpan(
                                    text: identifier,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _showPostOptions(context),
                            borderRadius: BorderRadius.circular(20),
                            splashColor: Colors.grey.withOpacity(0.2),
                            child: const Icon(Icons.more_vert,
                                size: 20, color: Colors.grey),
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      _ExpandableText(text: content),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (imageUrl != null && imageUrl!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                // AQUI SE DEBE PONER LA URL DE LA IMAGEN QUE SE ENVIO EN EL POST SI HAY UNA
                child: Image.network(
                  imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: SizedBox(
                        height: 180,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.grey[500]!),
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Icon(Icons.broken_image,
                            size: 40, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _PostActions(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  //OPCIONES DEL POST BOTON DE LOS 3 PUNTITOS
  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: const Text('Guardar publicacion'),
                onTap: () {
                  Navigator.pop(ctx);
                  // AQUI IRA LA LOGICA PARA GUARDAR LA PUBLICACION EN EL FUTURO
                },
              ),
              // FILTRO PARA COLOCAR SI ELIMINAR LA PUBLICACION CUANDO ES PROPIA CUANDO SE MUESTREN EN EL PERFIL
              if (isMine)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text(
                    'Eliminar publicacion',
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await showDialog(
                      context: context,
                      builder: (dCtx) {
                        return AlertDialog(
                          title: const Text('Eliminar publicacion'),
                          content: const Text(
                              '¿Estos seguro que deseas eliminar esta publicacion? Esta acción no se puede deshacer.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                              onPressed: () {
                        //==== AQUI IRIA LA LOGICA PARA ELIMINAR LA PUBLICACION EN EL FUTURO (PUBLICACION PROPIA CLARO) =============
                                Navigator.pop(dCtx);
                              },
                              child: const Text('Eliminar'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}

//ACCIONES DEL POST ME GUSTA, COMENTAR Y COMPARTIR
class _PostActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
              child: _buildActionButton(
                  Icons.thumb_up_outlined, 'Me gusta', () {})),
          Expanded(
              child: _buildActionButton(
                  Icons.chat_bubble_outline, 'Comentar', () {})),
          Expanded(
              child:
                  _buildActionButton(Icons.share_outlined, 'Compartir', () {})),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: Colors.grey.withOpacity(0.2),
        highlightColor: Colors.grey.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// CLASE PARA EL TEXTO EXPANDIBLE
class _ExpandableText extends StatefulWidget {
  const _ExpandableText({
    required this.text,
    // ignore: unused_element
    this.trimLength = 147,
  });

  final String text;
  final int trimLength;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;
  late TapGestureRecognizer _moreRecognizer;
  late TapGestureRecognizer _lessRecognizer;

  @override
  void initState() {
    super.initState();
    _moreRecognizer = TapGestureRecognizer()..onTap = _expand;
    _lessRecognizer = TapGestureRecognizer()..onTap = _collapse;
  }

  void _expand() => setState(() => _expanded = true);
  void _collapse() => setState(() => _expanded = false);

  @override
  void dispose() {
    _moreRecognizer.dispose();
    _lessRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontSize: 16,
      height: 1.5,
      color: Colors.black87,
    );

    final fullText = widget.text.trim();
    if (fullText.length <= widget.trimLength) {
      return Text(fullText, style: baseStyle);
    }

    if (_expanded) {
      return RichText(
        text: TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: fullText),
            const TextSpan(text: ' '),
            TextSpan(
              text: 'Ver menos',
              style: baseStyle.copyWith(color: Colors.blue),
              recognizer: _lessRecognizer,
            ),
          ],
        ),
      );
    }

    final visible = fullText.substring(0, widget.trimLength).trimRight();
    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: '$visible... '),
          TextSpan(
            text: 'Ver mas',
            style: baseStyle.copyWith(color: Colors.blue),
            recognizer: _moreRecognizer,
          ),
        ],
      ),
    );
  }
}
