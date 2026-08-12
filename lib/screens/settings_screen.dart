import 'package:flutter/material.dart';
import '../models/member.dart';
import '../widgets/header.dart';
import '../widgets/member_edit_dialog.dart';
import '../widgets/moment_edit_dialog.dart';
import '../widgets/reward_edit_dialog.dart';

// ---- Modèles temporaires ----

class Moment {
  const Moment({required this.name, required this.heureDeFin});
  final String name;
  final String heureDeFin;
}

class Reward {
  const Reward({required this.title, required this.cost, this.unique = false, this.requiresNote = false, this.isObtained = false});
  final String title;
  final int cost;
  final bool unique;
  final bool requiresNote;
  final bool isObtained;
}

// ---- Écran ----

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static List<String> encouragementMessages = [
    'Tu es un champion ! 🏆',
    'Quelle journée productive ! 🌟',
    'Tu peux être fier de toi ! 💪',
    'Bravo, continue comme ça ! 🎉',
    'Tu as assuré aujourd\'hui ! ⭐',
  ];

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const double _limitedHeightThreshold = 400;

  final GlobalKey<_PinInputWidgetState> _pinKey = GlobalKey();
  final TextEditingController _icsController = TextEditingController(text: 'https://exemple.fr/famille.ics');
  final TextEditingController _newMessageController = TextEditingController();

  List<FamilyMember> members = [
    const FamilyMember(name: 'Marie', avatar: '👩', color: Colors.blue, stars: 0, tasks: []),
    const FamilyMember(name: 'Antoine', avatar: '👨', color: Colors.green, stars: 0, tasks: []),
    const FamilyMember(name: 'Mimi', avatar: '👧', color: Colors.pink, stars: 0, tasks: []),
    const FamilyMember(name: 'Alex', avatar: '👦', color: Colors.orange, stars: 0, tasks: []),
  ];

  List<Moment> moments = const [
    Moment(name: 'Matin', heureDeFin: '10:30'),
    Moment(name: 'Temps de midi', heureDeFin: '13:00'),
    Moment(name: 'Après-midi', heureDeFin: '18:00'),
    Moment(name: 'Soirée', heureDeFin: '19:30'),
    Moment(name: 'Fin de soirée', heureDeFin: '21:30'),
  ];

  List<Reward> rewards = [
    const Reward(title: 'Soirée cinéma', cost: 20),
    const Reward(title: 'Choisir le repas', cost: 15, requiresNote: true),
    const Reward(title: 'Journée parc', cost: 30),
    const Reward(title: 'Soirée pizza', cost: 25, unique: true, isObtained: true),
  ];

  int maxObtenues = 3;

  String get currentMoment => '';
  int get totalTasks => 0;
  int get completedTasks => 0;
  double get progress => 0;

  @override
  void dispose() {
    _icsController.dispose();
    _newMessageController.dispose();
    super.dispose();
  }

  // ---- Membres ----

  void _addMember() async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => const MemberEditDialog());
    if (result != null) {
      setState(() => members.add(FamilyMember(name: result['name'], avatar: result['avatar'], color: result['color'], stars: 0, tasks: [])));
    }
  }

  void _editMember(int index) async {
    final member = members[index];
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => MemberEditDialog(memberName: member.name, memberAvatar: member.avatar, memberColor: member.color));
    if (result != null) {
      setState(() => members[index] = FamilyMember(name: result['name'], avatar: result['avatar'], color: result['color'], stars: member.stars, tasks: member.tasks, pause: member.pause));
    }
  }

  void _deleteMember(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le membre'),
        content: Text('Veux-tu vraiment supprimer ${members[index].name} ? Ses étoiles et son historique seront perdus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(onPressed: () { setState(() => members.removeAt(index)); Navigator.pop(context); }, style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Supprimer')),
        ],
      ),
    );
  }

  void _togglePause(int index) {
    setState(() {
      final m = members[index];
      members[index] = FamilyMember(name: m.name, avatar: m.avatar, color: m.color, stars: m.stars, tasks: m.tasks, pause: !m.pause);
    });
  }

  // ---- Moments ----

  void _addMoment() async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => const MomentEditDialog());
    if (result != null) setState(() => moments.add(Moment(name: result['name'], heureDeFin: result['heure_de_fin'])));
  }

  void _editMoment(int index) async {
    final m = moments[index];
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => MomentEditDialog(momentName: m.name, momentEndTime: m.heureDeFin));
    if (result != null) setState(() => moments[index] = Moment(name: result['name'], heureDeFin: result['heure_de_fin']));
  }

  void _deleteMoment(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le moment'),
        content: Text('Veux-tu vraiment supprimer le moment "${moments[index].name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(onPressed: () { setState(() => moments.removeAt(index)); Navigator.pop(context); }, style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Supprimer')),
        ],
      ),
    );
  }

  // ---- Réjouissances ----

  void _addReward() async {
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => const RewardEditDialog());
    if (result != null) setState(() => rewards.add(Reward(title: result['title'], cost: result['cost'], unique: result['unique'], requiresNote: result['requires_note'])));
  }

  void _editReward(int index) async {
    final r = rewards[index];
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => RewardEditDialog(rewardTitle: r.title, rewardCost: r.cost, rewardUnique: r.unique, rewardRequiresNote: r.requiresNote));
    if (result != null) setState(() => rewards[index] = Reward(title: result['title'], cost: result['cost'], unique: result['unique'], requiresNote: result['requires_note'], isObtained: r.isObtained));
  }

  void _deleteReward(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la réjouissance'),
        content: Text('Veux-tu vraiment supprimer la réjouissance "${rewards[index].title}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(onPressed: () { setState(() => rewards.removeAt(index)); Navigator.pop(context); }, style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Supprimer')),
        ],
      ),
    );
  }

  void _reactivateReward(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réactiver la réjouissance'),
        content: Text('Veux-tu réactiver "${rewards[index].title}" ? Elle sera de nouveau disponible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(onPressed: () { setState(() { final r = rewards[index]; rewards[index] = Reward(title: r.title, cost: r.cost, unique: r.unique, requiresNote: r.requiresNote, isObtained: false); }); Navigator.pop(context); }, child: const Text('Réactiver')),
        ],
      ),
    );
  }

  // ---- Messages ----

  void _addMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau message'),
        content: TextField(controller: _newMessageController, decoration: const InputDecoration(hintText: 'Ex: Tu as géré comme un chef !', border: OutlineInputBorder()), autofocus: true, maxLength: 100),
        actions: [
          TextButton(onPressed: () { _newMessageController.clear(); Navigator.pop(context); }, child: const Text('Annuler')),
          FilledButton(onPressed: () { final text = _newMessageController.text.trim(); if (text.isNotEmpty) setState(() => SettingsScreen.encouragementMessages.add(text)); _newMessageController.clear(); Navigator.pop(context); }, child: const Text('Ajouter')),
        ],
      ),
    );
  }

  void _deleteMessage(int index) {
    setState(() => SettingsScreen.encouragementMessages.removeAt(index));
  }

  // ---- Construction ----

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < _limitedHeightThreshold;

        return Column(
          children: [
            HeaderWidget(
              date: today, currentMoment: currentMoment, completedTasks: completedTasks,
              totalTasks: totalTasks, progress: progress, isCompact: isCompact,
              onMenuPressed: () => Scaffold.of(context).openDrawer(),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _buildMembersSection(), const SizedBox(height: 24),
                      _buildMomentsSection(), const SizedBox(height: 24),
                      _buildRewardsSection(), const SizedBox(height: 24),
                      _buildSyncSection(), const SizedBox(height: 24),
                      _buildSecuritySection(), const SizedBox(height: 24),
                      _buildEncouragementSection(),
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

  // ---- Sections ----

  Widget _buildMembersSection() {
    return _buildSection(title: '👨‍👩‍👧‍👦 Membres', trailing: IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _addMember, tooltip: 'Ajouter un membre'), children: [for (var i = 0; i < members.length; i++) _buildMemberTile(i)]);
  }

  Widget _buildMemberTile(int index) {
    final m = members[index];
    return Card(margin: const EdgeInsets.only(bottom: 6), child: ListTile(
      leading: CircleAvatar(backgroundColor: m.color.withValues(alpha: 0.2), child: Text(m.avatar, style: const TextStyle(fontSize: 22))),
      title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: m.pause ? Text('En pause', style: TextStyle(color: Colors.orange.shade700, fontSize: 12)) : null,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: Icon(m.pause ? Icons.play_arrow : Icons.pause_circle_outline, color: m.pause ? Colors.orange : Colors.grey), tooltip: m.pause ? 'Réactiver' : 'Mettre en pause', onPressed: () => _togglePause(index)),
        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), tooltip: 'Supprimer', onPressed: () => _deleteMember(index)),
      ]),
      onTap: () => _editMember(index),
    ));
  }

  Widget _buildMomentsSection() {
    return _buildSection(title: '⏰ Moments de la journée', trailing: IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _addMoment, tooltip: 'Ajouter un moment'), children: [
      for (var i = 0; i < moments.length; i++)
        Card(margin: const EdgeInsets.only(bottom: 6), child: ListTile(leading: const Icon(Icons.schedule), title: Text(moments[i].name, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text('Heure de fin : ${moments[i].heureDeFin}'), trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), tooltip: 'Supprimer', onPressed: () => _deleteMoment(i)), onTap: () => _editMoment(i))),
    ]);
  }

  Widget _buildRewardsSection() {
    return _buildSection(title: '🏆 Réjouissances', trailing: IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _addReward, tooltip: 'Ajouter une réjouissance'), children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), child: Row(children: [
        const Text('Nb obtenues affichées : ', style: TextStyle(fontSize: 14)), const Spacer(),
        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: maxObtenues > 1 ? () => setState(() => maxObtenues--) : null),
        Text('$maxObtenues', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => maxObtenues++)),
      ])),
      const SizedBox(height: 4),
      for (var i = 0; i < rewards.length; i++) _buildRewardTile(i),
    ]);
  }

  Widget _buildRewardTile(int index) {
    final r = rewards[index];
    return Card(margin: const EdgeInsets.only(bottom: 6), child: ListTile(
      leading: Icon(r.isObtained ? Icons.check_circle : Icons.star_rounded, color: r.isObtained ? Colors.green : Colors.amber),
      title: Text(r.title, style: TextStyle(fontWeight: FontWeight.w600, color: r.isObtained ? Colors.grey : null)),
      subtitle: Text('${r.cost} ⭐${r.unique ? " • Unique" : ""}${r.requiresNote ? " • Note requise" : ""}${r.isObtained ? " • Obtenue" : ""}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (r.isObtained && r.unique) IconButton(icon: const Icon(Icons.refresh, color: Colors.green), tooltip: 'Réactiver', onPressed: () => _reactivateReward(index)),
        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), tooltip: 'Supprimer', onPressed: () => _deleteReward(index)),
      ]),
      onTap: () => _editReward(index),
    ));
  }

  Widget _buildSyncSection() {
    return _buildSection(title: '🔄 Synchronisation ICS', children: [
      const SizedBox(height: 8),
      TextField(controller: _icsController, decoration: const InputDecoration(labelText: 'Adresse du fichier ICS', hintText: 'https://...', border: OutlineInputBorder()), keyboardType: TextInputType.url),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Synchronisation lancée...'))), icon: const Icon(Icons.sync), label: const Text('Synchroniser maintenant')),
    ]);
  }

  Widget _buildSecuritySection() {
    return _buildSection(title: '🔒 Code PIN parental', children: [
      const SizedBox(height: 8), const Text('Nouveau code PIN (4 chiffres) :', style: TextStyle(fontSize: 14)), const SizedBox(height: 8),
      PinInputWidget(key: _pinKey, onComplete: (pin) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code PIN modifié.'))); _pinKey.currentState?.clear(); }),
    ]);
  }

  Widget _buildEncouragementSection() {
    return _buildSection(title: '💬 Messages d\'encouragement', trailing: IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _addMessage, tooltip: 'Ajouter un message'), children: [
      const SizedBox(height: 4), Text('Ces messages apparaîtront quand un membre termine toutes ses tâches.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)), const SizedBox(height: 8),
      if (SettingsScreen.encouragementMessages.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text('Aucun message. Ajoutes-en !', style: TextStyle(color: Colors.grey.shade500))),
      for (var i = 0; i < SettingsScreen.encouragementMessages.length; i++)
        Card(margin: const EdgeInsets.only(bottom: 6), child: ListTile(leading: const Icon(Icons.format_quote, color: Colors.amber), title: Text(SettingsScreen.encouragementMessages[i], style: const TextStyle(fontSize: 14)), trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteMessage(i)))),
    ]);
  }

  Widget _buildSection({required String title, required List<Widget> children, Widget? trailing}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Spacer(), if (trailing != null) trailing]),
      const SizedBox(height: 8), ...children,
    ]);
  }
}

// ---- Widget PIN ----

class PinInputWidget extends StatefulWidget {
  const PinInputWidget({super.key, required this.onComplete});
  final void Function(String pin) onComplete;
  @override State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget> {
  final List<String?> _digits = List.filled(4, null);
  int _currentIndex = 0;

  void _addDigit(String digit) {
    if (_currentIndex >= 4) return;
    setState(() { _digits[_currentIndex] = digit; _currentIndex++; });
    Future.delayed(const Duration(milliseconds: 600), () { if (mounted && _currentIndex > 0) setState(() {}); });
  }

  void _removeDigit() {
    if (_currentIndex == 0) return;
    setState(() { _currentIndex--; _digits[_currentIndex] = null; });
  }

  void _clear() {
    setState(() { for (var i = 0; i < 4; i++) _digits[i] = null; _currentIndex = 0; });
  }

  void clear() => _clear();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (index) {
        final isActive = index == _currentIndex;
        return Container(width: 48, height: 56, margin: const EdgeInsets.symmetric(horizontal: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade300, width: isActive ? 2 : 1)), alignment: Alignment.center,
          child: _digits[index] != null ? Text(_digits[index]!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)) : Container(width: 10, height: 10, decoration: BoxDecoration(color: isActive ? Colors.grey.shade400 : Colors.transparent, shape: BoxShape.circle)));
      })),
      const SizedBox(height: 16), _buildNumpad(),
    ]);
  }

  Widget _buildNumpad() {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildKey('1'), const SizedBox(width: 8), _buildKey('2'), const SizedBox(width: 8), _buildKey('3')]), const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildKey('4'), const SizedBox(width: 8), _buildKey('5'), const SizedBox(width: 8), _buildKey('6')]), const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildKey('7'), const SizedBox(width: 8), _buildKey('8'), const SizedBox(width: 8), _buildKey('9')]), const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildBackspaceKey(), const SizedBox(width: 8), _buildKey('0'), const SizedBox(width: 8), _buildDoneKey()]),
    ]);
  }

  Widget _buildKey(String digit) => SizedBox(width: 64, height: 52, child: Material(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10), child: InkWell(borderRadius: BorderRadius.circular(10), onTap: () => _addDigit(digit), child: Center(child: Text(digit, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500))))));
  Widget _buildBackspaceKey() => SizedBox(width: 64, height: 52, child: Material(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10), child: InkWell(borderRadius: BorderRadius.circular(10), onTap: _removeDigit, child: const Center(child: Icon(Icons.backspace_outlined, size: 24)))));
  Widget _buildDoneKey() => SizedBox(width: 64, height: 52, child: Material(color: _currentIndex == 4 ? Theme.of(context).primaryColor : Colors.grey.shade300, borderRadius: BorderRadius.circular(10), child: InkWell(borderRadius: BorderRadius.circular(10), onTap: _currentIndex == 4 ? () { widget.onComplete(_digits.whereType<String>().join()); } : null, child: const Center(child: Icon(Icons.check, color: Colors.white, size: 24)))));
}