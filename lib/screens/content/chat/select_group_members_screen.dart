import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/providers/social_provider.dart';
import 'package:fakebook/providers/chat_providers.dart';
import 'package:fakebook/models/user_model.dart';
import 'create_group_screen.dart';

// PANTALLA DE SELECCIONAR MIEMBROS PARA UN GRUPO
class SelectGroupMembersScreen extends ConsumerStatefulWidget {
  const SelectGroupMembersScreen({
    super.key,
    this.isAddingToGroup = false,
    this.conversationId,
    this.excludeUserIds,
  });

  final bool isAddingToGroup;
  final String? conversationId;
  final Set<String>? excludeUserIds;

  @override
  ConsumerState<SelectGroupMembersScreen> createState() =>
      _SelectGroupMembersScreenState();
}

class _SelectGroupMembersScreenState
    extends ConsumerState<SelectGroupMembersScreen> {
  final Set<String> _selected = <String>{};
  String _query = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final followingAsync = ref.watch(followingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isAddingToGroup ? 'Agregar miembros' : 'Seleccionar miembros',
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar personas que sigues',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: followingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (users) {
                List<UserModel> list = users;

                // Filtrar usuarios que ya están en el grupo
                if (widget.isAddingToGroup && widget.excludeUserIds != null) {
                  list = list
                      .where((u) => !widget.excludeUserIds!.contains(u.id))
                      .toList();
                }

                // Filtrar por búsqueda
                if (_query.isNotEmpty) {
                  list = list.where((u) {
                    final name = (u.displayName ?? u.username).toLowerCase();
                    return name.contains(_query);
                  }).toList();
                }

                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      widget.isAddingToGroup
                          ? 'No hay más usuarios para agregar'
                          : 'No sigues a nadie todavía',
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (_, i) {
                    final u = list[i];
                    final checked = _selected.contains(u.id);
                    final title = u.displayName ?? u.username;
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selected.add(u.id);
                          } else {
                            _selected.remove(u.id);
                          }
                        });
                      },
                      title: Text(title),
                      subtitle: Text('@${u.username}'),
                      secondary: CircleAvatar(
                        backgroundImage:
                            (u.avatarUrl != null && u.avatarUrl!.isNotEmpty)
                                ? NetworkImage(u.avatarUrl!)
                                : null,
                        child: (u.avatarUrl == null || u.avatarUrl!.isEmpty)
                            ? Text(
                                title.isNotEmpty ? title[0].toUpperCase() : '?')
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton.icon(
            onPressed: _isLoading
                ? null
                : (widget.isAddingToGroup
                    ? (_selected.isNotEmpty ? _addMembersToGroup : null)
                    : (_selected.length >= 2 ? _continueToCreateGroup : null)),
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.arrow_forward),
            label: Text(_isLoading
                ? 'Procesando...'
                : widget.isAddingToGroup
                    ? (_selected.isEmpty
                        ? 'Selecciona al menos 1'
                        : 'Agregar (${_selected.length})')
                    : (_selected.isEmpty
                        ? 'Selecciona al menos 2'
                        : 'Continuar (${_selected.length})')),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Theme.of(context).colorScheme.primary,
              disabledForegroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }

  void _continueToCreateGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateGroupScreen(memberIds: _selected.toList()),
      ),
    );
  }

  Future<void> _addMembersToGroup() async {
    if (widget.conversationId == null) return;

    setState(() => _isLoading = true);

    try {
      // Agregar cada miembro seleccionado
      for (final userId in _selected) {
        ref.read(addParticipantProvider.notifier).add(
              conversationId: widget.conversationId!,
              profileId: userId,
            );
      }

      // Invalidar los providers para refrescar la información
      ref.invalidate(participantsProvider(widget.conversationId!));

      if (!mounted) return;

      // Volver a la pantalla anterior y mostrar mensaje de éxito
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selected.length == 1
                ? '1 miembro agregado exitosamente'
                : '${_selected.length} miembros agregados exitosamente',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar miembros: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
