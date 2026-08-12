import 'package:flutter/material.dart';
import 'task.dart';

/// Représente un membre de la famille.
///
/// Un membre possède un nom, un avatar, une couleur, un solde d'étoiles
/// et la liste de ses tâches.
class FamilyMember {
  const FamilyMember({
    required this.name,
    required this.avatar,
    required this.color,
    required this.stars,
    required this.tasks,
    this.pause = false,
  });

  /// Nom affiché du membre
  final String name;

  /// Emoji utilisé comme avatar
  final String avatar;

  /// Couleur associée au membre (utilisée dans toute l'interface)
  final Color color;

  /// Solde actuel d'étoiles
  final int stars;

  /// Liste des tâches du membre
  final List<TaskItem> tasks;

  /// Indique si le membre est en pause / vacances
  final bool pause;
}