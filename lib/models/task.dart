/// Représente une tâche dans l'application Family Tasks.
///
/// Une tâche est une occurrence concrète issue du fichier ICS.
/// Elle appartient à un membre, pour un moment donné de la journée.
class TaskItem {
  const TaskItem({
    required this.title,
    required this.stars,
    required this.moment,
    this.description,
    this.completed = false,
  });

  /// Titre de la tâche (ex: "Ranger la cuisine")
  final String title;

  /// Nombre d'étoiles gagnées en validant la tâche
  final int stars;

  /// Moment de la journée (ex: "Matin", "Soirée")
  final String moment;

  /// Description optionnelle (ex: "Mettre les affaires à leur place")
  final String? description;

  /// Indique si la tâche est terminée
  final bool completed;
}