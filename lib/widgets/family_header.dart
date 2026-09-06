import 'package:flutter/material.dart';
import '../services/member_service.dart';
import '../services/task_service.dart';
import '../services/moment_service.dart';

/// Header commun à tous les écrans.
///
/// Affiche la date, le moment actuel et la progression familiale.
/// Charge automatiquement les données depuis la base.
class FamilyHeader extends StatefulWidget {
  const FamilyHeader({super.key});

  @override
  State<FamilyHeader> createState() => FamilyHeaderState();
}

class FamilyHeaderState extends State<FamilyHeader> {
  int _totalTasks = 0;
  int _completedTasks = 0;
  double _progress = 0;
  List<Moment> _moments = [];

  @override
  void initState() {
    super.initState();
    reload();
  }

  /// Recharge la progression et les moments.
  Future<void> reload() async {
    await _loadProgress();
    await _loadMoments();
  }

  /// Charge les tâches du jour pour calculer la progression.
  Future<void> _loadProgress() async {
    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final members = await MemberService.getActive();
      var total = 0;
      var completed = 0;

      for (final member in members) {
        final tasks = await TaskService.getByMemberAndDate(member.id!, dateStr);
        total += tasks.length;
        completed += tasks.where((t) => t.completed).length;
      }

      if (mounted) {
        setState(() {
          _totalTasks = total;
          _completedTasks = completed;
          _progress = total == 0 ? 0 : completed / total;
        });
      }
    } catch (e) {
      // Silencieux : le header reste avec zéro
    }
  }

  /// Charge les moments pour calculer le moment actuel.
  Future<void> _loadMoments() async {
    try {
      final moments = await MomentService.getAll();
      if (mounted) {
        setState(() {
          _moments = moments;
        });
      }
    } catch (e) {
      // Silencieux
    }
  }

  /// Calcule le moment actuel à partir des moments en base.
  String get currentMoment {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    String? found;
    for (final moment in _moments) {
      final parts = moment.heureDeFin.split(':');
      if (parts.length == 2) {
        final endMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
        if (currentMinutes < endMinutes) {
          found = moment.name;
          break;
        }
      }
    }

    if (found == null && _moments.isNotEmpty) {
      found = _moments.last.name;
    }

    return found ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 550;
        final horizontalPadding = isCompact ? 10.0 : 16.0;
        final verticalPadding = isCompact ? 5.0 : 6.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, verticalPadding,
              horizontalPadding, isCompact ? 5 : 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date + moment
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${today.day} ${months[today.month - 1]} ${today.year}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentMoment,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600),
                  ),
                ],
              ),
              SizedBox(width: isCompact ? 8 : 16),
              // Progression
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Progression de la famille',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_completedTasks / $_totalTasks',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompact) ...[
                const SizedBox(width: 5),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 24,
                    tooltip: 'Menu',
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(Icons.menu_rounded),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}