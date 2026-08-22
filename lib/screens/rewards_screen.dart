import 'package:flutter/material.dart';
import '../models/member.dart';
import '../services/member_service.dart';
import '../services/reward_service.dart';
import '../services/config_service.dart';
import '../widgets/family_header.dart';
import '../widgets/contribute_dialog.dart';

/// Page des réjouissances.
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  List<FamilyMember> _members = [];
  List<Reward> _rewards = [];
  Map<int, int> _contributedByReward = {};
  Map<int, bool> _obtainedByReward = {};
  List<Redemption> _redemptions = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  int _maxObtenues = 3;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final members = await MemberService.getActive();
      final rewards = await RewardService.getAll();
      final maxObtenues = await ConfigService.getMaxObtenues();

      final contributedByReward = <int, int>{};
      final obtainedByReward = <int, bool>{};

      for (final reward in rewards) {
        final contributions = await RewardService.getContributions(reward.id!);
        final activeContributions = contributions.where((c) => c.redemptionId == null);
        final total = activeContributions.fold(0, (sum, c) => sum + c.stars);
        contributedByReward[reward.id!] = total;
        obtainedByReward[reward.id!] = false;
      }

      final redemptions = await RewardService.getRecentRedemptions(100);
      for (final redemption in redemptions) {
        obtainedByReward[redemption.rewardId] = true;
      }

      setState(() {
        _members = members;
        _rewards = rewards;
        _contributedByReward = contributedByReward;
        _obtainedByReward = obtainedByReward;
        _redemptions = redemptions;
        _maxObtenues = maxObtenues;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  String _formatDate(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _rewardTitle(int rewardId) {
    for (final reward in _rewards) {
      if (reward.id == rewardId) return reward.title;
    }
    return 'Réjouissance';
  }

  List<Reward> get _disponibles {
    return _rewards.where((r) {
      final isObtained = _obtainedByReward[r.id] ?? false;
      // Une réjouissance masquée n'apparaît pas
      if (!r.active) return false;
      // Une réjouissance unique obtenue disparaît des disponibles
      if (isObtained && r.uniqueReward) return false;
      return true;
    }).toList();
  }

  List<Redemption> get _dernieresObtenues {
    if (_redemptions.length <= _maxObtenues) return _redemptions;
    return _redemptions.sublist(0, _maxObtenues);
  }

  int _contributed(Reward reward) => _contributedByReward[reward.id] ?? 0;

  void _openContribution(Reward reward) {
    showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ContributeDialog(
        members: _members,
        rewardTitle: reward.title,
        rewardCost: reward.cost,
        alreadyContributed: _contributed(reward),
      ),
    ).then((result) {
      if (result != null) {
        final member = result['member'] as FamilyMember;
        final amount = result['amount'] as int;
        _handleContribution(reward, member, amount);
      }
    });
  }

  void _handleContribution(Reward reward, FamilyMember member, int amount) async {
    final newContributed = _contributed(reward) + amount;
    final isNowObtained = newContributed >= reward.cost;

    await RewardService.addContribution(reward.id!, member.id!, amount);
    await MemberService.updateStars(member.id!, member.stars - amount);

    if (isNowObtained && reward.requiresNote) {
      _showNoteDialog(reward);
    } else if (isNowObtained) {
      await _finalizeObtained(reward, null);
    }
    await _loadData();
  }

  void _showNoteDialog(Reward reward) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bravo ! 🎉\n« ${reward.title} » obtenue !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Tu peux ajouter une précision :'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Ex: pepperoni, Minecraft, Parc Astérix...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _finalizeObtained(reward, null);
            },
            child: const Text('Passer'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _finalizeObtained(reward, noteController.text.trim());
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizeObtained(Reward reward, String? note) async {
    await RewardService.redeem(reward.id!, reward.cost, note);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Erreur de chargement', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(_errorMessage,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                    _errorMessage = '';
                  });
                  _loadData();
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        const FamilyHeader(),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _buildSectionTitle('🏆 Réjouissances disponibles'),
                  const SizedBox(height: 8),
                  if (_disponibles.isEmpty)
                    _buildEmptyCard('Aucune réjouissance disponible'),
                  for (final reward in _disponibles)
                    _buildAvailableRewardCard(reward),
                  const SizedBox(height: 24),
                  if (_dernieresObtenues.isNotEmpty) ...[
                    _buildSectionTitle('🎉 Dernières obtenues'),
                    const SizedBox(height: 8),
                    for (final redemption in _dernieresObtenues)
                      _buildObtainedRewardCard(redemption),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Center(
          child: Text(message,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500))),
    );
  }

  Widget _buildAvailableRewardCard(Reward reward) {
    final contributed = _contributed(reward);
    final progress = reward.cost > 0 ? contributed / reward.cost : 0.0;
    final remaining = reward.cost - contributed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(reward.title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
              Row(children: [
                const Icon(Icons.star_rounded, size: 20, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${reward.cost}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                  value: progress, minHeight: 8, backgroundColor: Colors.grey.shade200)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Encore $remaining ⭐',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              const Spacer(),
              FilledButton.icon(
                  onPressed: () => _openContribution(reward),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Contribuer')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObtainedRewardCard(Redemption redemption) {
    final title = _rewardTitle(redemption.rewardId);
    final note = redemption.note ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(title,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.green.shade800))),
              const Icon(Icons.check_circle, color: Colors.green, size: 22),
            ],
          ),
          const SizedBox(height: 6),
          Text('Obtenue le ${_formatDate(redemption.createdAt)}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text(note,
                    style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey.shade700))),
          ],
        ],
      ),
    );
  }
}