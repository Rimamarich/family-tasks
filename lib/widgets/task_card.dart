import 'package:flutter/material.dart';
import '../models/task.dart';

/// Carte affichant une tâche dans la colonne d'un membre.
///
/// Affiche le titre, la description éventuelle, le nombre d'étoiles
/// et permet de valider/dévalider la tâche en tapant dessus.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.memberColor,
    required this.onToggle,
  });

  /// La tâche à afficher
  final TaskItem task;

  /// Couleur associée au membre (utilisée pour les icônes et le fond)
  final Color memberColor;

  /// Fonction appelée quand on tape sur la carte ou sur l'étoile
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    // Couleur du texte et des icônes : plus claire si la tâche est terminée
    final foregroundColor =
        task.completed ? memberColor.withValues(alpha: 0.55) : memberColor;

    // Couleur de fond : plus légère si la tâche est terminée
    final backgroundColor = task.completed
        ? memberColor.withValues(alpha: 0.08)
        : memberColor.withValues(alpha: 0.18);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Titre et description ----
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: foregroundColor,
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    // Affiche la description uniquement si elle existe
                    if (task.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: foregroundColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ---- Étoiles ----
              InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        task.completed
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 27,
                        color: foregroundColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${task.stars}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: foregroundColor,
                        ),
                      ),
                    ],
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