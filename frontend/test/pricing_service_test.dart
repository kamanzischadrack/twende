import 'package:twende_flutter/services/pricing_service.dart';
import 'package:twende_flutter/shared/domain/pricing_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PricingService', () {
    test('builds an hourly quote for same-day rentals', () {
      final quote = PricingService.buildQuote(
        vehicleCategory: 'car',
        pickupDateTime: DateTime(2026, 6, 1, 9, 0),
        returnDateTime: DateTime(2026, 6, 1, 15, 0),
        baseDailyRate: 50000.0,
        baseHourlyRate: 2500.0,
        taxConfig: const TaxConfig(mode: TaxMode.exempt),
      );

      expect(quote.baseRentalAmount, equals(16200.0));
      expect(quote.billableDays, equals(1));
      expect(quote.rateDecompositionDescription, contains('6 hours'));
    });

    test('applies corporate modifier and branch override', () {
      final plan = PricingService.resolveRatePlan(
        vehicleCategory: 'van',
        pickupDateTime: DateTime(2026, 2, 12),
        returnDateTime: DateTime(2026, 2, 15),
        customerType: 'corporate',
        branchId: 'airport',
        baseDailyRate: 50000.0,
        baseHourlyRate: 2500.0,
      );

      expect(plan.dailyRate, greaterThan(50000.0));
      expect(plan.currency, equals('RWF'));
      expect(plan.source, equals('standard rate'));
    });

    test('keeps the premium seasonal rate consistent', () {
      final plan = PricingService.resolveRatePlan(
        vehicleCategory: 'premium',
        pickupDateTime: DateTime(2026, 7, 10),
        returnDateTime: DateTime(2026, 7, 14),
      );

      expect(plan.dailyRate, greaterThan(50000.0));
      expect(plan.source, equals('peak-season rate'));
    });
  });
}
