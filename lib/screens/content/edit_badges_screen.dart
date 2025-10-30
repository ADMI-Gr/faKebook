import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fakebook/providers/badge_provider.dart';
import 'package:fakebook/models/badge_model.dart';
import 'package:fakebook/widgets/badge_widget.dart';

class EditBadgesScreen extends ConsumerStatefulWidget {
  final String userId;

  const EditBadgesScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<EditBadgesScreen> createState() => _EditBadgesScreenState();
}

class _EditBadgesScreenState extends ConsumerState<EditBadgesScreen> {
  List<String> selectedBadgeIds = [];
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final allUserBadgesAsync =
        ref.watch(userAllBadgeModelsProvider(widget.userId));
    final featuredBadgesAsync =
        ref.watch(userFeaturedBadgesProvider(widget.userId));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Editar insignias destacadas'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: selectedBadgeIds.isEmpty ? null : _saveBadges,
              child: const Text(
                'Guardar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: featuredBadgesAsync.when(
        data: (featuredIds) {
          if (selectedBadgeIds.isEmpty && featuredIds.isNotEmpty) {
            selectedBadgeIds = List.from(featuredIds);
          }

          return allUserBadgesAsync.when(
            data: (allBadges) {
              if (allBadges.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.workspace_premium_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes insignias disponibles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Las insignias se asignan desde la plataforma',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selecciona hasta 6 insignias',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Estas aparecerán en tu perfil y en tus publicaciones',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tus insignias',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: selectedBadgeIds.length >= 6
                                  ? Colors.red[100]
                                  : Colors.green[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${selectedBadgeIds.length}/6 seleccionadas',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selectedBadgeIds.length >= 6
                                    ? Colors.red[900]
                                    : Colors.green[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: allBadges.map((badge) {
                          final isSelected =
                              selectedBadgeIds.contains(badge.id);
                          final canSelect =
                              selectedBadgeIds.length < 6 || isSelected;

                          return GestureDetector(
                            onTap: canSelect
                                ? () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedBadgeIds.remove(badge.id);
                                      } else {
                                        selectedBadgeIds.add(badge.id);
                                      }
                                    });
                                  }
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Solo puedes destacar hasta 6 insignias'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Opacity(
                                  opacity: canSelect ? 1.0 : 0.3,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.green
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                    child: BadgeWidget(
                                      badge: badge,
                                      size: 56,
                                      radius: 12,
                                      showDialog: false,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: -6,
                                    right: -6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      if (selectedBadgeIds.isNotEmpty) ...[
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'Vista previa',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Así se verán en tu perfil:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 12),
                              BadgeGrid(
                                badges: allBadges
                                    .where(
                                        (b) => selectedBadgeIds.contains(b.id))
                                    .toList(),
                                badgeSize: 48,
                                spacing: 12,
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar insignias',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Future<void> _saveBadges() async {
    if (selectedBadgeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una insignia'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await ref.read(updateFeaturedBadgesProvider((
        userId: widget.userId,
        badgeIds: selectedBadgeIds,
      )).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insignias destacadas actualizadas'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
