import 'package:flutter/material.dart';
import '../models/member.dart';
import 'database_helper.dart';

/// Service gérant les opérations sur la table members.
class MemberService {
  static Future<List<FamilyMember>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query('members');
    return results.map((row) => _rowToMember(row)).toList();
  }

  static Future<List<FamilyMember>> getActive() async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query('members', where: 'pause = 0');
    return results.map((row) => _rowToMember(row)).toList();
  }

  static Future<int> insert(FamilyMember member) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('members', _memberToRow(member));
  }

  static Future<int> update(FamilyMember member) async {
    final db = await DatabaseHelper.instance.database;
    return db.update(
      'members',
      _memberToRow(member),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  static Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updateStars(int id, int stars) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('members', {'stars': stars}, where: 'id = ?', whereArgs: [id]);
  }

  static FamilyMember _rowToMember(Map<String, dynamic> row) {
    return FamilyMember(
      id: row['id'] as int,
      name: row['name'] as String,
      avatar: row['avatar'] as String,
      color: _parseColor(row['color'] as String),
      stars: row['stars'] as int,
      pause: (row['pause'] as int) == 1,
    );
  }

  static Map<String, dynamic> _memberToRow(FamilyMember member) {
    return {
      if (member.id != null) 'id': member.id,
      'name': member.name,
      'avatar': member.avatar,
      'color': _colorToString(member.color),
      'stars': member.stars,
      'pause': member.pause ? 1 : 0,
    };
  }

  static Color _parseColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'pink':
        return Colors.pink;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      default:
        return Colors.blue;
    }
  }

  static String _colorToString(Color color) {
    if (color == Colors.green) return 'green';
    if (color == Colors.pink) return 'pink';
    if (color == Colors.orange) return 'orange';
    if (color == Colors.purple) return 'purple';
    if (color == Colors.red) return 'red';
    if (color == Colors.teal) return 'teal';
    if (color == Colors.indigo) return 'indigo';
    return 'blue';
  }
}