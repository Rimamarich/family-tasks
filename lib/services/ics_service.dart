import 'package:http/http.dart' as http;
import 'package:rrule/rrule.dart';
import '../models/member.dart';
import 'config_service.dart';
import 'member_service.dart';
import 'moment_service.dart';
import 'task_service.dart';
import 'database_helper.dart';

/// Représente un événement brut lu dans le fichier ICS.
class _IcsEvent {
  const _IcsEvent({
    required this.uid,
    required this.title,
    required this.description,
    required this.start,
    this.rrule,
  });

  final String uid;
  final String title;
  final String? description;
  final DateTime start;
  final String? rrule;
}

/// Résultat de l'analyse du titre d'un événement.
class ParsedTitle {
  ParsedTitle({
    required this.cleanTitle,
    required this.members,
    this.stars,
    this.starsError,
  });

  final String cleanTitle;
  final List<String> members;
  final int? stars;
  final String? starsError;
}

/// Service gérant la synchronisation ICS.
class IcsService {
  /// Synchronise l'agenda avec la base de données.
  static Future<int> sync() async {
    final today = DateTime.now();
    final todayStr = _dateToString(today);

    // 1. Récupère l'URL ICS
    final icsUrl = await ConfigService.getIcsUrl();
    if (icsUrl == null || icsUrl.isEmpty) {
      await _saveStatus('failed', 'Adresse du fichier ICS non configurée.');
      return 0;
    }

    // 2. Télécharge le fichier
    String icsContent;
    try {
      final response = await http.get(Uri.parse(icsUrl));
      if (response.statusCode != 200) {
        await _saveStatus(
            'failed', 'Erreur HTTP ${response.statusCode} lors du téléchargement.');
        return 0;
      }
      icsContent = response.body;
    } catch (e) {
      await _saveStatus('failed', 'Impossible de télécharger le fichier ICS.');
      return 0;
    }

    // 3. Parse le fichier
    List<_IcsEvent> events;
    try {
      events = _parseIcs(icsContent);
    } catch (e) {
      await _saveStatus('failed', 'Fichier ICS invalide ou illisible.');
      return 0;
    }

    // 4. Vide la table sync_errors AVANT de filtrer
    await _clearSyncErrors();

    // 5. Filtre les événements qui ont une occurrence aujourd'hui
    final debugLog = <String>[];
    debugLog.add('Date du jour : ${_dateToString(today)}');
    debugLog.add('Total événements parsés : ${events.length}');
    debugLog.add(
        'Événements avec RRULE : ${events.where((e) => e.rrule != null).length}');

    final todayEvents = <_IcsEvent>[];
    for (final e in events) {
      if (_occursOn(e, today, debugLog)) {
        todayEvents.add(e);
      }
    }

    debugLog.add('Événements retenus aujourd\'hui : ${todayEvents.length}');

    // DEBUG : enregistre le log dans sync_errors
    for (final log in debugLog) {
      await _addError('[DEBUG]', log);
    }

    // 6. Supprime les tâches non terminées du jour
    await TaskService.deleteUncompletedByDate(todayStr);

    // 7. Traite chaque événement
    final members = await MemberService.getAll();
    final moments = await MomentService.getAll();
    final defaultStars = await ConfigService.getDefaultStars();

    var importedCount = 0;
    for (final event in todayEvents) {
      final result = await _processEvent(
        event: event,
        members: members,
        moments: moments,
        defaultStars: defaultStars,
        todayStr: todayStr,
      );
      if (result) importedCount++;
    }

    // 8. Enregistre le statut (sans compter les entrées [DEBUG])
    final errorsCount = await _countRealSyncErrors();
    if (errorsCount == 0) {
      await _saveStatus('success', '');
    } else {
      await _saveStatus('partial', '$errorsCount événement(s) en erreur.');
    }

    return importedCount;
  }

  /// Convertit une date en chaîne YYYY-MM-DD.
  static String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static Future<void> _saveStatus(String status, String message) async {
    await ConfigService.setLastSync(
      at: DateTime.now().toIso8601String(),
      status: status,
      message: message.isEmpty ? null : message,
    );
  }

  /// Vérifie si un événement a une occurrence à la date donnée.
  static bool _occursOn(_IcsEvent event, DateTime date, List<String> debugLog) {
    // Cas ponctuel
    if (event.rrule == null || event.rrule!.isEmpty) {
      final match = _dateToString(event.start) == _dateToString(date);
      if (match) {
        debugLog.add(
            'PONCTUEL inclus : "${event.title}" (${_dateToString(event.start)})');
      }
      return match;
    }

    // Cas récurrent
    try {
      final startUtc = event.start.toUtc();
      final targetUtc =
          DateTime.utc(date.year, date.month, date.day, 23, 59, 59);

      debugLog.add('--- RRULE pour "${event.title}" ---');
      debugLog.add('  RRULE brute : ${event.rrule}');
      debugLog.add('  Start local : ${event.start}');
      debugLog.add('  Start UTC   : $startUtc');
      debugLog.add('  Target UTC  : $targetUtc');

      // Le package rrule attend une chaîne préfixée par "RRULE:"
      final rrule = RecurrenceRule.fromString('RRULE:${event.rrule!}');
      final iterable =
          rrule.getAllInstances(start: startUtc, before: targetUtc);

      var count = 0;
      for (final occurrence in iterable) {
        count++;
        final occurrenceLocal = occurrence.toLocal();
        final dateStr = _dateToString(occurrenceLocal);
        if (count <= 5) {
          debugLog.add('  Occ. $count : $occurrenceLocal ($dateStr)');
        }
        if (dateStr == _dateToString(date)) {
          debugLog.add('  → MATCH !');
          return true;
        }
      }
      debugLog.add('  Total occurrences calculées : $count');
      debugLog.add('  → Pas d\'occurrence aujourd\'hui');
      return false;
    } catch (e) {
      debugLog.add('  ERREUR RRULE : $e');
      return false;
    }
  }

  /// Parse le contenu ICS.
  static List<_IcsEvent> _parseIcs(String content) {
    final events = <_IcsEvent>[];
    final lines = _unfoldLines(content);

    var inEvent = false;
    String? uid;
    String? summary;
    String? description;
    DateTime? start;
    String? rrule;

    for (final line in lines) {
      if (line == 'BEGIN:VEVENT') {
        inEvent = true;
        uid = null;
        summary = null;
        description = null;
        start = null;
        rrule = null;
        continue;
      }

      if (line == 'END:VEVENT') {
        inEvent = false;
        if (uid != null && summary != null && start != null) {
          events.add(_IcsEvent(
            uid: uid,
            title: summary,
            description: description,
            start: start,
            rrule: rrule,
          ));
        }
        continue;
      }

      if (!inEvent) continue;

      final colonIndex = line.indexOf(':');
      if (colonIndex < 0) continue;

      final key = line.substring(0, colonIndex).trim();
      final value = line.substring(colonIndex + 1).trim();

      final baseKey = key.contains(';') ? key.split(';').first : key;

      switch (baseKey) {
        case 'UID':
          uid = value;
          break;
        case 'SUMMARY':
          summary = value;
          break;
        case 'DESCRIPTION':
          description = value.isEmpty ? null : value;
          break;
        case 'DTSTART':
          start = _parseIcsDate(value);
          break;
        case 'RRULE':
          rrule = value;
          break;
      }
    }

    return events;
  }

  static List<String> _unfoldLines(String content) {
    final rawLines = content.split(RegExp(r'\r?\n'));
    final unfolded = <String>[];

    for (final line in rawLines) {
      if (line.startsWith(' ') || line.startsWith('\t')) {
        if (unfolded.isNotEmpty) {
          unfolded[unfolded.length - 1] += line.substring(1);
        }
      } else {
        unfolded.add(line);
      }
    }

    return unfolded;
  }

  static DateTime? _parseIcsDate(String value) {
    final cleanValue =
        value.endsWith('Z') ? value.substring(0, value.length - 1) : value;

    if (cleanValue.length == 8) {
      final year = int.tryParse(cleanValue.substring(0, 4));
      final month = int.tryParse(cleanValue.substring(4, 6));
      final day = int.tryParse(cleanValue.substring(6, 8));
      if (year == null || month == null || day == null) return null;
      return DateTime(year, month, day);
    }

    if (cleanValue.length >= 15) {
      final year = int.tryParse(cleanValue.substring(0, 4));
      final month = int.tryParse(cleanValue.substring(4, 6));
      final day = int.tryParse(cleanValue.substring(6, 8));
      final hour = int.tryParse(cleanValue.substring(9, 11));
      final minute = int.tryParse(cleanValue.substring(11, 13));
      final second = cleanValue.length >= 15
          ? int.tryParse(cleanValue.substring(13, 15))
          : 0;
      if (year == null ||
          month == null ||
          day == null ||
          hour == null ||
          minute == null) {
        return null;
      }
      return DateTime(year, month, day, hour, minute, second ?? 0);
    }

    return null;
  }

  static Future<bool> _processEvent({
    required _IcsEvent event,
    required List<FamilyMember> members,
    required List<Moment> moments,
    required int defaultStars,
    required String todayStr,
  }) async {
    final parsed = _parseTitle(event.title);

    List<FamilyMember> targets;
    if (parsed.members.isEmpty) {
      targets = members.where((m) => !m.pause).toList();
      if (targets.isEmpty) {
        await _addError(event.title, 'Aucun membre actif dans la famille');
        return false;
      }
    } else {
      targets = [];
      final unknownMembers = <String>[];
      for (final name in parsed.members) {
        final found = members.where(
          (m) => m.name.toLowerCase() == name.toLowerCase() && !m.pause,
        );
        if (found.isEmpty) {
          unknownMembers.add(name);
        } else {
          targets.add(found.first);
        }
      }
      if (unknownMembers.isNotEmpty) {
        await _addError(
          event.title,
          'Membre(s) inconnu(s) : ${unknownMembers.join(', ')}',
        );
        return false;
      }
    }

    int stars;
    if (parsed.starsError != null) {
      await _addError(event.title, parsed.starsError!);
      return false;
    }
    stars = parsed.stars ?? defaultStars;

    final moment = _findMoment(event.start, moments);
    if (moment == null) {
      await _addError(event.title, 'Aucun moment ne correspond à cette heure');
      return false;
    }

    final cleanTitle = parsed.cleanTitle;
    final taskTime =
        '${event.start.hour.toString().padLeft(2, '0')}:${event.start.minute.toString().padLeft(2, '0')}';

    for (final member in targets) {
      await _insertTask(
        icsUid: event.uid,
        title: cleanTitle,
        description: event.description,
        memberId: member.id!,
        stars: stars,
        momentId: moment.id!,
        taskDate: todayStr,
        taskTime: taskTime,
      );
    }

    return true;
  }

  static ParsedTitle _parseTitle(String rawTitle) {
    final memberRegex = RegExp(r'@(\w+)');
    final starRegex = RegExp(r'#(\S+)');

    final memberMatches = memberRegex.allMatches(rawTitle);
    final memberNames = memberMatches.map((m) => m.group(1)!).toList();

    final starMatches = starRegex.allMatches(rawTitle);
    int? stars;
    String? starsError;

    if (starMatches.length > 1) {
      starsError = 'Plusieurs #étoiles trouvés dans le titre';
    } else if (starMatches.length == 1) {
      final starValue = starMatches.first.group(1)!;
      final parsed = int.tryParse(starValue);
      if (parsed == null || parsed < 0) {
        starsError = 'Nombre d\'étoiles invalide : #$starValue';
      } else {
        stars = parsed;
      }
    }

    var cleanTitle = rawTitle;
    cleanTitle = cleanTitle.replaceAll(memberRegex, '');
    cleanTitle = cleanTitle.replaceAll(starRegex, '');
    cleanTitle = cleanTitle.trim().replaceAll(RegExp(r'\s+'), ' ');

    return ParsedTitle(
      cleanTitle: cleanTitle,
      members: memberNames,
      stars: stars,
      starsError: starsError,
    );
  }

  static Moment? _findMoment(DateTime date, List<Moment> moments) {
    if (moments.isEmpty) return null;

    final eventMinutes = date.hour * 60 + date.minute;

    for (final moment in moments) {
      final parts = moment.heureDeFin.split(':');
      if (parts.length != 2) continue;
      final hours = int.tryParse(parts[0]);
      final minutes = int.tryParse(parts[1]);
      if (hours == null || minutes == null) continue;
      final endMinutes = hours * 60 + minutes;
      if (eventMinutes < endMinutes) {
        return moment;
      }
    }

    return moments.last;
  }

  static Future<void> _insertTask({
    required String icsUid,
    required String title,
    required String? description,
    required int memberId,
    required int stars,
    required int momentId,
    required String taskDate,
    required String taskTime,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('tasks', {
      'ics_uid': icsUid,
      'title': title,
      'description': description,
      'member_id': memberId,
      'stars': stars,
      'completed': 0,
      'moment_id': momentId,
      'task_date': taskDate,
      'task_time': taskTime,
    });
  }

  static Future<void> _clearSyncErrors() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('sync_errors');
  }

  /// Compte les erreurs réelles (exclut les entrées [DEBUG]).
  static Future<int> _countRealSyncErrors() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM sync_errors WHERE event_title != '[DEBUG]'",
    );
    return result.first['count'] as int? ?? 0;
  }

  static Future<void> _addError(String eventTitle, String message) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('sync_errors', {
      'event_title': eventTitle,
      'error_message': message,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}