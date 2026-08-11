import 'package:flutter/material.dart';
import 'screens/family_screen.dart';

/// Configuration générale de l'application Family Tasks.
///
/// Définit le thème, le titre et la page d'accueil.
class FamilyTasksApp extends StatelessWidget {
  const FamilyTasksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Tasks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const FamilyScreen(),
    );
  }
}