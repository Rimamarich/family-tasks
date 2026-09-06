import 'package:flutter/material.dart';
import 'task.dart';

/// Représente un membre de la famille.
class FamilyMember {
  const FamilyMember({
    this.id,
    required this.name,
    required this.avatar,
    required this.color,
    required this.stars,
    this.tasks = const [],
    this.pause = false,
  });

  /// Identifiant unique dans la base de données.
  /// null si le membre n'a pas encore été inséré.
  final int? id;

  final String name;
  final String avatar;
  final Color color;
  final int stars;
  final List<TaskItem> tasks;
  final bool pause;

  /// Crée une copie du membre avec des champs modifiés.
  FamilyMember copyWith({
    int? id,
    String? name,
    String? avatar,
    Color? color,
    int? stars,
    List<TaskItem>? tasks,
    bool? pause,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      color: color ?? this.color,
      stars: stars ?? this.stars,
      tasks: tasks ?? this.tasks,
      pause: pause ?? this.pause,
    );
  }
}