import 'package:flutter/material.dart';

/// Barre supérieure affichant la date, le moment actuel et la progression.
///
/// S'adapte à la largeur disponible en changeant de disposition :
/// - Écran large : date et progression côte à côte
/// - Écran étroit : date et progression empilées
///
/// En mode hauteur réduite (isCompact), le menu sandwich apparaît.
class HeaderWidget extends StatelessWidget {
  const HeaderWidget({
    super.key,
    required this.date,
    required this.currentMoment,
    required this.completedTasks,
    required this.totalTasks,
    required this.progress,
    this.isCompact = false,
    this.onMenuPressed,
  });

  final DateTime date;
  final String currentMoment;
  final int completedTasks;
  final int totalTasks;
  final double progress;
  final bool isCompact;
  final VoidCallback? onMenuPressed;

  static const _months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

  // Seuil en dessous duquel on empile au lieu de mettre côte à côte
  static const double _stackedWidthThreshold = 500;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < _stackedWidthThreshold;

        final hPadding = isCompact ? 10.0 : 12.0;
        final vPadding = isCompact ? 4.0 : 6.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(hPadding, vPadding, hPadding, 4),
          child: isStacked
              ? _buildStackedLayout()
              : _buildSideBySideLayout(),
        );
      },
    );
  }

  /// Layout empilé : date au-dessus, progression en dessous
  Widget _buildStackedLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildDateAndMoment()),
            if (isCompact) _buildMenuButton(),
          ],
        ),
        const SizedBox(height: 6),
        _buildProgress(),
      ],
    );
  }

  /// Layout côte à côte : date à gauche, progression à droite
  Widget _buildSideBySideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateAndMoment(),
        const SizedBox(width: 16),
        Expanded(child: _buildProgress()),
        if (isCompact) ...[
          const SizedBox(width: 8),
          _buildMenuButton(),
        ],
      ],
    );
  }

  /// Date et moment du jour
  Widget _buildDateAndMoment() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${date.day} ${_months[date.month - 1]} ${date.year}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          currentMoment,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// Barre de progression avec titre et compteur
  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Progression de la famille',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$completedTasks / $totalTasks',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }

  /// Bouton menu sandwich (mode compact uniquement)
  Widget _buildMenuButton() {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 24,
        tooltip: 'Menu',
        onPressed: onMenuPressed,
        icon: const Icon(Icons.menu_rounded),
      ),
    );
  }
}