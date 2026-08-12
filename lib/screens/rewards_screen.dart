import 'package:flutter/material.dart';
import '../models/member.dart';
import '../widgets/header.dart';
import '../widgets/contribute_dialog.dart';

// ---- Modèles temporaires ----

class Reward {
  const Reward({
    required this.title,
    required this.cost,
    required this.contributed,
    this.isObtained = false,
    this.obtainedDate,
    this.note,
    this.unique = false,
    this.requiresNote = false,
  });

  final String title;
  final int cost;
  final int contributed;
  final bool isObtained;
  final String? obtainedDate;
  final String? note;
  final bool unique;
  final bool requiresNote;
}

// ---- Écran ----

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  static const double _limitedHeightThreshold = 400;
  static const int _maxObtenues = 3;

  final List<FamilyMember> members = [
    const FamilyMember(name: 'Marie', avatar: '👩', color: Colors.blue, stars: 24, tasks: []),
    const FamilyMember(name: 'Antoine', avatar: '👨', color: Colors.green, stars: 18, tasks: []),
    const FamilyMember(name: 'Mimi', avatar: '👧', color: Colors.pink, stars: 31, tasks: []),
    const FamilyMember(name: 'Alex', avatar: '👦', color: Colors.orange, stars: 15, tasks: []),
  ];

  List<Reward> rewards = [
    const Reward(title: 'Soirée cinéma', cost: 20, contributed: 12, requiresNote: true),
    const Reward(title: 'Choisir le repas', cost: 15, contributed: 0, requiresNote: true),
    const Reward(title: 'Journée parc', cost: 30, contributed: 5),
    Reward(title: 'Soirée pizza', cost: 25, contributed: 25, isObtained: true, obtainedDate: '11 août 2026', unique: true, note: 'Reine'),
    Reward(title: 'Nouveau jeu vidéo', cost: 40, contributed: 40, isObtained: true, obtainedDate: '3 août 2026', note: 'Minecraft', unique: true),
  ];

  List<Reward> get _disponibles => rewards.where((r) => !r.isObtained).toList();

  List<Reward> get _dernieresObtenues {
    final obtenues = rewards.where((r) => r.isObtained).toList();
    if (obtenues.length <= _maxObtenues) return obtenues;
    return obtenues.sublist(obtenues.length - _maxObtenues);
  }

  int get totalTasks => 0;
  int get completedTasks => 0;
  double get progress => 0;

  String get currentMoment {
    final now = DateTime.now();
    final time = now.hour * 60 + now.minute;
    if (time < 10 * 60 + 30) return 'Matin';
    if (time < 13 * 60) return 'Temps de midi';
    if (time < 18 * 60) return 'Après-midi';
    if (time < 19 * 60 + 30) return 'Soirée';
    return 'Fin de soirée';
  }

  void _openContribution(Reward reward) {
    showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ContributeDialog(
        members: members,
        rewardTitle: reward.title,
        rewardCost: reward.cost,
        alreadyContributed: reward.contributed,
      ),
    ).then((result) {
      if (result != null) {
        final member = result['member'] as FamilyMember;
        final amount = result['amount'] as int;
        _handleContribution(reward, member, amount);
      }
    });
  }

  void _handleContribution(Reward reward, FamilyMember member, int amount) {
    final memberIndex = members.indexOf(member);
    final rewardIndex = rewards.indexOf(reward);
    final newContributed = reward.contributed + amount;
    final isNowObtained = newContributed >= reward.cost;

    members[memberIndex] = FamilyMember(
      name: member.name, avatar: member.avatar, color: member.color,
      stars: member.stars - amount, tasks: member.tasks,
    );

    if (isNowObtained && reward.requiresNote) {
      _showNoteDialog(reward, newContributed, rewardIndex);
    } else if (isNowObtained) {
      _finalizeObtained(reward, newContributed, rewardIndex, null);
    } else {
      setState(() {
        rewards[rewardIndex] = Reward(
          title: reward.title, cost: reward.cost, contributed: newContributed,
          isObtained: false, obtainedDate: reward.obtainedDate,
          note: reward.note, unique: reward.unique, requiresNote: reward.requiresNote,
        );
      });
    }
  }

  void _showNoteDialog(Reward reward, int newContributed, int rewardIndex) {
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
              _finalizeObtained(reward, newContributed, rewardIndex, null);
              Navigator.pop(context);
            },
            child: const Text('Passer'),
          ),
          FilledButton(
            onPressed: () {
              _finalizeObtained(reward, newContributed, rewardIndex, noteController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _finalizeObtained(Reward reward, int newContributed, int rewardIndex, String? note) {
    setState(() {
      rewards[rewardIndex] = Reward(
        title: reward.title, cost: reward.cost, contributed: newContributed,
        isObtained: true, obtainedDate: _todayString(),
        note: note != null && note.isNotEmpty ? note : null,
        unique: reward.unique, requiresNote: reward.requiresNote,
      );
    });
  }

  String _todayString() {
    final now = DateTime.now();
    const months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < _limitedHeightThreshold;

        return Column(
          children: [
            HeaderWidget(
              date: today,
              currentMoment: currentMoment,
              completedTasks: completedTasks,
              totalTasks: totalTasks,
              progress: progress,
              isCompact: isCompact,
              onMenuPressed: () => Scaffold.of(context).openDrawer(),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      _buildSectionTitle('🏆 Réjouissances disponibles'),
                      const SizedBox(height: 8),
                      if (_disponibles.isEmpty) _buildEmptyCard('Aucune réjouissance disponible'),
                      for (final reward in _disponibles) _buildAvailableRewardCard(reward),
                      const SizedBox(height: 24),
                      if (_dernieresObtenues.isNotEmpty) ...[
                        _buildSectionTitle('🎉 Dernières obtenues'),
                        const SizedBox(height: 8),
                        for (final reward in _dernieresObtenues) _buildObtainedRewardCard(reward),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Center(child: Text(message, style: TextStyle(fontSize: 15, color: Colors.grey.shade500))),
    );
  }

  Widget _buildAvailableRewardCard(Reward reward) {
    final progress = reward.cost > 0 ? reward.contributed / reward.cost : 0.0;
    final remaining = reward.cost - reward.contributed;
    final isComplete = remaining <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(reward.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
              Row(children: [const Icon(Icons.star_rounded, size: 20, color: Colors.amber), const SizedBox(width: 4), Text('${reward.cost}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))]),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.grey.shade200)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(isComplete ? 'Complété !' : 'Encore $remaining ⭐', style: TextStyle(fontSize: 14, color: isComplete ? Colors.green.shade600 : Colors.grey.shade600, fontWeight: FontWeight.w500)),
              const Spacer(),
              if (!isComplete) FilledButton.icon(onPressed: () => _openContribution(reward), icon: const Icon(Icons.add_circle_outline, size: 18), label: const Text('Contribuer')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObtainedRewardCard(Reward reward) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(reward.title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.green.shade800))),
              const Icon(Icons.check_circle, color: Colors.green, size: 22),
            ],
          ),
          const SizedBox(height: 6),
          Text('Obtenue le ${reward.obtainedDate ?? ""}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          if (reward.note != null && reward.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Text(reward.note!, style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey.shade700))),
          ],
        ],
      ),
    );
  }
}