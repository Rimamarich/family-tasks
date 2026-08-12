import 'package:flutter/material.dart';

/// Barre de navigation inférieure avec 3 onglets.
///
/// Affiche les icônes Tâches, Réjouissances et Paramètres.
/// Réutilisable dans toute l'application.
class BottomMenu extends StatelessWidget {
  const BottomMenu({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  /// Index de l'onglet actif (0 = Tâches, 1 = Réjouissances, 2 = Paramètres)
  final int currentIndex;

  /// Appelée quand un onglet est sélectionné
  final void Function(int index) onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          _buildTab(
            index: 0,
            icon: Icons.home_rounded,
            label: 'Tâches',
            context: context,
          ),
          _buildTab(
            index: 1,
            icon: Icons.emoji_events_rounded,
            label: 'Réjouissances',
            context: context,
          ),
          _buildTab(
            index: 2,
            icon: Icons.settings_rounded,
            label: 'Paramètres',
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required IconData icon,
    required String label,
    required BuildContext context,
  }) {
    final isActive = index == currentIndex;

    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: isActive
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade500,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}