import 'package:flutter/material.dart';

/// Dialogue d'ajout ou de modification d'un membre.
///
/// Permet de saisir le prénom, choisir un avatar parmi une liste
/// prédéfinie, et sélectionner une couleur.
///
/// Si [memberName] est fourni, le dialogue est en mode modification
/// et les champs sont pré-remplis.
class MemberEditDialog extends StatefulWidget {
  const MemberEditDialog({
    super.key,
    this.memberName,
    this.memberAvatar,
    this.memberColor,
  });

  /// Prénom actuel (mode modification)
  final String? memberName;

  /// Avatar actuel (mode modification)
  final String? memberAvatar;

  /// Couleur actuelle (mode modification)
  final Color? memberColor;

  /// Le dialogue est en mode modification si un nom est fourni
  bool get isEditing => memberName != null;

  @override
  State<MemberEditDialog> createState() => _MemberEditDialogState();
}

class _MemberEditDialogState extends State<MemberEditDialog> {
  late final TextEditingController _nameController;

  // Liste des avatars disponibles
  static const List<String> _avatars = [
    '👩', '👨', '👧', '👦', '👵', '👴', '👶', '🧑',
    '👩‍🦰', '👨‍🦰', '👩‍🦱', '👨‍🦱', '👩‍🦳', '👨‍🦳',
  ];

  // Liste des couleurs disponibles
  static const List<Color> _colors = [
    Colors.blue,
    Colors.green,
    Colors.pink,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
  ];

  String _selectedAvatar = '👩';
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.memberName ?? '');
    _selectedAvatar = widget.memberAvatar ?? '👩';
    _selectedColor = widget.memberColor ?? Colors.blue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _validate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le prénom ne peut pas être vide.')),
      );
      return;
    }
    Navigator.of(context).pop({
      'name': name,
      'avatar': _selectedAvatar,
      'color': _selectedColor,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Modifier le membre' : 'Ajouter un membre'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Prénom ----
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Prénom',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // ---- Avatar ----
            const Text('Avatar', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _avatars.map((avatar) {
                final isSelected = _selectedAvatar == avatar;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAvatar = avatar),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _selectedColor.withValues(alpha: 0.2)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: _selectedColor, width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(avatar, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ---- Couleur ----
            const Text('Couleur', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _validate,
          child: Text(widget.isEditing ? 'Modifier' : 'Ajouter'),
        ),
      ],
    );
  }
}