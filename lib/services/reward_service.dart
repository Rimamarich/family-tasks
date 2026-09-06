import 'database_helper.dart';

/// Représente une récompense.
class Reward {
  const Reward({
    this.id,
    required this.title,
    required this.cost,
    this.uniqueReward = false,
    this.requiresNote = false,
    this.active = true,
  });

  final int? id;
  final String title;
  final int cost;
  final bool uniqueReward;
  final bool requiresNote;
  final bool active;
}

/// Représente une contribution d'un membre à une récompense.
class RewardContribution {
  const RewardContribution({
    this.id,
    required this.rewardId,
    required this.memberId,
    required this.stars,
    this.redemptionId,
  });

  final int? id;
  final int rewardId;
  final int memberId;
  final int stars;
  final int? redemptionId;
}

/// Représente une récompense obtenue.
class Redemption {
  const Redemption({
    this.id,
    required this.rewardId,
    required this.stars,
    this.note,
    required this.createdAt,
  });

  final int? id;
  final int rewardId;
  final int stars;
  final String? note;
  final String createdAt;
}

/// Service gérant les opérations sur les tables rewards,
/// reward_contributions et redemptions.
class RewardService {
  // ---- Récompenses ----

  static Future<List<Reward>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query('rewards');
    return results.map((row) => Reward(
      id: row['id'] as int,
      title: row['title'] as String,
      cost: row['cost'] as int,
      uniqueReward: (row['unique_reward'] as int) == 1,
      requiresNote: (row['requires_note'] as int) == 1,
      active: (row['active'] as int? ?? 1) == 1,
    )).toList();
  }

  static Future<int> insert(Reward reward) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('rewards', {
      'title': reward.title,
      'cost': reward.cost,
      'unique_reward': reward.uniqueReward ? 1 : 0,
      'requires_note': reward.requiresNote ? 1 : 0,
      'active': reward.active ? 1 : 0,
    });
  }

  static Future<int> update(Reward reward) async {
    final db = await DatabaseHelper.instance.database;
    return db.update('rewards', {
      'title': reward.title,
      'cost': reward.cost,
      'unique_reward': reward.uniqueReward ? 1 : 0,
      'requires_note': reward.requiresNote ? 1 : 0,
      'active': reward.active ? 1 : 0,
    }, where: 'id = ?', whereArgs: [reward.id]);
  }

  /// Supprime une récompense et toutes ses dépendances.
  static Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('reward_contributions', where: 'reward_id = ?', whereArgs: [id]);
    await db.delete('redemptions', where: 'reward_id = ?', whereArgs: [id]);
    return db.delete('rewards', where: 'id = ?', whereArgs: [id]);
  }

  /// Réactive une récompense unique (la rend visible).
  static Future<void> reactivate(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('rewards', {'active': 1}, where: 'id = ?', whereArgs: [id]);
  }

  /// Désactive une récompense unique (la masque).
  static Future<void> deactivate(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('rewards', {'active': 0}, where: 'id = ?', whereArgs: [id]);
  }

  // ---- Contributions ----

  static Future<List<RewardContribution>> getContributions(int rewardId) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'reward_contributions',
      where: 'reward_id = ?',
      whereArgs: [rewardId],
    );
    return results.map((row) => RewardContribution(
      id: row['id'] as int,
      rewardId: row['reward_id'] as int,
      memberId: row['member_id'] as int,
      stars: row['stars'] as int,
      redemptionId: row['redemption_id'] as int?,
    )).toList();
  }

  static Future<int> addContribution(int rewardId, int memberId, int stars) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('reward_contributions', {
      'reward_id': rewardId,
      'member_id': memberId,
      'stars': stars,
      'redemption_id': null,
    });
  }

  // ---- Récompenses obtenues ----

  static Future<int> redeem(int rewardId, int cost, String? note) async {
    final db = await DatabaseHelper.instance.database;

    final redemptionId = await db.insert('redemptions', {
      'reward_id': rewardId,
      'stars': cost,
      'note': note ?? '',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.update(
      'reward_contributions',
      {'redemption_id': redemptionId},
      where: 'reward_id = ? AND redemption_id IS NULL',
      whereArgs: [rewardId],
    );

    return redemptionId;
  }

  static Future<List<Redemption>> getRecentRedemptions(int limit) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'redemptions',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return results.map((row) => Redemption(
      id: row['id'] as int,
      rewardId: row['reward_id'] as int,
      stars: row['stars'] as int,
      note: row['note'] as String?,
      createdAt: row['created_at'] as String,
    )).toList();
  }
}