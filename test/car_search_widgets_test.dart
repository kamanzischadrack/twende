// test/car_search_widgets_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twende_flutter/models/car.dart';
import 'package:twende_flutter/models/supplier.dart';
import 'package:twende_flutter/widgets/car_card.dart';
import 'package:twende_flutter/widgets/search_form.dart';
import 'package:twende_flutter/screens/home/home_screen.dart';

void main() {
  group('HomeScreen widget tests', () {
    testWidgets('renders Twende logo and search form', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byWidgetPredicate((w) => w is Text && (w.data == 'Twende' || w.data == 'Twende')), findsOneWidget);
      expect(find.text('®'), findsOneWidget);
      expect(find.text('Pick-up location'), findsOneWidget);
      expect(find.text('SEARCH'), findsOneWidget);
      expect(find.text('Return to same location'), findsOneWidget);
    });
  });

  group('CarCard widget tests', () {
    testWidgets('renders car details, specs, supplier and book button', (tester) async {
      const car = Car(
        id: 'car-123',
        name: 'Volkswagen Golf 8',
        supplier: Supplier(id: 'supp-1', fullName: 'Europcar Rental'),
        price: 45.0,
        type: 'gasoline',
        gearbox: 'automatic',
        seats: 5,
        doors: 5,
        aircon: true,
        mileage: -1,
        deposit: 500,
        cancellation: 0,
        amendments: 0,
        theftProtection: 0,
        rating: 4.8,
        trips: 24,
      );

      final from = DateTime(2026, 6, 1, 10, 0);
      final to = DateTime(2026, 6, 4, 10, 0); // 3 days

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CarCard(
                car: car,
                from: from,
                to: to,
                pickupLocation: 'loc-1',
                dropOffLocation: 'loc-1',
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Car name
      expect(find.text('Volkswagen Golf 8'), findsOneWidget);

      // Specs
      expect(find.text('GASOLINE'), findsOneWidget);
      expect(find.text('AUTOMATIC'), findsOneWidget);
      expect(find.text('5'), findsNWidgets(2)); // seats: 5, doors: 5

      // Supplier
      expect(find.text('Europcar Rental'), findsOneWidget);

      // Price calculation (3 days * $45 = $135)
      expect(find.text('\$135'), findsOneWidget);
      expect(find.text('Price per day \$45'), findsOneWidget);

      // Book button
      expect(find.text('BOOK'), findsOneWidget);
    });
  });

  group('SearchForm widget tests', () {
    testWidgets('renders all date/time and location fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SearchForm(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Pick-up location'), findsOneWidget);
      expect(find.text('Pickup date'), findsOneWidget);
      expect(find.text('Pickup time'), findsOneWidget);
      expect(find.text('Drop-off date'), findsOneWidget);
      expect(find.text('Drop-off time'), findsOneWidget);
      expect(find.text('SEARCH'), findsOneWidget);
      expect(find.text('Return to same location'), findsOneWidget);
    });
  });
}
