import 'package:flutter/material.dart';
import '../models/member.dart';
import '../services/member_service.dart';
import '../services/moment_service.dart';
import '../services/reward_service.dart';
import '../services/config_service.dart';
import '../widgets/family_header.dart';
import '../widgets/member_edit_dialog.dart';
import '../widgets/moment_edit_dialog.dart';
import '../widgets/reward_edit_dialog.dart';

/// Page des paramètres.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<_PinInputWidgetState> _pinKey = GlobalKey();
  final TextEditingController _icsController = TextEditingController();
  final TextEditingController _message1Controller = TextEditingController();
  final TextEditingController _message2Controller = TextEditingController();
  final TextEditingController _message3Controller = TextEditingController();
  final TextEditingController _message4Controller = TextEditingController();
  final TextEditingController _message5Controller = TextEditingController();

  List<FamilyMember> _members = [];
  List<Moment> _moments = [];
  List<Reward> _rewards = [];
  Map<int, int> _contributedByReward = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  int _maxObtenues = 3;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _icsController.dispose();
    _message1Controller.dispose();
    _message2Controller.dispose();
    _message3Controller.dispose();
    _message4Controller.dispose();
    _message5Controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final members = await MemberService.getAll();
      final moments = await MomentService.getAll();
      final rewards = await RewardService.getAll();
      final maxObtenues = await ConfigService.getMaxObtenues();
      final messages = await ConfigService.getMessages();

      // Charge les contributions pour chaque récompense
      final contributedByReward = <int, int>{};
      for (final reward in rewards) {
        final contributions = await RewardService.getContributions(reward.id!);
        final total = contributions.fold(0, (sum, c) => sum + c.stars);
        contributedByReward[reward.id!] = total;
      }

      _icsController.text = await ConfigService.getIcsUrl() ?? '';
      _message1Controller.text = messages.length > 0 ? messages[0] : '';
      _message2Controller.text = messages.length > 1 ? messages[1] : '';
      _message3Controller.text = messages.length > 2 ? messages[2] : '';
      _message4Controller.text = messages.length > 3 ? messages[3] : '';
      _message5Controller.text = messages.length > 4 ? messages[4] : '';

      setState(() {
        _members = members;
        _moments = moments;
        _rewards = rewards;
        _contributedByReward = contributedByReward;
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

  // ---- Membres ----

  void _addMember() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const MemberEditDialog(),
    );
    if (result != null) {
      final member = FamilyMember(
        name: result['name'],
        avatar: result['avatar'],
        color: result['color'],
        stars: 0,
      );
      await MemberService.insert(member);
      await _loadData();
    }
  }

  void _editMember(int index) async {
    final member = _members[index];
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => MemberEditDialog(
        memberName: member.name,
        memberAvatar: member.avatar,
        memberColor: member.color,
      ),
    );
    if (result != null) {
      final updated = member.copyWith(
        name: result['name'],
        avatar: result['avatar'],
        color: result['color'],
      );
      await MemberService.update(updated);
      await _loadData();
    }
  }

  void _deleteMember(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le membre'),
        content: Text(
            'Veux-tu vraiment supprimer ${_members[index].name} ? Ses étoiles et son historique seront perdus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              await MemberService.delete(_members[index].id!);
              Navigator.pop(context);
              await _loadData();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _togglePause(int index) async {
    final member = _members[index];
    final updated = member.copyWith(pause: !member.pause);
    await MemberService.update(updated);
    await _loadData();
  }

  // ---- Moments ----

  void _addMoment() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const MomentEditDialog(),
    );
    if (result != null) {
      final moment = Moment(name: result['name'], heureDeFin: result['heure_de_fin']);
      await MomentService.insert(moment);
      await _loadData();
    }
  }

  void _editMoment(int index) async {
    final moment = _moments[index];
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => MomentEditDialog(
        momentName: moment.name,
        momentEndTime: moment.heureDeFin,
      ),
    );
    if (result != null) {
      final updated = Moment(
        id: moment.id,
        name: result['name'],
        heureDeFin: result['heure_de_fin'],
      );
      await MomentService.update(updated);
      await _loadData();
    }
  }

  void _deleteMoment(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le moment'),
        content: Text(
            'Veux-tu vraiment supprimer le moment "${_moments[index].name}" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              await MomentService.delete(_moments[index].id!);
              Navigator.pop(context);
              await _loadData();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ---- Réjouissances ----

  void _addReward() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const RewardEditDialog(),
    );
    if (result != null) {
      final reward = Reward(
        title: result['title'],
        cost: result['cost'],
        uniqueReward: result['unique'],
        requiresNote: result['requires_note'],
      );
      await RewardService.insert(reward);
      await _loadData();
    }
  }

  void _editReward(int index) async {
    final reward = _rewards[index];
    final contributed = _contributedByReward[reward.id] ?? 0;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => RewardEditDialog(
        rewardTitle: reward.title,
        rewardCost: reward.cost,
        rewardUnique: reward.uniqueReward,
        rewardRequiresNote: reward.requiresNote,
        minCost: contributed,
      ),
    );
    if (result != null) {
      final newCost = result['cost'] as int;
      final updated = Reward(
        id: reward.id,
        title: result['title'],
        cost: newCost,
        uniqueReward: result['unique'],
        requiresNote: result['requires_note'],
        active: reward.active,
      );
      await RewardService.update(updated);

      // Si le montant contribué atteint le nouveau coût, la réjouissance est obtenue
      if (contributed >= newCost) {
        await RewardService.redeem(reward.id!, newCost, null);
      }

      await _loadData();
    }
  }

  void _deleteReward(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la réjouissance'),
        content: Text(
            'Veux-tu vraiment supprimer la réjouissance "${_rewards[index].title}" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              await RewardService.delete(_rewards[index].id!);
              Navigator.pop(context);
              await _loadData();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _toggleRewardActive(int index, bool active) async {
    final reward = _rewards[index];
    if (active) {
      await RewardService.reactivate(reward.id!);
    } else {
      await RewardService.deactivate(reward.id!);
    }
    await _loadData();
  }

  // ---- Synchronisation ----

  void _saveIcsUrl() async {
    await ConfigService.setIcsUrl(_icsController.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adresse ICS enregistrée.')),
    );
  }

  void _syncNow() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Synchronisation bientôt disponible.')),
    );
  }

  void _savePin(String pin) {
    ConfigService.setParentPin(pin);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code PIN modifié.')),
    );
    _pinKey.currentState?.clear();
  }

  void _saveMessages() async {
    await ConfigService.setMessages([
      _message1Controller.text.trim(),
      _message2Controller.text.trim(),
      _message3Controller.text.trim(),
      _message4Controller.text.trim(),
      _message5Controller.text.trim(),
    ]);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Messages enregistrés.')),
    );
  }

  void _changeMaxObtenues(int delta) async {
    final newValue = _maxObtenues + delta;
    if (newValue < 1 || newValue > 10) return;
    setState(() => _maxObtenues = newValue);
    await ConfigService.setMaxObtenues(newValue);
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _buildMembersSection(),
                  const SizedBox(height: 24),
                  _buildMomentsSection(),
                  const SizedBox(height: 24),
                  _buildRewardsSection(),
                  const SizedBox(height: 24),
                  _buildSyncSection(),
                  const SizedBox(height: 24),
                  _buildSecuritySection(),
                  const SizedBox(height: 24),
                  _buildEncouragementSection(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Sections ----

  Widget _buildMembersSection() {
    return _buildSection(
      title: '👨‍👩‍👧‍👦 Membres',
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        onPressed: _addMember,
        tooltip: 'Ajouter un membre',
      ),
      children: [for (var i = 0; i < _members.length; i++) _buildMemberTile(i)],
    );
  }

  Widget _buildMemberTile(int index) {
    final m = _members[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: m.color.withValues(alpha: 0.2),
          child: Text(m.avatar, style: const TextStyle(fontSize: 22)),
        ),
        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: m.pause
            ? Text('En pause', style: TextStyle(color: Colors.orange.shade700, fontSize: 12))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                m.pause ? Icons.play_arrow : Icons.pause_circle_outline,
                color: m.pause ? Colors.orange : Colors.grey,
              ),
              tooltip: m.pause ? 'Réactiver' : 'Mettre en pause',
              onPressed: () => _togglePause(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Supprimer',
              onPressed: () => _deleteMember(index),
            ),
          ],
        ),
        onTap: () => _editMember(index),
      ),
    );
  }

  Widget _buildMomentsSection() {
    return _buildSection(
      title: '⏰ Moments de la journée',
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        onPressed: _addMoment,
        tooltip: 'Ajouter un moment',
      ),
      children: [
        for (var i = 0; i < _moments.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(_moments[i].name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Heure de fin : ${_moments[i].heureDeFin}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Supprimer',
                onPressed: () => _deleteMoment(i),
              ),
              onTap: () => _editMoment(i),
            ),
          ),
      ],
    );
  }

  Widget _buildRewardsSection() {
    return _buildSection(
      title: '🏆 Réjouissances',
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        onPressed: _addReward,
        tooltip: 'Ajouter une réjouissance',
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              const Text('Nb obtenues affichées : ', style: TextStyle(fontSize: 14)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _maxObtenues > 1 ? () => _changeMaxObtenues(-1) : null,
              ),
              Text('$_maxObtenues',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _changeMaxObtenues(1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        for (var i = 0; i < _rewards.length; i++) _buildRewardTile(i),
      ],
    );
  }

  Widget _buildRewardTile(int index) {
    final r = _rewards[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Icon(
          r.active ? Icons.star_rounded : Icons.star_border_rounded,
          color: r.active ? Colors.amber : Colors.grey,
        ),
        title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${r.cost} ⭐${r.uniqueReward ? " • Unique" : ""}${r.requiresNote ? " • Note requise" : ""}${!r.active ? " • Masquée" : ""}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: r.active,
              onChanged: (value) => _toggleRewardActive(index, value),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Supprimer',
              onPressed: () => _deleteReward(index),
            ),
          ],
        ),
        onTap: () => _editReward(index),
      ),
    );
  }

  Widget _buildSyncSection() {
    return _buildSection(
      title: '🔄 Synchronisation ICS',
      children: [
        const SizedBox(height: 8),
        TextField(
          controller: _icsController,
          decoration: const InputDecoration(
            labelText: 'Adresse du fichier ICS',
            hintText: 'https://...',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _saveIcsUrl,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Enregistrer'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _syncNow,
                icon: const Icon(Icons.sync),
                label: const Text('Synchroniser'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return _buildSection(
      title: '🔒 Code PIN parental',
      children: [
        const SizedBox(height: 8),
        const Text('Nouveau code PIN (4 chiffres) :', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        PinInputWidget(key: _pinKey, onComplete: _savePin),
      ],
    );
  }

  Widget _buildEncouragementSection() {
    return _buildSection(
      title: '💬 Messages d\'encouragement',
      children: [
        const SizedBox(height: 4),
        Text(
          'Ces 5 messages apparaîtront quand un membre termine toutes ses tâches.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        for (var i = 1; i <= 5; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: i == 1
                  ? _message1Controller
                  : i == 2
                      ? _message2Controller
                      : i == 3
                          ? _message3Controller
                          : i == 4
                              ? _message4Controller
                              : _message5Controller,
              decoration: InputDecoration(
                labelText: 'Message $i',
                border: const OutlineInputBorder(),
              ),
              maxLength: 100,
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _saveMessages,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Enregistrer les messages'),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (trailing != null) trailing,
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

// ---- Widget PIN ----

class PinInputWidget extends StatefulWidget {
  const PinInputWidget({super.key, required this.onComplete});
  final void Function(String pin) onComplete;
  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget> {
  final List<String?> _digits = List.filled(4, null);
  int _currentIndex = 0;

  void _addDigit(String digit) {
    if (_currentIndex >= 4) return;
    setState(() {
      _digits[_currentIndex] = digit;
      _currentIndex++;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _currentIndex > 0) setState(() {});
    });
  }

  void _removeDigit() {
    if (_currentIndex == 0) return;
    setState(() {
      _currentIndex--;
      _digits[_currentIndex] = null;
    });
  }

  void _clear() {
    setState(() {
      for (var i = 0; i < 4; i++) {
        _digits[i] = null;
      }
      _currentIndex = 0;
    });
  }

  void clear() => _clear();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final isActive = index == _currentIndex;
            return Container(
              width: 48,
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade300,
                  width: isActive ? 2 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: _digits[index] != null
                  ? Text(_digits[index]!,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
                  : Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.grey.shade400 : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
            );
          }),
        ),
        const SizedBox(height: 16),
        _buildNumpad(),
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
          _buildBackspaceKey(), const SizedBox(width: 8),
          _buildKey('0'), const SizedBox(width: 8),
          _buildDoneKey(),
        ]),
      ],
    );
  }

  Widget _buildKey(String digit) => SizedBox(
        width: 64,
        height: 52,
        child: Material(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _addDigit(digit),
            child: Center(
                child: Text(digit,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500))),
          ),
        ),
      );

  Widget _buildBackspaceKey() => SizedBox(
        width: 64,
        height: 52,
        child: Material(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _removeDigit,
            child: const Center(child: Icon(Icons.backspace_outlined, size: 24)),
          ),
        ),
      );

  Widget _buildDoneKey() => SizedBox(
        width: 64,
        height: 52,
        child: Material(
          color: _currentIndex == 4 ? Theme.of(context).primaryColor : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _currentIndex == 4
                ? () {
                    widget.onComplete(_digits.whereType<String>().join());
                  }
                : null,
            child: const Center(child: Icon(Icons.check, color: Colors.white, size: 24)),
          ),
        ),
      );
}