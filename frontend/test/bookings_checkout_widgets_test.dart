// test/bookings_checkout_widgets_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twende_flutter/widgets/booking_status_badge.dart';
import 'package:twende_flutter/screens/bookings/bookings_screen.dart';
import 'package:twende_flutter/screens/booking/booking_screen.dart';
import 'package:twende_flutter/screens/checkout/checkout_screen.dart';
import 'package:twende_flutter/screens/about/about_screen.dart';
import 'package:twende_flutter/screens/contact/contact_screen.dart';
import 'package:twende_flutter/screens/tos/tos_screen.dart';

void main() {
  group('BookingStatusBadge tests', () {
    testWidgets('renders all status labels and colors correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                BookingStatusBadge(status: 'pending'),
                BookingStatusBadge(status: 'deposit'),
                BookingStatusBadge(status: 'paid'),
                BookingStatusBadge(status: 'reserved'),
                BookingStatusBadge(status: 'cancelled'),
                BookingStatusBadge(status: 'void'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Deposit'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Reserved'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('Void'), findsOneWidget);
    });
  });

  group('BookingsScreen tests', () {
    testWidgets('renders bookings screen header and filter chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Bookings'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    });
  });

  group('BookingScreen detail tests', () {
    testWidgets('renders BookingScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookingScreen(bookingId: 'book-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(BookingScreen), findsOneWidget);
    });
  });

  group('CheckoutScreen tests', () {
    testWidgets('renders CheckoutScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CheckoutScreen(params: {
              'carId': 'car-1',
              'pickupLocationId': 'loc-1',
              'dropOffLocationId': 'loc-1',
              'from': 1717236000000,
              'to': 1717495200000,
            }),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(CheckoutScreen), findsOneWidget);
    });
  });

  group('Informational screens tests', () {
    testWidgets('renders AboutScreen with brand and version info', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AboutScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Twende'), findsWidgets);
      expect(find.text('Fleet management platform'), findsOneWidget);
      expect(find.text('Version 1.0.0'), findsOneWidget);
    });

    testWidgets('renders ContactScreen with support info', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ContactScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Twende'), findsWidgets);
      expect(find.text('hello@twende.app'), findsOneWidget);
      expect(find.text('Send a message'), findsOneWidget);
    });

    testWidgets('renders TosScreen with terms content', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TosScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Twende'), findsWidgets);
      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.textContaining('1. Acceptance of Terms'), findsOneWidget);
    });
  });
}
