/// Représente une tâche dans l'application Family Tasks.
class TaskItem {
  const TaskItem({
    this.id,
    required this.title,
    required this.stars,
    this.momentId,
    this.moment,
    this.description,
    this.completed = false,
    this.taskDate,
  });

  /// Identifiant unique dans la base de données.
  final int? id;

  final String title;
  final int stars;

  /// ID du moment (venant de la base de données).
  final int? momentId;

  /// Nom du moment (pour l'affichage, pas stocké en base).
  final String? moment;

  final String? description;
  final bool completed;

  /// Date de la tâche au format YYYY-MM-DD.
  final String? taskDate;

  /// Crée une copie avec des champs modifiés.
  TaskItem copyWith({
    int? id,
    String? title,
    int? stars,
    int? momentId,
    String? moment,
    String? description,
    bool? completed,
    String? taskDate,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      stars: stars ?? this.stars,
      momentId: momentId ?? this.momentId,
      moment: moment ?? this.moment,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      taskDate: taskDate ?? this.taskDate,
    );
  }
}