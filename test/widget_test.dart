// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:competihub/main.dart';

void main() {
  testWidgets('CompetiHub home screen shows title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CompetihubApp());

    // Verify that the CompetiHub title is displayed in the app bar.
    expect(find.widgetWithText(AppBar, 'CompetiHub'), findsOneWidget);
    expect(find.text('Encuentra y comprende competencias'), findsOneWidget);
  });
}