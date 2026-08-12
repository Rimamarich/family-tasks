import 'package:flutter/material.dart';
import '../models/member.dart';

/// Dialogue de contribution à une récompense.
///
/// Permet de sélectionner un membre, puis de choisir le montant
/// d'étoiles à contribuer. Le montant est limité par le solde
/// du membre et par le montant restant à atteindre.
class ContributeDialog extends StatefulWidget {
  const ContributeDialog({
    super.key,
    required this.members,
    required this.rewardTitle,
    required this.rewardCost,
    required this.alreadyContributed,
  });

  /// Liste des membres de la famille
  final List<FamilyMember> members;

  /// Titre de la récompense
  final String rewardTitle;

  /// Coût total de la récompense en étoiles
  final int rewardCost;

  /// Montant déjà contribué
  final int alreadyContributed;

  @override
  State<ContributeDialog> createState() => _ContributeDialogState();
}

class _ContributeDialogState extends State<ContributeDialog> {
  FamilyMember? _selectedMember;
  final TextEditingController _amountController = TextEditingController();

  /// Montant restant à atteindre
  int get _remaining => widget.rewardCost - widget.alreadyContributed;

  /// Solde du membre sélectionné (0 si aucun)
  int get _memberBalance => _selectedMember?.stars ?? 0;

  /// Montant maximum que le membre peut contribuer
  int get _maxAmount {
    if (_selectedMember == null) return 0;
    final fromBalance = _memberBalance;
    final fromRemaining = _remaining;
    return fromBalance < fromRemaining ? fromBalance : fromRemaining;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _validate() {
    final amount = int.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un montant valide.')),
      );
      return;
    }
    if (amount > _maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Montant maximum : $_maxAmount ⭐ (solde : $_memberBalance ⭐, '
            'restant pour la récompense : $_remaining ⭐)',
          ),
        ),
      );
      return;
    }
    // Ferme le dialogue et retourne le membre et le montant
    Navigator.of(context).pop({
      'member': _selectedMember,
      'amount': amount,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Contribuer à\n« ${widget.rewardTitle} »'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Coût total et restant
          Text(
            'Coût : ${widget.rewardCost} ⭐  •  Restant : $_remaining ⭐',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),

          // Sélecteur de membre
          Text(
            'Qui es-tu ?',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: widget.members.map((member) {
              final isSelected = _selectedMember == member;
              return ChoiceChip(
                label: Text('${member.avatar} ${member.name}'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedMember = selected ? member : null;
                    _amountController.clear();
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Champ montant
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            enabled: _selectedMember != null,
            decoration: InputDecoration(
              labelText: 'Montant',
              suffixText: '⭐',
              hintText: _selectedMember != null
                  ? 'Max $_maxAmount ⭐'
                  : 'Sélectionne un membre',
              border: const OutlineInputBorder(),
            ),
          ),
          if (_selectedMember != null) ...[
            const SizedBox(height: 4),
            Text(
              'Ton solde : $_memberBalance ⭐',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _selectedMember != null ? _validate : null,
          child: const Text('Contribuer'),
        ),
      ],
    );
  }
}