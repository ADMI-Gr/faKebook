import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fakebook/providers/auth_provider.dart';
import 'package:fakebook/providers/chat_providers.dart';
import 'package:fakebook/providers/chat_providers.dart' show chatRepositoryProvider;
import 'package:fakebook/providers/social_provider.dart';
import 'group_chat_detail_screen.dart';

//==== PANTALLA DE CREAR UN NUEVO GRUPO Y EDITAR UN GRUPO ====
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({
    super.key,
    required this.memberIds,
    this.isEdit = false,
    this.initialTitle,
    this.initialDescription,
    this.initialAvatarUrl,
    this.conversationId,
  });
  final List<String> memberIds; 
  final bool isEdit;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialAvatarUrl;
  final String? conversationId;

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _avatarUrl; 
  String? _avatarLocalPath; 
  bool _uploadingAvatar = false;
  bool _creating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _edit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _creating = true);
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grupo editado (demo)')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // Prefill si es modo ediciOn
    if (widget.isEdit) {
      _nameCtrl.text = widget.initialTitle ?? '';
      _descCtrl.text = widget.initialDescription ?? '';
      _avatarUrl = widget.initialAvatarUrl;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;

    try {
      setState(() {
        _avatarLocalPath = picked.path;
        _uploadingAvatar = true;
      });
      final socialRepo = ref.read(socialRepositoryProvider);
      final file = File(picked.path);
      final fileName = 'group_${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final filePath = 'groups/$fileName';
      final url = await socialRepo.uploadImage(file, filePath);
      setState(() {
        _avatarUrl = url;
        _uploadingAvatar = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir imagen: $e')));
      setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(userProvider);
    if (user == null) return;

    setState(() => _creating = true);
    try {
      // Construir metadata con admins: [creador]
      final metadata = {
        'title': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'avatarUrl': _avatarUrl ?? '',
        'admins': [user.id],
      };

      // Participantes: creador + miembros seleccionados
      final participantIds = <String>{user.id, ...widget.memberIds}.toList();

      final chatRepo = ref.read(chatRepositoryProvider);
      final created = await chatRepo.createConversation(
        kind: 'group',
        metadata: metadata,
        participantIds: participantIds,
      );

      if (!mounted) return;
      ref.invalidate(userConversationsProvider(user.id));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => GroupChatDetailScreen(
            conversationId: created.id,
            title: metadata['title'] as String,
            avatarUrl: metadata['avatarUrl'] as String,
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Editar grupo' : 'Nuevo grupo', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundImage: (_avatarLocalPath != null)
                          ? FileImage(File(_avatarLocalPath!)) as ImageProvider
                          : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                              ? NetworkImage(_avatarUrl!)
                              : null,
                      child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                          ? const Icon(Icons.group, size: 40)
                          : null,
                    ),
                    if (_uploadingAvatar)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.camera_alt, size: 20),
                          tooltip: 'Cambiar foto',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del grupo',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  // FUTURO METODO PARA CREAR O EDITAR EL GRUPO ACTUALMENTE SOLO ES DEMO EL EDITAR
                  onPressed: _creating ? null : (widget.isEdit ? _edit : _create),
                  icon: _creating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(widget.isEdit ? Icons.edit : Icons.check),
                  label: Text(_creating ? (widget.isEdit ? 'Guardando…' : 'Creando…') : (widget.isEdit ? 'Editar grupo' : 'Crear grupo')),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
