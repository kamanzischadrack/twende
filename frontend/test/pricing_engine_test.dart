import 'package:flutter_test/flutter_test.dart';
import 'package:twende_flutter/shared/domain/pricing_engine.dart';

void main() {
  group('Twende SRS §8.1 Pricing Engine Reference Cases', () {
    const ratePlan = RatePlanInput(
      dailyRate: 50000.0,
      weeklyRate: 300000.0,
      monthlyRate: 900000.0,
      currency: 'RWF',
    );

    test('Case 1: 3 days -> 150,000 RWF', () {
      final start = DateTime(2026, 6, 1, 10, 0);
      final end = DateTime(2026, 6, 4, 10, 0); // 3 days exactly
      final quote = PricingEngine.compute(
        pickupDateTime: start,
        returnDateTime: end,
        ratePlan: ratePlan,
        taxConfig: const TaxConfig(mode: TaxMode.exempt),
      );

      expect(quote.billableDays, equals(3));
      expect(quote.baseRentalAmount, equals(150000.0));
    });

    test('Case 2: 6 days -> 300,000 RWF (Weekly cap)', () {
      final start = DateTime(2026, 6, 1, 10, 0);
      final end = DateTime(2026, 6, 7, 10, 0); // 6 days
      final quote = PricingEngine.compute(
        pickupDateTime: start,
        returnDateTime: end,
        ratePlan: ratePlan,
        taxConfig: const TaxConfig(mode: TaxMode.exempt),
      );

      expect(quote.billableDays, equals(6));
      expect(quote.baseRentalAmount, equals(300000.0));
    });

    test('Case 3: 10 days -> 450,000 RWF (1W + 3D)', () {
      final start = DateTime(2026, 6, 1, 10, 0);
      final end = DateTime(2026, 6, 11, 10, 0); // 10 days
      final quote = PricingEngine.compute(
        pickupDateTime: start,
        returnDateTime: end,
        ratePlan: ratePlan,
        taxConfig: const TaxConfig(mode: TaxMode.exempt),
      );

      expect(quote.billableDays, equals(10));
      expect(quote.baseRentalAmount, equals(450000.0));
    });

    test('Case 4: 13 days -> 600,000 RWF (2W cap)', () {
      final start = DateTime(2026, 6, 1, 10, 0);
      final end = DateTime(2026, 6, 14, 10, 0); // 13 days
      final quote = PricingEngine.compute(
        pickupDateTime: start,
        returnDateTime: end,
        ratePlan: ratePlan,
        taxConfig: const TaxConfig(mode: TaxMode.exempt),
      );

      expect(quote.billableDays, equals(13));
      expect(quote.baseRentalAmount, equals(600000.0));
    });

    test('Case 5: 35 days -> 1,150,000 RWF (1M + 5D)', () {
      final start = DateTime(2026, 6, 1, 10, 0);
      final end = DateTime(2026, 7, 6, 10, 0); // 35 days
      final quote = PricingEngine.compute(
        pickupDateTime: start,
        returnDateTime: end,
        ratePlan: ratePlan,
        taxConfig: const TaxConfig(mode: TaxMode.exempt),
      );

      expect(quote.billableDays, equals(35));
      expect(quote.baseRentalAmount, equals(1150000.0));
    });

    test('Discount approval threshold trigger', () {
      final start = DateTime(2026, 6, 1, 10, 0);
      final end = DateTime(2026, 6, 4, 10, 0); // 3 days = 150k
      final quote = PricingEngine.compute(
        pickupDateTime: start,
        returnDateTime: end,
        ratePlan: ratePlan,
        discount: const DiscountInput(
          id: 'vip',
          name: 'VIP Special',
          percent: 25.0, // > 20%
        ),
      );

      expect(quote.requiresApproval, isTrue);
      expect(quote.approvalReason, contains('exceeds approval threshold'));
      expect(quote.discountAmount, equals(37500.0));
    });
  });
}
