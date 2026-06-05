// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smart_learning_room/main.dart';
import 'package:smart_learning_room/models/sensor_data.dart';
import 'package:smart_learning_room/providers/sensor_provider.dart';

void main() {
  testWidgets('Smart Learning Room app loads', (WidgetTester tester) async {
    final sensorData = SensorData(
      temperature: 25.0,
      humidity: 60.0,
      lux: 320.0,
      gasLevel: 30,
      presence: true,
      distance: 50.0,
      comfortScore: 85,
      comfortStatus: 'Optimal',
      timestamp: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sensorProvider.overrideWithValue(AsyncValue.data(sensorData)),
        ],
        child: const SmartLearningRoomApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that the main navigation is visible.
    expect(find.text('Home'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
