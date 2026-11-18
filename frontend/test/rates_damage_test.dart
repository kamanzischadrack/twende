// test/rates_damage_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twende_flutter/features/rates/rates_screen.dart';
import 'package:twende_flutter/features/damage/damage_incidents_screen.dart';
import 'package:twende_flutter/features/settings/policies_screen.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Staff App Additional Features Tests', () {
    testWidgets('RatesScreen renders interactive price calculator and category rate cards',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const RatesScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Rate Plans & Tariffs (SRS 8.1)'), findsOneWidget);
      expect(find.text('Live Tariff Preview Calculator'), findsOneWidget);
      expect(find.text('Active Category Rate Cards'), findsOneWidget);
      expect(find.text('AI Smart Pricing Insights (AI-05)'), findsOneWidget);
    });

    testWidgets('DamageIncidentsScreen renders damage records and traffic fines auto-matching',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const DamageIncidentsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Damage & Incident Claims (DMG-02)'), findsOneWidget);
      expect(find.text('Damage Records (3)'), findsOneWidget);
      expect(find.text('Traffic Fine Re-Billing (2)'), findsOneWidget);
    });

    testWidgets('PoliciesScreen renders buffer sliders and role approval limits',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const PoliciesScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Company Operational Policies (SRS 13)'), findsOneWidget);
      expect(find.text('Turnaround Buffers & Grace Periods'), findsOneWidget);
      expect(find.text('Deposit & Booking Hold Rules'), findsOneWidget);
      expect(find.text('Save & Apply Policies'), findsOneWidget);
    });
  });
}
