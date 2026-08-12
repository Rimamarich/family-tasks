import 'package:flutter/material.dart';
import 'screens/family_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/bottom_menu.dart';

/// Configuration générale de l'application Family Tasks.
///
/// Gère la navigation entre les trois écrans principaux
/// et intègre le menu de navigation commun.
class FamilyTasksApp extends StatefulWidget {
  const FamilyTasksApp({super.key});

  @override
  State<FamilyTasksApp> createState() => _FamilyTasksAppState();
}

class _FamilyTasksAppState extends State<FamilyTasksApp> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Hauteur en dessous de laquelle le menu inférieur disparaît
  static const double _limitedHeightThreshold = 550;

  // Liste des écrans
  final List<Widget> _screens = const [
    FamilyScreen(),
    RewardsScreen(),
    SettingsScreen(),
  ];

  // Titres pour le Drawer
  static const List<String> _titles = ['Tâches', 'Réjouissances', 'Paramètres'];
  static const List<IconData> _icons = [
    Icons.home_rounded,
    Icons.emoji_events_rounded,
    Icons.settings_rounded,
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Tasks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F5F5),
        drawer: _buildDrawer(),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxHeight < _limitedHeightThreshold;

              return Column(
                children: [
                  Expanded(
                    child: _screens[_currentIndex],
                  ),
                  if (!isCompact)
                    BottomMenu(
                      currentIndex: _currentIndex,
                      onTabSelected: _onTabSelected,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              width: double.infinity,
              child: const Text(
                'Family Tasks',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            for (var i = 0; i < _screens.length; i++)
              ListTile(
                leading: Icon(
                  _icons[i],
                  color: _currentIndex == i
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade600,
                ),
                title: Text(
                  _titles[i],
                  style: TextStyle(
                    fontWeight:
                        _currentIndex == i ? FontWeight.bold : FontWeight.normal,
                    color: _currentIndex == i
                        ? Theme.of(context).primaryColor
                        : null,
                  ),
                ),
                selected: _currentIndex == i,
                onTap: () {
                  _onTabSelected(i);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}