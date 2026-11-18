import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twende_flutter/core/utils/money_utils.dart';
import 'package:twende_flutter/core/widgets/status_badge.dart';
import 'package:twende_flutter/shared/domain/enums.dart';

void main() {
  test('formats RWF with the currency before the amount', () {
    expect(MoneyUtils.format(450000), 'RWF 450,000');
  });

  testWidgets('vehicle status badges include an icon and a text label',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatusBadge.vehicle(VehicleStatus.available),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.text('AVAILABLE'), findsOneWidget);
  });
}
