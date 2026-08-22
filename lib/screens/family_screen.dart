import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/member.dart';
import '../models/task.dart';
import '../services/member_service.dart';
import '../services/task_service.dart';
import '../services/moment_service.dart';
import '../services/config_service.dart';
import '../widgets/family_header.dart';
import '../widgets/member_column.dart';

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

  final GlobalKey<FamilyHeaderState> _headerKey = GlobalKey<FamilyHeaderState>();

  PageController? _pageController;
  double? _pageControllerViewportFraction;
  int _currentPage = 0;
  bool? _lastIsLandscape;

  List<FamilyMember> _members = [];
  List<Moment> _momentList = [];
  Map<int, List<TaskItem>> _tasksByMember = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final members = await MemberService.getActive();
      final moments = await MomentService.getAll();
      final tasksByMember = <int, List<TaskItem>>{};
      for (final member in members) {
        tasksByMember[member.id!] =
            await TaskService.getByMemberAndDate(member.id!, dateStr);
      }

      setState(() {
        _members = members;
        _momentList = moments;
        _tasksByMember = tasksByMember;
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

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  String? _momentName(int? momentId) {
    if (momentId == null) return null;
    for (final m in _momentList) {
      if (m.id == momentId) return m.name;
    }
    return null;
  }

  List<FamilyMember> get members {
    return _members.map((member) {
      final tasks = (_tasksByMember[member.id] ?? []).map((task) {
        return task.copyWith(moment: _momentName(task.momentId));
      }).toList();
      return member.copyWith(tasks: tasks);
    }).toList();
  }

  List<String> get moments => _momentList.map((m) => m.name).toList();

  void toggleTask(int memberIndex, int taskIndex) async {
    final member = members[memberIndex];
    final task = member.tasks[taskIndex];
    final wasCompleted = task.completed;

    await TaskService.toggleComplete(task.id!, !wasCompleted);

    final newStars = wasCompleted
        ? member.stars - task.stars
        : member.stars + task.stars;
    await MemberService.updateStars(member.id!, newStars);

    await _loadData();
    _headerKey.currentState?.reload();

    if (!wasCompleted) {
      final memberTasks = _tasksByMember[member.id] ?? [];
      if (memberTasks.every((t) => t.completed)) {
        _showCongrats(member.name);
      }
    }
  }

  void _showCongrats(String name) async {
    final messages = await ConfigService.getMessages();
    final message = messages.isNotEmpty
        ? messages[DateTime.now().millisecondsSinceEpoch % messages.length]
        : '$name a terminé toutes ses tâches du jour !';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Bravo !'),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Super !'),
          ),
        ],
      ),
    );
  }

  double _landscapeViewportFraction(double width) {
    final maxReadableSlots = width / _landscapeMinColumnWidth;
    final slots = math.max(
        1.0,
        math.min(_landscapeTargetSlots,
            math.min(members.length.toDouble(), maxReadableSlots)));
    return 1 / slots;
  }

  double _portraitViewportFraction(double width) {
    if (width <= _portraitPeekStartWidth) return 1.0;
    final rawT = (width - _portraitPeekStartWidth) /
        (_portraitPeekFullWidth - _portraitPeekStartWidth);
    final t = math.min(1.0, math.max(0.0, rawT));
    return 1.0 - _portraitMaxPeekFraction * t;
  }

  PageController _resolvePageController(
      double viewportFraction, bool isLandscape) {
    final orientationChanged =
        _lastIsLandscape != null && _lastIsLandscape != isLandscape;
    _lastIsLandscape = isLandscape;
    final needsNewController = _pageController == null ||
        orientationChanged ||
        (_pageControllerViewportFraction! - viewportFraction).abs() > 0.01;
    if (needsNewController) {
      _pageController?.dispose();
      _pageController = PageController(
          viewportFraction: viewportFraction, initialPage: _currentPage);
      _pageControllerViewportFraction = viewportFraction;
    }
    return _pageController!;
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
              const Text('Erreur de chargement',
                  style: TextStyle(fontSize: 18)),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final viewportFraction = isLandscape
            ? _landscapeViewportFraction(constraints.maxWidth)
            : _portraitViewportFraction(constraints.maxWidth);

        return Column(
          children: [
            FamilyHeader(key: _headerKey),
            Expanded(
              child: _buildFamilyMembers(
                viewportFraction: viewportFraction,
                isLandscape: isLandscape,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFamilyMembers({
    required double viewportFraction,
    required bool isLandscape,
  }) {
    final controller = _resolvePageController(viewportFraction, isLandscape);
    final isSingleColumn = viewportFraction >= 0.99;

    if (members.isEmpty) {
      return const Center(
        child: Text('Aucun membre',
            style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    return PageView.builder(
      controller: controller,
      padEnds: false,
      onPageChanged: (page) => _currentPage = page,
      itemCount: members.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSingleColumn ? 5 : 8,
            vertical: 4,
          ),
          child: MemberColumn(
            member: members[index],
            moments: moments,
            currentMoment: _currentMomentName(),
            onToggleTask: (taskIndex) => toggleTask(index, taskIndex),
          ),
        );
      },
    );
  }

  String _currentMomentName() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    String? currentMoment;
    for (final moment in _momentList) {
      final parts = moment.heureDeFin.split(':');
      if (parts.length == 2) {
        final endMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
        if (currentMinutes < endMinutes) {
          currentMoment = moment.name;
          break;
        }
      }
    }

    if (currentMoment == null && _momentList.isNotEmpty) {
      currentMoment = _momentList.last.name;
    }

    return currentMoment ?? 'Soirée';
  }
}