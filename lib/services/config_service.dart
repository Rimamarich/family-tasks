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

  // ---- URL ICS ----

  /// Récupère l'URL ICS.
  static Future<String?> getIcsUrl() async {
    final config = await get();
    return config?['ics_url'] as String?;
  }

  /// Met à jour l'URL ICS.
  static Future<void> setIcsUrl(String url) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('config', {'ics_url': url}, where: 'id = 1');
  }

  // ---- Code PIN ----

  /// Récupère le code PIN parental.
  static Future<String?> getParentPin() async {
    final config = await get();
    return config?['parent_pin'] as String?;
  }

  /// Met à jour le code PIN parental.
  static Future<void> setParentPin(String pin) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('config', {'parent_pin': pin}, where: 'id = 1');
  }

  // ---- Réjouissances ----

  /// Récupère le nombre de réjouissances obtenues à afficher.
  static Future<int> getMaxObtenues() async {
    final config = await get();
    return config?['max_obtenues'] as int? ?? 3;
  }

  /// Récupère la limite maximale du nombre de réjouissances affichées.
  static Future<int> getMaxObtenuesLimit() async {
    final config = await get();
    return config?['max_obtenues_limit'] as int? ?? 50;
  }

  /// Met à jour le nombre de réjouissances obtenues à afficher.
  static Future<void> setMaxObtenues(int value) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('config', {'max_obtenues': value}, where: 'id = 1');
  }

  // ---- Messages d'encouragement ----

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

  // ---- Synchronisation ICS ----

  /// Récupère le nombre d'étoiles par défaut.
  static Future<int> getDefaultStars() async {
    final config = await get();
    return config?['default_stars'] as int? ?? 5;
  }

  /// Met à jour le nombre d'étoiles par défaut.
  static Future<void> setDefaultStars(int value) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('config', {'default_stars': value}, where: 'id = 1');
  }

  /// Vérifie si la configuration familiale est terminée.
  static Future<bool> isFamilyConfigured() async {
    final config = await get();
    return (config?['family_configured'] as int? ?? 0) == 1;
  }

  /// Met à jour l'état de la configuration familiale.
  static Future<void> setFamilyConfigured(bool value) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('config', {'family_configured': value ? 1 : 0}, where: 'id = 1');
  }

  /// Récupère le statut de la dernière synchronisation.
  /// Retourne un objet avec :
  /// - at      : date et heure ISO de la dernière tentative (ou null)
  /// - status  : 'success', 'partial', 'failed' ou null
  /// - message : message explicatif (ou null)
  static Future<Map<String, String?>> getLastSync() async {
    final config = await get();
    return {
      'at': config?['last_sync_at'] as String?,
      'status': config?['last_sync_status'] as String?,
      'message': config?['last_sync_message'] as String?,
    };
  }

  /// Met à jour le statut de la dernière synchronisation.
  static Future<void> setLastSync({
    required String at,
    required String status,
    String? message,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('config', {
      'last_sync_at': at,
      'last_sync_status': status,
      'last_sync_message': message,
    }, where: 'id = 1');
  }
}