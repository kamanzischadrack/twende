// test/settings_notifications_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twende_flutter/screens/notifications/notifications_screen.dart';
import 'package:twende_flutter/screens/settings/settings_screen.dart';

void main() {
  group('NotificationsScreen tests', () {
    testWidgets('shows sign-in prompt when unauthenticated', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsWidgets);
      expect(find.text('SIGN IN'), findsOneWidget);
    });
  });

  group('SettingsScreen tests', () {
    testWidgets('shows sign-in prompt when unauthenticated', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsWidgets);
      expect(find.text('SIGN IN'), findsOneWidget);
    });
  });
}
