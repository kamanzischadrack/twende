import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twende_flutter/core/widgets/photo_capture_grid.dart';

void main() {
  testWidgets('shows all required inspection photo slots', (tester) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PhotoCaptureGrid(
              photos: const {},
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('0 / 7 required photos'), findsOneWidget);
    expect(find.text('Tap to capture'), findsNWidgets(7));
    for (final slot in requiredInspectionPhotoSlots) {
      expect(find.text(slot), findsOneWidget);
    }
  });
}
