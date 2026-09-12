import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Gestionnaire de la base de données SQLite.
///
/// Responsable de l'ouverture de la base et de l'activation
/// des clés étrangères. Tous les services passent par cette classe
/// pour obtenir une connexion.
class DatabaseHelper {
  static DatabaseHelper? _instance;
  Database? _database;

  DatabaseHelper._();

  /// Retourne l'instance unique du helper.
  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  /// Ouvre la base de données.
  ///
  /// Au premier lancement, crée les tables à partir du fichier
  /// `database/schema.sql` embarqué dans l'application.
  /// Aux lancements suivants, ouvre simplement la base existante.
  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'family-tasks.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );

    return _database!;
  }

  /// Crée les tables de la base à partir du fichier `schema.sql`,
  /// puis insère la ligne de configuration par défaut.
  ///
  /// N'est appelée qu'une seule fois : à la toute première ouverture
  /// de la base sur un appareil.
  Future<void> _onCreate(Database db, int version) async {
    // Lit le fichier schema.sql depuis les assets
    final schemaSql = await rootBundle.loadString('database/schema.sql');

    // Découpe en instructions séparées par ';'
    // et retire les commentaires (lignes commençant par '--')
    final statements = schemaSql
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !s.startsWith('--'))
        .toList();

    // Exécute chaque instruction
    for (final statement in statements) {
      await db.execute(statement);
    }

    // Insère la ligne de configuration par défaut
    // (id = 1, code PIN par défaut, URL ICS vide)
    await db.insert('config', {
      'id': 1,
      'parent_pin': '0000',
      'ics_url': '',
    });
  }
}