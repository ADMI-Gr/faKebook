import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/providers/social_provider.dart';
import 'package:fakebook/models/user_model.dart';
import 'create_group_screen.dart';

// PANTALLA DE SELECCIONAR MIEMBROS PARA UN GRUPO
class SelectGroupMembersScreen extends ConsumerStatefulWidget {
  const SelectGroupMembersScreen({super.key});

  @override
  ConsumerState<SelectGroupMembersScreen> createState() => _SelectGroupMembersScreenState();
}

class _SelectGroupMembersScreenState extends ConsumerState<SelectGroupMembersScreen> {
  final Set<String> _selected = <String>{};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final followingAsync = ref.watch(followingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar miembros'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1976D2),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
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
                if (_query.isNotEmpty) {
                  list = users.where((u) {
                    final name = (u.displayName ?? u.username).toLowerCase();
                    return name.contains(_query);
                  }).toList();
                }
                if (list.isEmpty) {
                  return const Center(child: Text('No sigues a nadie todavía'));
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
                        backgroundImage: (u.avatarUrl != null && u.avatarUrl!.isNotEmpty)
                            ? NetworkImage(u.avatarUrl!)
                            : null,
                        child: (u.avatarUrl == null || u.avatarUrl!.isEmpty)
                            ? Text(title.isNotEmpty ? title[0].toUpperCase() : '?')
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
            onPressed: _selected.length >= 2
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateGroupScreen(memberIds: _selected.toList()),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.arrow_forward),
            label: Text(_selected.isEmpty
                ? 'Selecciona al menos 2'
                : 'Continuar (${_selected.length})'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF90CAF9),
              disabledForegroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }
}
