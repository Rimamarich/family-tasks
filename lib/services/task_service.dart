import '../models/task.dart';
import 'database_helper.dart';

/// Service gérant les opérations sur la table tasks.
class TaskService {
  /// Récupère toutes les tâches d'une date donnée.
  static Future<List<TaskItem>> getByDate(String date) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'tasks',
      where: 'task_date = ?',
      whereArgs: [date],
    );
    return results.map((row) => _rowToTask(row)).toList();
  }

  /// Récupère les tâches d'un membre pour une date donnée.
  static Future<List<TaskItem>> getByMemberAndDate(int memberId, String date) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'tasks',
      where: 'member_id = ? AND task_date = ?',
      whereArgs: [memberId, date],
    );
    return results.map((row) => _rowToTask(row)).toList();
  }

  /// Met à jour l'état completed d'une tâche.
  static Future<void> toggleComplete(int taskId, bool completed) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'tasks',
      {'completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// Convertit une ligne SQL en objet TaskItem.
  static TaskItem _rowToTask(Map<String, dynamic> row) {
    return TaskItem(
      id: row['id'] as int,
      title: row['title'] as String,
      stars: row['stars'] as int,
      momentId: row['moment_id'] as int,
      description: row['description'] as String?,
      completed: (row['completed'] as int) == 1,
      taskDate: row['task_date'] as String,
    );
  }
}