// test/portal_screens_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:twende_flutter/core/store/json_document_store.dart';
import 'package:twende_flutter/core/store/store_provider.dart';
import 'package:twende_flutter/features/portal/portal_sign_screen.dart';
import 'package:twende_flutter/features/portal/portal_pay_screen.dart';
import 'package:twende_flutter/features/portal/portal_documents_screen.dart';

Widget createTestableWidget(Widget child) {
  final inMemoryStore = JsonDocumentStore(useInMemory: true);
  return ProviderScope(
    overrides: [
      jsonDocumentStoreProvider.overrideWithValue(inMemoryStore),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

Future<void> pumpScreen(WidgetTester tester, Widget widget) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.0;
  await tester.pumpWidget(createTestableWidget(widget));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Customer Portal (Frontend) Screen Tests', () {
    testWidgets('1. PortalSignScreen renders unsigned contract, terms declarations, and signature pad', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await pumpScreen(tester, const PortalSignScreen(token: 'cnt_03'));

      expect(find.byType(PortalSignScreen), findsOneWidget);
      expect(find.text('Digital Contract Signing'), findsOneWidget);
      expect(find.text('CNT-2026-0045'), findsOneWidget);
      expect(find.text('Total Value'), findsOneWidget);
      expect(find.text('CONFIRM & SEAL CONTRACT'), findsOneWidget);
    });

    testWidgets('2. PortalPayScreen renders invoice summary, payment channels, and pay action', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await pumpScreen(tester, const PortalPayScreen(token: 'cnt_01'));

      expect(find.byType(PortalPayScreen), findsOneWidget);
      expect(find.text('Secure Payment Gateway'), findsOneWidget);
      expect(find.text('Amount Due Now'), findsOneWidget);
      expect(find.text('MTN Mobile Money (MoMo)'), findsOneWidget);
      expect(find.text('Airtel Money'), findsOneWidget);
      expect(find.text('Credit / Debit Card'), findsOneWidget);
    });

    testWidgets('3. PortalDocumentsScreen renders customer PDF documents and download actions', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await pumpScreen(tester, const PortalDocumentsScreen());

      expect(find.byType(PortalDocumentsScreen), findsOneWidget);
      expect(find.text('My Documents Hub'), findsOneWidget);
      expect(find.text('Master Vehicle Rental Agreement'), findsOneWidget);
      expect(find.text('Rwanda Revenue Authority EBM Tax Invoice'), findsOneWidget);
      expect(find.text('SIGNED & SEALED'), findsOneWidget);
      expect(find.text('PAID IN FULL'), findsOneWidget);
    });
  });
}
