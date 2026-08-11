import 'package:flutter/material.dart';
import '../models/member.dart';
import '../models/task.dart';
import '../widgets/header.dart';
import '../widgets/bottom_menu.dart';
import '../widgets/member_column.dart';

/// Page d'accueil : vue familiale des tâches.
///
/// Affiche le header, les colonnes des membres et le menu inférieur.
/// Contient la logique métier (moments, progression, validation).
class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  // Largeur cible d'une colonne membre
  static const double _memberColumnWidth = 360;

  // En dessous de cette hauteur, le menu disparaît et le menu sandwich apparaît
  static const double _limitedHeightThreshold = 400;

  // Liste des moments de la journée
  static const List<String> moments = [
    'Matin',
    'Temps de midi',
    'Après-midi',
    'Soirée',
    'Fin de soirée',
  ];

  // Contrôleur du PageView, créé une seule fois et recréé si nécessaire
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Données des membres et leurs tâches
  final List<FamilyMember> members = [
    FamilyMember(
      name: 'Marie',
      avatar: '👩',
      color: Colors.blue,
      stars: 24,
      tasks: [
        const TaskItem(
          title: 'Ranger la cuisine',
          description: 'Mettre les affaires à leur place.',
          stars: 3,
          moment: 'Matin',
        ),
        const TaskItem(
          title: 'Sortir les poubelles',
          stars: 2,
          moment: 'Matin',
        ),
        const TaskItem(
          title: 'Préparer le repas',
          stars: 4,
          moment: 'Temps de midi',
          completed: true,
        ),
        const TaskItem(
          title: 'Faire une promenade',
          description: 'Au moins 20 minutes.',
          stars: 2,
          moment: 'Après-midi',
        ),
        const TaskItem(
          title: 'Ranger sa chambre',
          stars: 3,
          moment: 'Soirée',
        ),
      ],
    ),
    FamilyMember(
      name: 'Antoine',
      avatar: '👨',
      color: Colors.green,
      stars: 18,
      tasks: [
        const TaskItem(
          title: 'Faire son lit',
          stars: 2,
          moment: 'Matin',
          completed: true,
        ),
        const TaskItem(
          title: 'Ranger sa chambre',
          stars: 3,
          moment: 'Matin',
        ),
        const TaskItem(
          title: 'Débarrasser la table',
          stars: 2,
          moment: 'Temps de midi',
        ),
        const TaskItem(
          title: 'Sortir les poubelles',
          stars: 3,
          moment: 'Après-midi',
        ),
        const TaskItem(
          title: 'Préparer ses affaires',
          description: 'Préparer les affaires du lendemain.',
          stars: 2,
          moment: 'Soirée',
        ),
      ],
    ),
    FamilyMember(
      name: 'Mimi',
      avatar: '👧',
      color: Colors.pink,
      stars: 31,
      tasks: [
        const TaskItem(
          title: 'Faire son lit',
          stars: 2,
          moment: 'Matin',
          completed: true,
        ),
        const TaskItem(
          title: "S'habiller",
          stars: 2,
          moment: 'Matin',
        ),
        const TaskItem(
          title: 'Mettre la table',
          stars: 2,
          moment: 'Temps de midi',
          completed: true,
        ),
        const TaskItem(
          title: 'Ranger ses affaires',
          stars: 3,
          moment: 'Après-midi',
        ),
        const TaskItem(
          title: 'Préparer son cartable',
          stars: 2,
          moment: 'Soirée',
        ),
      ],
    ),
    FamilyMember(
      name: 'Alex',
      avatar: '👦',
      color: Colors.orange,
      stars: 15,
      tasks: [
        const TaskItem(
          title: 'Faire son lit',
          stars: 2,
          moment: 'Matin',
        ),
        const TaskItem(
          title: "S'habiller",
          stars: 2,
          moment: 'Matin',
        ),
        const TaskItem(
          title: 'Débarrasser la table',
          stars: 2,
          moment: 'Temps de midi',
        ),
        const TaskItem(
          title: 'Ranger les jeux',
          stars: 3,
          moment: 'Après-midi',
          completed: true,
        ),
        const TaskItem(
          title: 'Préparer ses affaires',
          stars: 2,
          moment: 'Soirée',
        ),
      ],
    ),
  ];

  // ---- Logique métier ----

  /// Détermine le moment actuel en fonction de l'heure
  String get currentMoment {
    final now = DateTime.now();
    final time = now.hour * 60 + now.minute;

    if (time < 10 * 60 + 30) return 'Matin';
    if (time < 13 * 60) return 'Temps de midi';
    if (time < 18 * 60) return 'Après-midi';
    if (time < 19 * 60 + 30) return 'Soirée';
    return 'Fin de soirée';
  }

  /// Nombre total de tâches (tous membres confondus)
  int get totalTasks {
    return members.fold(
      0,
      (total, member) => total + member.tasks.length,
    );
  }

  /// Nombre de tâches terminées (tous membres confondus)
  int get completedTasks {
    return members.fold(
      0,
      (total, member) =>
          total + member.tasks.where((task) => task.completed).length,
    );
  }

  /// Progression entre 0.0 et 1.0
  double get progress {
    if (totalTasks == 0) return 0;
    return completedTasks / totalTasks;
  }

  /// Valide ou dévalide une tâche et met à jour le solde d'étoiles
  void toggleTask(int memberIndex, int taskIndex) {
    final member = members[memberIndex];
    final oldTask = member.tasks[taskIndex];
    final wasCompleted = oldTask.completed;

    setState(() {
      // Met à jour la tâche
      final updatedTasks = List<TaskItem>.from(member.tasks);
      updatedTasks[taskIndex] = TaskItem(
        title: oldTask.title,
        stars: oldTask.stars,
        moment: oldTask.moment,
        description: oldTask.description,
        completed: !wasCompleted,
      );

      // Calcule le nouveau solde d'étoiles
      final newStars = wasCompleted
          ? member.stars - oldTask.stars  // On décoche : on retire les étoiles
          : member.stars + oldTask.stars; // On coche : on ajoute les étoiles

      members[memberIndex] = FamilyMember(
        name: member.name,
        avatar: member.avatar,
        color: member.color,
        stars: newStars,
        tasks: updatedTasks,
      );
    });
  }

  // ---- Construction de la page ----

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            final width = constraints.maxWidth;
            final isCompact = height < _limitedHeightThreshold;

            return Column(
              children: [
                // ---- HEADER ----
                HeaderWidget(
                  date: today,
                  currentMoment: currentMoment,
                  completedTasks: completedTasks,
                  totalTasks: totalTasks,
                  progress: progress,
                  isCompact: isCompact,
                  onMenuPressed: () {
                    // Futur menu
                  },
                ),

                // ---- CORPS : colonnes des membres ----
                Expanded(
                  child: _buildFamilyMembers(availableWidth: width),
                ),

                // ---- MENU INFÉRIEUR ----
                if (!isCompact) const BottomMenu(),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Construit le défilement horizontal des colonnes membres
  Widget _buildFamilyMembers({required double availableWidth}) {
    final viewportFraction =
        (_memberColumnWidth / availableWidth).clamp(0.25, 1.0);

    // Recrée le contrôleur uniquement si le viewportFraction a changé
    if (_pageController.viewportFraction != viewportFraction) {
      _pageController.dispose();
      _pageController = PageController(viewportFraction: viewportFraction);
    }

    return PageView.builder(
      controller: _pageController,
      padEnds: false,
      itemCount: members.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: availableWidth <= _memberColumnWidth ? 5 : 8,
            vertical: 4,
          ),
          child: MemberColumn(
            member: members[index],
            moments: moments,
            currentMoment: currentMoment,
            onToggleTask: (taskIndex) => toggleTask(index, taskIndex),
          ),
        );
      },
    );
  }
}