import 'package:flutter/material.dart';
import 'screens/family_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/settings_screen.dart';
import 'services/config_service.dart';
import 'services/ics_service.dart';
import 'services/member_service.dart';
import 'widgets/bottom_menu.dart';
import 'widgets/pin_dialog.dart';

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
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Hauteur en dessous de laquelle le menu inférieur disparaît
  static const double _limitedHeightThreshold = 550;

  // Index de l'onglet Paramètres
  static const int _settingsTabIndex = 2;

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

  @override
  void initState() {
    super.initState();
    // Charge la configuration initiale (détermine l'onglet de départ)
    _loadInitialState();
    // Lance la synchronisation automatique en arrière-plan
    _runAutoSync();
  }

  /// Détermine l'onglet de départ en fonction de l'existence de membres.
  ///
  /// Si aucun membre n'est en base, on démarre sur l'onglet Paramètres
  /// pour inviter l'utilisateur à faire sa configuration initiale.
  Future<void> _loadInitialState() async {
    try {
      final members = await MemberService.getAll();
      if (!mounted) return;
      if (members.isEmpty) {
        setState(() => _currentIndex = _settingsTabIndex);
      }
    } catch (e) {
      // En cas d'erreur, on garde l'onglet Tâches par défaut
    }
  }

  /// Lance la synchronisation automatique si la configuration
  /// familiale est activée. Affiche les mêmes messages que le
  /// bouton Synchroniser des paramètres.
  Future<void> _runAutoSync() async {
    try {
      final isConfigured = await ConfigService.isFamilyConfigured();
      if (!isConfigured) return;

      // Message de début
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Synchronisation en cours...')),
      );

      final eventCount = await IcsService.sync();

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

      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      // Silencieux : si la synchro échoue au lancement, l'utilisateur
      // verra le statut dans les Paramètres.
    }
  }

  int _extractErrorCount(String? message) {
    if (message == null || message.isEmpty) return 0;
    final match = RegExp(r'(\d+)').firstMatch(message);
    if (match == null) return 0;
    return int.tryParse(match.group(1)!) ?? 0;
  }

  /// Change d'onglet. Protège l'accès aux paramètres par PIN.
  Future<void> _onTabSelected(int index) async {
    // Si on demande l'onglet Paramètres (et qu'on n'y est pas déjà),
    // on vérifie le PIN
    if (index == _settingsTabIndex && _currentIndex != _settingsTabIndex) {
      final ok = await PinDialog.show(context);
      if (!ok || !mounted) return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Tasks',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
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
                  // Ferme le Drawer avant de vérifier le PIN
                  Navigator.pop(context);
                  _onTabSelected(i);
                },
              ),
          ],
        ),
      ),
    );
  }
}