import 'package:flutter/material.dart';

/// Dialogue d'ajout ou de modification d'une récompense.
///
/// Permet de saisir le titre, le coût en étoiles, et de définir
/// si la récompense est unique et/ou nécessite une note.
/// Si [rewardTitle] est fourni, le dialogue est en mode modification.
class RewardEditDialog extends StatefulWidget {
  const RewardEditDialog({
    super.key,
    this.rewardTitle,
    this.rewardCost,
    this.rewardUnique = false,
    this.rewardRequiresNote = false,
    this.minCost = 1,
  });

  final String? rewardTitle;
  final int? rewardCost;
  final bool rewardUnique;
  final bool rewardRequiresNote;

  /// Coût minimum autorisé (montant déjà contribué).
  final int minCost;

  bool get isEditing => rewardTitle != null;

  @override
  State<RewardEditDialog> createState() => _RewardEditDialogState();
}

class _RewardEditDialogState extends State<RewardEditDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _costController;
  late bool _unique;
  late bool _requiresNote;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.rewardTitle ?? '');
    _costController = TextEditingController(
      text: widget.rewardCost?.toString() ?? '',
    );
    _unique = widget.rewardUnique;
    _requiresNote = widget.rewardRequiresNote;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _validate() {
    final title = _titleController.text.trim();
    final cost = int.tryParse(_costController.text.trim());

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre ne peut pas être vide.')),
      );
      return;
    }
    if (cost == null || cost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le coût doit être un nombre positif.')),
      );
      return;
    }
    if (widget.isEditing && cost < widget.minCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible : ${widget.minCost} ⭐ déjà contribuées. '
            'Le coût doit être supérieur ou égal à ${widget.minCost} ⭐.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop({
      'title': title,
      'cost': cost,
      'unique': _unique,
      'requires_note': _requiresNote,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing
          ? 'Modifier la récompense'
          : 'Ajouter une récompense'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Titre ----
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                hintText: 'Ex: Soirée cinéma',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // ---- Coût ----
            TextField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Coût en étoiles',
                suffixText: '⭐',
                border: const OutlineInputBorder(),
                helperText: widget.isEditing
                    ? 'Minimum : ${widget.minCost} ⭐ (déjà contribuées)'
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // ---- Unique ----
            SwitchListTile(
              title: const Text('Récompense unique'),
              subtitle: const Text('Ne peut être obtenue qu\'une seule fois'),
              value: _unique,
              onChanged: (value) => setState(() => _unique = value),
              contentPadding: EdgeInsets.zero,
            ),

            // ---- Nécessite une note ----
            SwitchListTile(
              title: const Text('Nécessite une note'),
              subtitle: const Text('Ex: quel repas, quel film...'),
              value: _requiresNote,
              onChanged: (value) => setState(() => _requiresNote = value),
              contentPadding: EdgeInsets.zero,
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