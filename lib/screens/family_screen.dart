import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/member.dart';
import '../models/task.dart';
import '../widgets/header.dart';
import '../widgets/member_column.dart';
import 'settings_screen.dart';

/// Page d'accueil : vue familiale des tâches.
class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  static const double _landscapeTargetSlots = 3.3;
  static const double _landscapeMinColumnWidth = 260;

  static const double _portraitPeekStartWidth = 450;
  static const double _portraitPeekFullWidth = 900;
  static const double _portraitMaxPeekFraction = 0.45;

  static const double _limitedHeightThreshold = 550;

  static const List<String> moments = [
    'Matin', 'Temps de midi', 'Après-midi', 'Soirée', 'Fin de soirée',
  ];

  PageController? _pageController;
  double? _pageControllerViewportFraction;
  int _currentPage = 0;
  bool? _lastIsLandscape;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  final List<FamilyMember> members = [
    FamilyMember(name: 'Marie', avatar: '👩', color: Colors.blue, stars: 24, tasks: [
      const TaskItem(title: 'Ranger la cuisine', description: 'Mettre les affaires à leur place.', stars: 3, moment: 'Matin'),
      const TaskItem(title: 'Sortir les poubelles', stars: 2, moment: 'Matin'),
      const TaskItem(title: 'Préparer le repas', stars: 4, moment: 'Temps de midi', completed: true),
      const TaskItem(title: 'Faire une promenade', description: 'Au moins 20 minutes.', stars: 2, moment: 'Après-midi'),
      const TaskItem(title: 'Ranger sa chambre', stars: 3, moment: 'Soirée'),
    ]),
    FamilyMember(name: 'Antoine', avatar: '👨', color: Colors.green, stars: 18, tasks: [
      const TaskItem(title: 'Faire son lit', stars: 2, moment: 'Matin', completed: true),
      const TaskItem(title: 'Ranger sa chambre', stars: 3, moment: 'Matin'),
      const TaskItem(title: 'Débarrasser la table', stars: 2, moment: 'Temps de midi'),
      const TaskItem(title: 'Sortir les poubelles', stars: 3, moment: 'Après-midi'),
      const TaskItem(title: 'Préparer ses affaires', description: 'Préparer les affaires du lendemain.', stars: 2, moment: 'Soirée'),
    ]),
    FamilyMember(name: 'Mimi', avatar: '👧', color: Colors.pink, stars: 31, tasks: [
      const TaskItem(title: 'Faire son lit', stars: 2, moment: 'Matin', completed: true),
      const TaskItem(title: "S'habiller", stars: 2, moment: 'Matin'),
      const TaskItem(title: 'Mettre la table', stars: 2, moment: 'Temps de midi', completed: true),
      const TaskItem(title: 'Ranger ses affaires', stars: 3, moment: 'Après-midi'),
      const TaskItem(title: 'Préparer son cartable', stars: 2, moment: 'Soirée'),
    ]),
    FamilyMember(name: 'Alex', avatar: '👦', color: Colors.orange, stars: 15, tasks: [
      const TaskItem(title: 'Faire son lit', stars: 2, moment: 'Matin'),
      const TaskItem(title: "S'habiller", stars: 2, moment: 'Matin'),
      const TaskItem(title: 'Débarrasser la table', stars: 2, moment: 'Temps de midi'),
      const TaskItem(title: 'Ranger les jeux', stars: 3, moment: 'Après-midi', completed: true),
      const TaskItem(title: 'Préparer ses affaires', stars: 2, moment: 'Soirée'),
    ]),
  ];

  String get currentMoment {
    final now = DateTime.now();
    final time = now.hour * 60 + now.minute;
    if (time < 10 * 60 + 30) return 'Matin';
    if (time < 13 * 60) return 'Temps de midi';
    if (time < 18 * 60) return 'Après-midi';
    if (time < 19 * 60 + 30) return 'Soirée';
    return 'Fin de soirée';
  }

  int get totalTasks => members.fold(0, (total, member) => total + member.tasks.length);
  int get completedTasks => members.fold(0, (total, member) => total + member.tasks.where((t) => t.completed).length);
  double get progress => totalTasks == 0 ? 0 : completedTasks / totalTasks;

  void toggleTask(int memberIndex, int taskIndex) {
    final member = members[memberIndex];
    final oldTask = member.tasks[taskIndex];
    final wasCompleted = oldTask.completed;

    setState(() {
      final updatedTasks = List<TaskItem>.from(member.tasks);
      updatedTasks[taskIndex] = TaskItem(title: oldTask.title, stars: oldTask.stars, moment: oldTask.moment, description: oldTask.description, completed: !wasCompleted);
      final newStars = wasCompleted ? member.stars - oldTask.stars : member.stars + oldTask.stars;
      members[memberIndex] = FamilyMember(name: member.name, avatar: member.avatar, color: member.color, stars: newStars, tasks: updatedTasks);

      if (!wasCompleted && updatedTasks.every((t) => t.completed)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showCongrats(member.name));
      }
    });
  }

  void _showCongrats(String name) {
    final messages = SettingsScreen.encouragementMessages;
    final message = messages.isNotEmpty ? messages[DateTime.now().millisecondsSinceEpoch % messages.length] : '$name a terminé toutes ses tâches du jour !';
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('🎉 Bravo !'), content: Text(message, style: const TextStyle(fontSize: 16)), actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Super !'))]));
  }

  double _landscapeViewportFraction(double width) {
    final maxReadableSlots = width / _landscapeMinColumnWidth;
    final slots = math.max(1.0, math.min(_landscapeTargetSlots, math.min(members.length.toDouble(), maxReadableSlots)));
    return 1 / slots;
  }

  double _portraitViewportFraction(double width) {
    if (width <= _portraitPeekStartWidth) return 1.0;
    final rawT = (width - _portraitPeekStartWidth) / (_portraitPeekFullWidth - _portraitPeekStartWidth);
    final t = math.min(1.0, math.max(0.0, rawT));
    return 1.0 - _portraitMaxPeekFraction * t;
  }

  PageController _resolvePageController(double viewportFraction, bool isLandscape) {
    final orientationChanged = _lastIsLandscape != null && _lastIsLandscape != isLandscape;
    _lastIsLandscape = isLandscape;
    final needsNewController = _pageController == null || orientationChanged || (_pageControllerViewportFraction! - viewportFraction).abs() > 0.01;
    if (needsNewController) {
      _pageController?.dispose();
      _pageController = PageController(viewportFraction: viewportFraction, initialPage: _currentPage);
      _pageControllerViewportFraction = viewportFraction;
    }
    return _pageController!;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final isCompact = constraints.maxHeight < _limitedHeightThreshold;
        final viewportFraction = isLandscape ? _landscapeViewportFraction(constraints.maxWidth) : _portraitViewportFraction(constraints.maxWidth);

        return Column(
          children: [
            HeaderWidget(date: today, currentMoment: currentMoment, completedTasks: completedTasks, totalTasks: totalTasks, progress: progress, isCompact: isCompact, onMenuPressed: () => Scaffold.of(context).openDrawer()),
            Expanded(child: _buildFamilyMembers(viewportFraction: viewportFraction, isLandscape: isLandscape)),
          ],
        );
      },
    );
  }

  Widget _buildFamilyMembers({required double viewportFraction, required bool isLandscape}) {
    final controller = _resolvePageController(viewportFraction, isLandscape);
    final isSingleColumn = viewportFraction >= 0.99;

    return PageView.builder(
      controller: controller, padEnds: false, onPageChanged: (page) => _currentPage = page, itemCount: members.length,
      itemBuilder: (context, index) => Padding(padding: EdgeInsets.symmetric(horizontal: isSingleColumn ? 5 : 8, vertical: 4), child: MemberColumn(member: members[index], moments: moments, currentMoment: currentMoment, onToggleTask: (taskIndex) => toggleTask(index, taskIndex))),
    );
  }
}