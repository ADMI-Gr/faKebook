import 'package:flutter/material.dart';

////// TARJETA DE FOLLOW/UNFOLLOW
class FollowTile extends StatelessWidget {
  const FollowTile({
    super.key,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.following,
    required this.onTap,
    required this.onToggleFollow,
  });

  final String name;
  final String username;
  final String? avatarUrl;
  final bool following;
  final VoidCallback onTap;
  final VoidCallback onToggleFollow;

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1976D2);

    return InkWell(
      onTap: onTap, // Base de navegacion al perfil (pendiente)
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: primaryBlue,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    username,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: following ? Colors.grey.shade200 : primaryBlue,
                foregroundColor: following ? Colors.black : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onToggleFollow,
              child: Text(following ? 'Siguiendo' : 'Seguir'),
            ),
            const SizedBox(width: 8),

            // MENU PARA BLOQUEAR AL USUARIO
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'block') {
                  final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Bloquear usuario'),
                          content: Text('¿Quieres bloquear a $username?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                              child: const Text('Bloquear'),
                            ),
                          ],
                        ),
                      ) ??
                      false;

                  if (confirmed) {
                    // AQUI IRIA LA LOGICA PARA BLOQUEAR AL USUARIO QUE AUN NO SE COMO LA IMPLEMENTARAN
                    // SUPONGO QUE IGUALMENTE MEDIANTE EL @ (username) posteriormente se cambia de lo contrario
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Has bloqueado a $username (demo)')),
                    );
                  }
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'block',
                  child: Text('Bloquear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}