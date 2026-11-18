import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twende_flutter/features/access_control/role_access_screen.dart';

void main() {
  testWidgets('shows each role and its SRS default actions', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RoleAccessScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('System Administrator'), findsOneWidget);
    expect(find.text('Owner / Management'), findsOneWidget);
    expect(find.text('Rental Manager'), findsOneWidget);
    expect(find.text('Rental Officer'), findsOneWidget);
    expect(find.text('Fleet Manager'), findsOneWidget);
    expect(find.text('Finance Officer / Accountant'), findsOneWidget);
    expect(find.text('Driver / Chauffeur'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);

    await tester.tap(find.text('System Administrator'));
    await tester.pumpAndSettle();

    expect(find.text('Fleet and documents'), findsOneWidget);
    expect(find.text('Settings and users'), findsOneWidget);
    expect(find.textContaining('Delete / archive'), findsWidgets);
  });
}
