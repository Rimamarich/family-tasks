import 'database_helper.dart';

/// Représente un moment de la journée.
class Moment {
  const Moment({
    this.id,
    required this.name,
    required this.heureDeFin,
  });

  final int? id;
  final String name;
  final String heureDeFin;
}

/// Service gérant les opérations sur la table moments.
class MomentService {
  /// Récupère tous les moments, triés par heure de fin.
  static Future<List<Moment>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query('moments', orderBy: 'heure_de_fin ASC');
    return results.map((row) => Moment(
      id: row['id'] as int,
      name: row['name'] as String,
      heureDeFin: row['heure_de_fin'] as String,
    )).toList();
  }

  /// Ajoute un moment.
  static Future<int> insert(Moment moment) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('moments', {
      'name': moment.name,
      'heure_de_fin': moment.heureDeFin,
    });
  }

  /// Met à jour un moment.
  static Future<int> update(Moment moment) async {
    final db = await DatabaseHelper.instance.database;
    return db.update(
      'moments',
      {'name': moment.name, 'heure_de_fin': moment.heureDeFin},
      where: 'id = ?',
      whereArgs: [moment.id],
    );
  }

  /// Supprime un moment.
  static Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete('moments', where: 'id = ?', whereArgs: [id]);
  }

  /// Compte les tâches liées à un moment.
  static Future<int> countTasks(int momentId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE moment_id = ?',
      [momentId],
    );
    return result.first['count'] as int? ?? 0;
  }

  /// Déplace les tâches d'un moment vers un autre.
  static Future<void> moveTasks(int fromMomentId, int toMomentId) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'tasks',
      {'moment_id': toMomentId},
      where: 'moment_id = ?',
      whereArgs: [fromMomentId],
    );
  }

  /// Vérifie si une heure de fin est déjà utilisée par un autre moment.
  static Future<bool> isHeureDeFinTaken(String heureDeFin, {int? excludeId}) async {
    final db = await DatabaseHelper.instance.database;

    if (excludeId != null) {
      final result = await db.query(
        'moments',
        where: 'heure_de_fin = ? AND id != ?',
        whereArgs: [heureDeFin, excludeId],
      );
      return result.isNotEmpty;
    } else {
      final result = await db.query(
        'moments',
        where: 'heure_de_fin = ?',
        whereArgs: [heureDeFin],
      );
      return result.isNotEmpty;
    }
  }
}