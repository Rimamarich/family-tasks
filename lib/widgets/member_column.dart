import 'package:flutter/material.dart';
import '../models/member.dart';
import '../models/task.dart';
import 'task_card.dart';

/// Colonne affichant un membre et ses tâches.
///
/// Affiche l'en-tête du membre (avatar, nom, étoiles) puis la liste
/// de ses tâches regroupées par moment de la journée.
class MemberColumn extends StatelessWidget {
  const MemberColumn({
    super.key,
    required this.member,
    required this.moments,
    required this.currentMoment,
    required this.onToggleTask,
  });

  /// Le membre à afficher
  final FamilyMember member;

  /// Liste des moments de la journée (ex: "Matin", "Soirée"...)
  final List<String> moments;

  /// Le moment actuel de la journée (pour ouvrir la bonne section)
  final String currentMoment;

  /// Fonction appelée quand on valide/dévalide une tâche
  /// Reçoit l'index de la tâche dans la liste des tâches du membre
  final void Function(int taskIndex) onToggleTask;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: member.color.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          _buildMemberHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              children: [
                for (final moment in moments)
                  _buildMomentSection(context, moment),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// En-tête avec l'avatar, le nom et le solde d'étoiles
  Widget _buildMemberHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: member.color.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: member.color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              member.avatar,
              style: const TextStyle(fontSize: 27),
            ),
          ),
          const SizedBox(width: 10),

          // Nom
          Expanded(
            child: Text(
              member.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Étoiles
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                size: 22,
                color: member.color,
              ),
              const SizedBox(width: 3),
              Text(
                '${member.stars}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Section regroupant les tâches d'un moment donné
  Widget _buildMomentSection(BuildContext context, String moment) {
    // Récupère les tâches de ce moment avec leur index d'origine
    final tasks = <MapEntry<int, TaskItem>>[];
    for (var index = 0; index < member.tasks.length; index++) {
      if (member.tasks[index].moment == moment) {
        tasks.add(MapEntry(index, member.tasks[index]));
      }
    }

    final isCurrent = moment == currentMoment;

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        initiallyExpanded: isCurrent,
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        childrenPadding: const EdgeInsets.only(bottom: 4),
        title: Text(
          moment,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
            color: isCurrent ? member.color : Colors.grey.shade700,
          ),
        ),
        trailing: Icon(
          isCurrent
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
        ),
        children: [
          for (final entry in tasks)
            TaskCard(
              task: entry.value,
              memberColor: member.color,
              onToggle: () => onToggleTask(entry.key),
            ),
        ],
      ),
    );
  }
}