import 'package:flutter/material.dart';
import '../models/member.dart';
import '../services/member_service.dart';
import '../services/moment_service.dart';
import '../services/reward_service.dart';
import '../services/config_service.dart';
import '../services/ics_service.dart';
import '../services/database_helper.dart';
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
  Map<int, bool> _hasHistory = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  int _maxObtenues = 3;
  int _maxObtenuesLimit = 50;
  int _syncErrorCount = 0;

  Map<String, String?> _lastSync = {
    'at': null,
    'status': null,
    'message': null,
  };

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
      final maxObtenuesLimit = await ConfigService.getMaxObtenuesLimit();
      final messages = await ConfigService.getMessages();
      final lastSync = await ConfigService.getLastSync();

      // Compte les entrées dans sync_errors
      final db = await DatabaseHelper.instance.database;
      final errorResult = await db.rawQuery('SELECT COUNT(*) as count FROM sync_errors');
      final syncErrorCount = errorResult.first['count'] as int? ?? 0;

      final contributedByReward = <int, int>{};
      for (final reward in rewards) {
        final contributions = await RewardService.getContributions(reward.id!);
        final activeContributions = contributions.where((c) => c.redemptionId == null);
        final total = activeContributions.fold(0, (sum, c) => sum + c.stars);
        contributedByReward[reward.id!] = total;
      }

      final hasHistory = <int, bool>{};
      for (final member in members) {
        hasHistory[member.id!] = await MemberService.hasHistory(member.id!);
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
        _hasHistory = hasHistory;
        _maxObtenues = maxObtenues;
        _maxObtenuesLimit = maxObtenuesLimit;
        _syncErrorCount = syncErrorCount;
        _lastSync = lastSync;
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
        content: Text('Veux-tu vraiment supprimer ${_members[index].name} ?'),
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
      final heure = result['heure_de_fin'] as String;
      final isTaken = await MomentService.isHeureDeFinTaken(heure);
      if (isTaken) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cette heure est déjà utilisée par un autre moment.')),
          );
        }
        return;
      }
      final moment = Moment(name: result['name'], heureDeFin: heure);
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
      final heure = result['heure_de_fin'] as String;
      final isTaken = await MomentService.isHeureDeFinTaken(heure, excludeId: moment.id);
      if (isTaken) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cette heure est déjà utilisée par un autre moment.')),
          );
        }
        return;
      }
      final updated = Moment(
        id: moment.id,
        name: result['name'],
        heureDeFin: heure,
      );
      await MomentService.update(updated);
      await _loadData();
    }
  }

  void _deleteMoment(int index) async {
    final moment = _moments[index];

    if (_moments.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de supprimer le dernier moment.')),
      );
      return;
    }

    final taskCount = await MomentService.countTasks(moment.id!);

    if (taskCount == 0) {
      _confirmDeleteMoment(moment);
    } else {
      _chooseDestinationAndDelete(moment, taskCount);
    }
  }

  void _confirmDeleteMoment(Moment moment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le moment'),
        content: Text('Veux-tu vraiment supprimer le moment "${moment.name}" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              await MomentService.delete(moment.id!);
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

  void _chooseDestinationAndDelete(Moment moment, int taskCount) {
    final destinations = _moments.where((m) => m.id != moment.id).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déplacer les tâches'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ce moment contient $taskCount tâche${taskCount > 1 ? 's' : ''}.\n'
              'Vers quel moment veux-tu les déplacer ?',
            ),
            const SizedBox(height: 16),
            for (final dest in destinations)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await MomentService.moveTasks(moment.id!, dest.id!);
                    await MomentService.delete(moment.id!);
                    await _loadData();
                  },
                  child: Text(dest.name),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
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
      final requiresNote = result['requires_note'] as bool;
      final updated = Reward(
        id: reward.id,
        title: result['title'],
        cost: newCost,
        uniqueReward: result['unique'],
        requiresNote: requiresNote,
        active: reward.active,
      );
      await RewardService.update(updated);

      if (contributed >= newCost) {
        if (requiresNote) {
          _showNoteDialog(reward, newCost);
        } else {
          await RewardService.redeem(reward.id!, newCost, null);
        }
      }

      await _loadData();
    }
  }

  void _showNoteDialog(Reward reward, int cost) {
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
              _redeemWithNote(reward, cost, null);
            },
            child: const Text('Passer'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _redeemWithNote(reward, cost, noteController.text.trim());
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _redeemWithNote(Reward reward, int cost, String? note) async {
    await RewardService.redeem(reward.id!, cost, note);
    await _loadData();
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

  Future<void> _syncNow() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Synchronisation en cours...')),
    );

    final eventCount = await IcsService.sync();

    if (!mounted) return;

    final lastSync = await ConfigService.getLastSync();
    final errorCount = _extractErrorCount(lastSync['message']);

    String message;
    if (eventCount == 0 && errorCount == 0) {
      message = 'Aucun événement à synchroniser aujourd\'hui.';
    } else if (errorCount == 0) {
      message = '$eventCount événement(s) synchronisé(s).';
    } else {
      message =
          '$eventCount événement(s) synchronisé(s), $errorCount en erreur.';
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    await _loadData();
  }

  int _extractErrorCount(String? message) {
    if (message == null || message.isEmpty) return 0;
    final match = RegExp(r'(\d+)').firstMatch(message);
    if (match == null) return 0;
    return int.tryParse(match.group(1)!) ?? 0;
  }

  Future<void> _showErrorJournal() async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query('sync_errors', orderBy: 'id ASC');

    if (!mounted) return;

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune erreur enregistrée.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Journal des erreurs'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final row = results[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ ${row['event_title']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      row['error_message'] as String,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
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
    if (newValue < 1 || newValue > _maxObtenuesLimit) return;
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
    final hasHistory = _hasHistory[m.id] ?? false;

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
            if (!hasHistory)
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
        Text(
          'Pour ajouter un moment entre deux existants, modifie d\'abord l\'heure de fin '
          'du moment qui précède pour libérer un créneau.\n'
          'Chaque moment doit avoir une heure de fin unique.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 16),
        _buildSyncStatus(),
      ],
    );
  }

  Widget _buildSyncStatus() {
    final status = _lastSync['status'];
    final message = _lastSync['message'] ?? '';
    final at = _lastSync['at'];

    if (status == null) {
      return Text(
        'Aucune synchronisation effectuée pour le moment.',
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      );
    }

    String formattedDate = '';
    if (at != null) {
      final date = DateTime.tryParse(at);
      if (date != null) {
        formattedDate =
            '${date.day}/${date.month}/${date.year} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
      }
    }

    Color color;
    IconData icon;
    String label;

    // Le bouton apparaît dès qu'il y a des entrées dans sync_errors
    final showDetails = _syncErrorCount > 0;

    switch (status) {
      case 'success':
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Aucune erreur détectée.';
        break;
      case 'partial':
        color = Colors.orange;
        icon = Icons.warning_amber_rounded;
        label = message.isNotEmpty ? message : 'Certains événements ont échoué.';
        break;
      case 'failed':
        color = Colors.red;
        icon = Icons.error_outline;
        label = message.isNotEmpty ? message : 'Synchronisation échouée.';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
        label = 'Statut inconnu.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dernière synchronisation : $formattedDate',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showDetails) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _showErrorJournal,
                icon: const Icon(Icons.list, size: 18),
                label: const Text('Voir le détail'),
              ),
            ),
          ],
        ],
      ),
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