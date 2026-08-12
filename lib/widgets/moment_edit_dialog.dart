import 'package:flutter/material.dart';

/// Dialogue d'ajout ou de modification d'un moment de la journée.
///
/// Permet de saisir le nom du moment et de choisir son heure de fin.
/// Si [momentName] est fourni, le dialogue est en mode modification.
class MomentEditDialog extends StatefulWidget {
  const MomentEditDialog({
    super.key,
    this.momentName,
    this.momentEndTime,
  });

  final String? momentName;
  final String? momentEndTime;

  bool get isEditing => momentName != null;

  @override
  State<MomentEditDialog> createState() => _MomentEditDialogState();
}

class _MomentEditDialogState extends State<MomentEditDialog> {
  late final TextEditingController _nameController;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 30);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.momentName ?? '');

    if (widget.momentEndTime != null) {
      final parts = widget.momentEndTime!.split(':');
      if (parts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 10,
          minute: int.tryParse(parts[1]) ?? 30,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _validate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom du moment ne peut pas être vide.')),
      );
      return;
    }
    Navigator.of(context).pop({
      'name': name,
      'heure_de_fin': _formatTime(_selectedTime),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Modifier le moment' : 'Ajouter un moment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom du moment',
              hintText: 'Ex: Matin, Soirée...',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Heure de fin : ',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time),
                label: Text(
                  _selectedTime.format(context),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ],
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