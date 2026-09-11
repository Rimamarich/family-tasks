// Test de base pour Family Tasks.
//
// Vérifie que l'application démarre correctement.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familytasks/app.dart';

void main() {
  testWidgets('L\'application démarre correctement',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FamilyTasksApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}