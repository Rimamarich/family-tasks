import 'package:flutter/material.dart';

/// Barre de navigation inférieure.
///
/// Réutilisable dans toutes les pages de l'application.
/// Pour le moment, elle affiche un placeholder "MENU".
/// Elle sera enrichie avec les icônes de navigation dans une version ultérieure.
class BottomMenu extends StatelessWidget {
  const BottomMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'MENU',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}