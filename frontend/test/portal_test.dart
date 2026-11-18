// test/portal_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twende_flutter/features/portal/portal_home_screen.dart';
import 'package:twende_flutter/features/portal/portal_book_screen.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Customer Portal Experience Tests', () {
    testWidgets('PortalHomeScreen renders branches, rolling quote duration, and vehicle categories',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const PortalHomeScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Customer Portal'), findsOneWidget);
      expect(find.text('Book Your Rental in Rwanda'), findsOneWidget);
      expect(find.text('Available Vehicle Classes'), findsOneWidget);
      expect(find.text('SUV & Crossover'), findsOneWidget);
      expect(find.text('Economy Sedan'), findsOneWidget);
      expect(find.text('Commercial Truck & 4x4'), findsOneWidget);
    });

    testWidgets('PortalBookScreen renders customer contact inputs, extras, and live breakdown',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          const PortalBookScreen(
            params: {
              'category': 'SUV & Crossover',
              'branch': 'Kigali HQ',
              'dailyRate': 75000,
              'deposit': 200000,
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Complete Reservation'), findsOneWidget);
      expect(find.text('1. Driver & Customer Information'), findsOneWidget);
      expect(find.text('2. Add-on Options & Extras'), findsOneWidget);
      expect(find.text('3. Price Breakdown (SRS 8.1 Engine)'), findsOneWidget);
      expect(find.text('Proceed to Payment Checkout'), findsOneWidget);
    });
  });
}
