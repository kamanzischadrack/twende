// test/driver_app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twende_flutter/features/driver_app/driver_home_screen.dart';
import 'package:twende_flutter/features/driver_app/driver_job_detail_screen.dart';
import 'package:twende_flutter/features/driver_app/driver_checklist_screen.dart';
import 'package:twende_flutter/features/driver_app/driver_expense_screen.dart';
import 'package:twende_flutter/features/driver_app/driver_pod_screen.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Driver App Experience Tests', () {
    testWidgets('DriverHomeScreen renders greeting, driving hours (DRV-03), and trip cards',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const DriverHomeScreen()));
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.textContaining('Hi, '), findsOneWidget);
      expect(find.text('Daily Driving Hours (DRV-03)'), findsOneWidget);
      expect(find.text("Today's Assigned Jobs"), findsOneWidget);
      expect(find.text('T-0098'), findsOneWidget);
      expect(find.text('RAF 789 T'), findsOneWidget);
    });

    testWidgets('DriverJobDetailScreen renders origin, destination, client call, and action hub',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(const DriverJobDetailScreen(tripId: 'T-0098')),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Trip T-0098'), findsOneWidget);
      expect(find.textContaining('Cimerwa Cement Ltd'), findsOneWidget);
      expect(find.text('Driver Action Hub'), findsOneWidget);
      expect(find.text('Log Expense'), findsOneWidget);
      expect(find.text('Report Issue'), findsOneWidget);
    });

    testWidgets('DriverChecklistScreen renders walkaround inspection items and seal field',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(const DriverChecklistScreen(tripId: 'T-0098')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Pre-Trip Walkaround (TRP-03)'), findsOneWidget);
      expect(find.text('Inspection Checklist'), findsOneWidget);
      expect(find.textContaining('Container / Cargo Seal Number'), findsOneWidget);
      expect(find.text('Complete Pre-Trip Check & Start Trip'), findsOneWidget);
    });

    testWidgets('DriverExpenseScreen renders category picker and integer RWF amount field',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(const DriverExpenseScreen(tripId: 'T-0098')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Log Trip Expense (TRP-02)'), findsOneWidget);
      expect(find.text('Expense Category *'), findsOneWidget);
      expect(find.text('Save & Log Expense'), findsOneWidget);
    });

    testWidgets('DriverPodScreen renders consignee fields and POD confirmation button',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(const DriverPodScreen(tripId: 'T-0098')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Proof of Delivery (TRP-04)'), findsOneWidget);
      expect(find.text('Receiving Consignee Information *'), findsOneWidget);
      expect(find.text('Confirm Delivery & Seal POD'), findsOneWidget);
    });
  });
}
