import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twende_flutter/core/store/json_document_store.dart';
import 'package:twende_flutter/features/returns_inspection/returns_due_screen.dart';
import 'package:twende_flutter/shared/repositories/store_finance_repositories.dart';

void main() {
  testWidgets('groups active contracts by overdue and tomorrow due dates',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contractRepositoryProvider.overrideWithValue(
            StoreContractRepository(
                store: JsonDocumentStore(useInMemory: true)),
          ),
        ],
        child: const MaterialApp(home: ReturnsDueScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Overdue (1)'), findsOneWidget);
    expect(find.text('Tomorrow (1)'), findsOneWidget);
    expect(find.text('Start return'), findsNWidgets(2));
  });
}
