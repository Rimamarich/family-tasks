import 'dart:io';
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
  /// Au premier lancement, copie la base pré-remplie depuis les assets.
  /// En production, cette étape sera remplacée par une création de base vide.
  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'family-tasks.db');

    // Vérifie si la base existe déjà
    final exists = await databaseExists(path);

    if (!exists) {
      // Copie la base pré-remplie depuis les assets (développement)
      final data = await rootBundle.load('assets/family-tasks.db');
      final bytes = data.buffer.asUint8List();
      await File(path).writeAsBytes(bytes);
    }

    _database = await openDatabase(
      path,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );

    return _database!;
  }
}