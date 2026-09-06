import 'package:flutter/material.dart';
import '../models/member.dart';

/// Dialogue de contribution à une récompense.
///
/// Permet de sélectionner un membre, puis de choisir le montant
/// d'étoiles à contribuer via un pavé numérique tactile.
class ContributeDialog extends StatefulWidget {
  const ContributeDialog({
    super.key,
    required this.members,
    required this.rewardTitle,
    required this.rewardCost,
    required this.alreadyContributed,
  });

  final List<FamilyMember> members;
  final String rewardTitle;
  final int rewardCost;
  final int alreadyContributed;

  @override
  State<ContributeDialog> createState() => _ContributeDialogState();
}

class _ContributeDialogState extends State<ContributeDialog> {
  FamilyMember? _selectedMember;
  String _amountText = '';

  int get _remaining => widget.rewardCost - widget.alreadyContributed;

  int get _memberBalance => _selectedMember?.stars ?? 0;

  int get _maxAmount {
    if (_selectedMember == null) return 0;
    final fromBalance = _memberBalance;
    final fromRemaining = _remaining;
    return fromBalance < fromRemaining ? fromBalance : fromRemaining;
  }

  void _addDigit(String digit) {
    if (_selectedMember == null) return;
    setState(() {
      if (_amountText.length < 3) {
        _amountText += digit;
      }
    });
  }

  void _removeDigit() {
    if (_amountText.isEmpty) return;
    setState(() {
      _amountText = _amountText.substring(0, _amountText.length - 1);
    });
  }

  void _clear() {
    setState(() {
      _amountText = '';
    });
  }

  void _validate() {
    final amount = int.tryParse(_amountText);
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
    Navigator.of(context).pop({
      'member': _selectedMember,
      'amount': amount,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Contribuer à\n« ${widget.rewardTitle} »'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Coût et restant
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coût : ${widget.rewardCost} ⭐ • Restant : $_remaining ⭐',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sélecteur de membre
            const Text('Qui es-tu ?',
                style: TextStyle(fontWeight: FontWeight.w600)),
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
                      _amountText = '';
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Affichage du montant
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                _amountText.isEmpty ? '0 ⭐' : '$_amountText ⭐',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),

            // Solde et max
            if (_selectedMember != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined,
                        size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Ton solde : $_memberBalance ⭐',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Max : $_maxAmount ⭐',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Pavé numérique
            if (_selectedMember != null) _buildNumpad(),
          ],
        ),
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

  Widget _buildNumpad() {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildKey('1'), const SizedBox(width: 8),
          _buildKey('2'), const SizedBox(width: 8),
          _buildKey('3'),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildKey('4'), const SizedBox(width: 8),
          _buildKey('5'), const SizedBox(width: 8),
          _buildKey('6'),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildKey('7'), const SizedBox(width: 8),
          _buildKey('8'), const SizedBox(width: 8),
          _buildKey('9'),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildClearKey(), const SizedBox(width: 8),
          _buildKey('0'), const SizedBox(width: 8),
          _buildBackspaceKey(),
        ]),
      ],
    );
  }

  Widget _buildKey(String digit) => SizedBox(
        width: 56,
        height: 48,
        child: Material(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _addDigit(digit),
            child: Center(
                child: Text(digit,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w500))),
          ),
        ),
      );

  Widget _buildClearKey() => SizedBox(
        width: 56,
        height: 48,
        child: Material(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _clear,
            child: const Center(child: Icon(Icons.clear, size: 20)),
          ),
        ),
      );

  Widget _buildBackspaceKey() => SizedBox(
        width: 56,
        height: 48,
        child: Material(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _removeDigit,
            child: const Center(
                child: Icon(Icons.backspace_outlined, size: 20)),
          ),
        ),
      );
}