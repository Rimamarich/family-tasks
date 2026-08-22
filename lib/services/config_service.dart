import 'database_helper.dart';

/// Service gérant les opérations sur la table config.
class ConfigService {
  /// Récupère la configuration (une seule ligne).
  static Future<Map<String, dynamic>?> get() async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query('config', limit: 1);
    if (results.isEmpty) return null;
    return results.first;
  }

  /// Récupère l'URL ICS.
  static Future<String?> getIcsUrl() async {
    final config = await get();
    return config?['ics_url'] as String?;
  }

  /// Récupère le code PIN parental.
  static Future<String?> getParentPin() async {
    final config = await get();
    return config?['parent_pin'] as String?;
  }

  /// Récupère le nombre de réjouissances obtenues à afficher.
  static Future<int> getMaxObtenues() async {
    final config = await get();
    return config?['max_obtenues'] as int? ?? 3;
  }

  /// Récupère les 5 messages d'encouragement.
  static Future<List<String>> getMessages() async {
    final config = await get();
    if (config == null) {
      return [
        'Tu es un champion ! 🏆',
        'Quelle journée productive ! 🌟',
        'Tu peux être fier de toi ! 💪',
        'Bravo, continue comme ça ! 🎉',
        'Tu as assuré aujourd\'hui ! ⭐',
      ];
    }
    return [
      config['message_1'] as String? ?? 'Tu es un champion ! 🏆',
      config['message_2'] as String? ?? 'Quelle journée productive ! 🌟',
      config['message_3'] as String? ?? 'Tu peux être fier de toi ! 💪',
      config['message_4'] as String? ?? 'Bravo, continue comme ça ! 🎉',
      config['message_5'] as String? ?? 'Tu as assuré aujourd\'hui ! ⭐',
    ];
  }

  /// Met à jour l'URL ICS.
  static Future<void> setIcsUrl(String url) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('config', {'ics_url': url}, where: 'id = 1');
  }

  /// Met à jour le code PIN parental.
  static Future<void> setParentPin(String pin) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('config', {'parent_pin': pin}, where: 'id = 1');
  }

  /// Met à jour le nombre de réjouissances obtenues à afficher.
  static Future<void> setMaxObtenues(int value) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('config', {'max_obtenues': value}, where: 'id = 1');
  }

  /// Met à jour les 5 messages d'encouragement.
  static Future<void> setMessages(List<String> messages) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('config', {
      'message_1': messages.length > 0 ? messages[0] : '',
      'message_2': messages.length > 1 ? messages[1] : '',
      'message_3': messages.length > 2 ? messages[2] : '',
      'message_4': messages.length > 3 ? messages[3] : '',
      'message_5': messages.length > 4 ? messages[4] : '',
    }, where: 'id = 1');
  }
}