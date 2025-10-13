import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/post_model.dart';
import '../../../providers/social_provider.dart';

// ======== PAGINA PARA PUBLICAR UN POST ========
class PostPublishScreen extends ConsumerStatefulWidget {
  final PostModel? postToEdit;

  const PostPublishScreen({super.key, this.postToEdit});

  @override
  ConsumerState<PostPublishScreen> createState() => _PostPublishScreenState();
}

class _PostPublishScreenState extends ConsumerState<PostPublishScreen> {
  // MAXIMO DE CARACTERES Y IMAGENES
  static const int _maxChars = 280;
  static const int _maxImages = 1;
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];

  // Variables para manejar imágenes existentes en modo edición
  String? _existingImageUrl;
  bool _shouldDeleteExistingImage = false;

  bool _isPublishing = false;
  bool _publishSuccess = false;

  @override
  void initState() {
    super.initState();
    if (widget.postToEdit != null) {
      _textController.text = widget.postToEdit!.content ?? '';

      // Si el post tiene una imagen existente, la guardamos
      final imageUrl = widget.postToEdit!.contentJson['image_url'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        _existingImageUrl = imageUrl;
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickFromGallery() async {
    try {
      if (_images.length >= _maxImages) {
        _showSnack('Solo puedes seleccionar hasta $_maxImages imagen');
        return;
      }
      if (_existingImageUrl != null) {
        _showSnack('Solo puedes tener una imagen. Elimina la actual primero.');
        return;
      }
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
      if (photo != null) {
        setState(() => _images.add(photo));
      }
    } catch (e) {
      _showSnack('Ocurrio un error al intentar seleccionar la imagen');
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      if (_images.length >= _maxImages) {
        _showSnack('Solo puedes seleccionar hasta $_maxImages imagenes');
        return;
      }
      if (_existingImageUrl != null) {
        _showSnack('Solo puedes tener una imagen. Elimina la actual primero.');
        return;
      }
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() => _images.add(photo));
      }
    } catch (e) {
      _showSnack('Ocurrio un error al intentar abrir la camara');
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _removeExistingImage() {
    setState(() {
      _shouldDeleteExistingImage = true;
      _existingImageUrl = null;
    });
  }

  // FUNCION PARA PUBLICAR EL POST
  Future<void> _publish() async {
    final hasContent = _textController.text.trim().isNotEmpty;
    if (!hasContent) {
      _showSnack('Escribe algo para publicar');
      return;
    }

    setState(() => _isPublishing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final controller = AnimationController(
              vsync: Navigator.of(context),
              duration: const Duration(milliseconds: 600),
            );
            final animation = Tween<double>(begin: 0, end: -10).animate(
              CurvedAnimation(parent: controller, curve: Curves.easeInOut),
            );
            controller.repeat(reverse: true);
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 240,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                    0, animation.value * (index + 1) / 3),
                                child: child,
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Subiendo contenido',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Por favor espera un momento...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    try {
      if (widget.postToEdit == null) {
        // Crear nuevo post
        await ref.read(createPostProvider(
          (
            content: _textController.text.trim(),
            imageFile: _images.isNotEmpty ? _images.first : null,
          ),
        ).future);
      } else {
        // Editar post existente
        await ref.read(updatePostProvider(
          (
            postId: widget.postToEdit!.id,
            content: _textController.text.trim(),
            imageFile: _images.isNotEmpty ? _images.first : null,
            shouldDeleteExistingImage: _shouldDeleteExistingImage,
            existingImageUrl:
                widget.postToEdit!.contentJson['image_url'] as String?,
          ),
        ).future);
      }

      if (!mounted) return;

      setState(() {
        _textController.clear();
        _images.clear();
        _publishSuccess = true;
      });

      _showSnack(widget.postToEdit == null
          ? '¡Publicado con éxito!'
          : '¡Publicación actualizada!');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error al publicar: $e');
    } finally {
      if (mounted) {
        // Cerramos el diálogo de "cargando"
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isPublishing = false);
        if (_publishSuccess) {
          _publishSuccess = false;
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPublish = _textController.text.trim().isNotEmpty;
    final hasAnyImage = _images.isNotEmpty || _existingImageUrl != null;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Colors.black12, width: 0.5),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        leadingWidth: 96,
        leading: TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              setState(() {
                _textController.clear();
                _images.clear();
              });
              _showSnack('Publicacion cancelada');
            }
          },
          child: const Text(
            'Cancelar',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        title: Text(
          widget.postToEdit == null
              ? 'Nueva publicación'
              : 'Editar publicación',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: canPublish
                    ? const Color(0xFFF5F5F5)
                    : Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.6),
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: canPublish ? 2 : 0,
                
              ),
              onPressed: canPublish && !_isPublishing ? _publish : null,
              child: Text(
                widget.postToEdit == null ? 'Publicar' : 'Guardar',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Consumer(
                builder: (context, ref, _) {
                  final user = ref.watch(userProvider);
                  final avatarUrl = user?.avatarUrl;
                  final displayName = user?.displayName;
                  final username = user?.username;

                  final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
                  final initials =
                      (displayName != null && displayName.isNotEmpty)
                          ? displayName[0]
                          : (username != null && username.isNotEmpty
                                  ? username[0]
                                  : '?')
                              .toUpperCase();
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage:
                            hasAvatar ? NetworkImage(avatarUrl) : null,
                        backgroundColor:
                            hasAvatar ? Colors.transparent : Theme.of(context).colorScheme.primary,
                        child: hasAvatar
                            ? null
                            : Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (displayName != null && displayName.isNotEmpty)
                                  ? displayName
                                  : (username ?? 'Usuario'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              username != null ? '@$username' : '@usuario',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _textController,
                          maxLines: null,
                          maxLength: _maxChars,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: '¿Que estas pensando?',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            counterText:
                                '${_textController.text.length}/$_maxChars',
                            counterStyle:
                                const TextStyle(color: Colors.black38),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (hasAnyImage) _buildImageGrid(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildComposerBar(),
    );
  }

  Widget _buildComposerBar() {
    final hasAnyImage = _images.isNotEmpty || _existingImageUrl != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: hasAnyImage ? null : _pickFromGallery,
                icon: const Icon(Icons.image_rounded),
                label: const Text('Galería'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: hasAnyImage ? null : _pickFromCamera,
                icon: const Icon(Icons.photo_camera),
                label: const Text('Camara'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return Column(
      children: [
        // Mostrar imagen existente (si hay)
        if (_existingImageUrl != null) _buildExistingImageCard(),

        // Mostrar nuevas imágenes seleccionadas
        if (_images.isNotEmpty)
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final file = File(_images[index].path);
              return Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(file, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: InkWell(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildExistingImageCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _existingImageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
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
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 8),
                        Text('Error al cargar imagen'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: InkWell(
              onTap: _removeExistingImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_done, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Imagen actual',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
