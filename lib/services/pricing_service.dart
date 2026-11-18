import '../core/constants/app_constants.dart';
import '../shared/domain/pricing_engine.dart';

class ResolvedRatePlan {
  final String vehicleCategory;
  final String customerType;
  final String branchId;
  final String currency;
  final double dailyRate;
  final double? hourlyRate;
  final double? weeklyRate;
  final double? monthlyRate;
  final String source;

  const ResolvedRatePlan({
    required this.vehicleCategory,
    required this.customerType,
    required this.branchId,
    required this.currency,
    required this.dailyRate,
    this.hourlyRate,
    this.weeklyRate,
    this.monthlyRate,
    required this.source,
  });

  RatePlanInput toRatePlanInput() => RatePlanInput(
        dailyRate: dailyRate,
        hourlyRate: hourlyRate,
        weeklyRate: weeklyRate,
        monthlyRate: monthlyRate,
        currency: currency,
      );
}

class PricingService {
  const PricingService._();

  static const Map<String, double> _categoryModifiers = {
    'car': 1.0,
    'premium': 1.35,
    'van': 1.45,
    'truck': 1.75,
  };

  static const Map<String, double> _customerModifiers = {
    'individual': 1.0,
    'corporate': 0.96,
    'government': 0.9,
    'agency': 0.92,
  };

  static const Map<String, double> _branchModifiers = {
    'main': 1.0,
    'airport': 1.08,
    'kigali': 1.02,
    'rwamagana': 1.04,
  };

  static ResolvedRatePlan resolveRatePlan({
    required String vehicleCategory,
    required DateTime pickupDateTime,
    required DateTime returnDateTime,
    String customerType = 'individual',
    String branchId = 'main',
    String currency = AppConstants.defaultCurrency,
    double baseDailyRate = 50000.0,
    double baseHourlyRate = 3000.0,
    double? baseWeeklyRate,
    double? baseMonthlyRate,
  }) {
    final categoryModifier = _categoryModifiers[vehicleCategory.toLowerCase()] ?? 1.0;
    final customerModifier = _customerModifiers[customerType.toLowerCase()] ?? 1.0;
    final branchModifier = _branchModifiers[branchId.toLowerCase()] ?? 1.0;

    final dailyRate = baseDailyRate * categoryModifier * customerModifier * branchModifier;
    final hourlyRate = baseHourlyRate * categoryModifier * customerModifier * branchModifier;
    final weeklyRate = baseWeeklyRate ?? (dailyRate * 6.0);
    final monthlyRate = baseMonthlyRate ?? (dailyRate * 28.0);

    final season = _seasonBoost(pickupDateTime);
    final adjustedDailyRate = dailyRate * season;
    final adjustedHourlyRate = hourlyRate * season;
    final adjustedWeeklyRate = weeklyRate * season;
    final adjustedMonthlyRate = monthlyRate * season;

    final quoteWindowHours = returnDateTime.difference(pickupDateTime).inHours;
    final source = quoteWindowHours <= 24
        ? 'hourly override'
        : _rateSourceForDate(pickupDateTime);

    return ResolvedRatePlan(
      vehicleCategory: vehicleCategory,
      customerType: customerType,
      branchId: branchId,
      currency: currency,
      dailyRate: adjustedDailyRate,
      hourlyRate: adjustedHourlyRate,
      weeklyRate: adjustedWeeklyRate,
      monthlyRate: adjustedMonthlyRate,
      source: source,
    );
  }

  static QuoteResult buildQuote({
    required String vehicleCategory,
    required DateTime pickupDateTime,
    required DateTime returnDateTime,
    String customerType = 'individual',
    String branchId = 'main',
    String currency = AppConstants.defaultCurrency,
    double baseDailyRate = 50000.0,
    double baseHourlyRate = 3000.0,
    double? baseWeeklyRate,
    double? baseMonthlyRate,
    List<ExtraInput> extras = const [],
    DiscountInput? discount,
    MileagePlanInput mileagePlan = const MileagePlanInput(),
    TaxConfig taxConfig = const TaxConfig(mode: TaxMode.exclusive, rate: 0.18),
    double depositAmount = 0.0,
  }) {
    final plan = resolveRatePlan(
      vehicleCategory: vehicleCategory,
      pickupDateTime: pickupDateTime,
      returnDateTime: returnDateTime,
      customerType: customerType,
      branchId: branchId,
      currency: currency,
      baseDailyRate: baseDailyRate,
      baseHourlyRate: baseHourlyRate,
      baseWeeklyRate: baseWeeklyRate,
      baseMonthlyRate: baseMonthlyRate,
    );

    final totalHours = returnDateTime.difference(pickupDateTime).inHours;
    final effectiveHourlyRate = totalHours <= 24 ? plan.hourlyRate : null;

    return PricingEngine.compute(
      pickupDateTime: pickupDateTime,
      returnDateTime: returnDateTime,
      ratePlan: RatePlanInput(
        dailyRate: plan.dailyRate,
        hourlyRate: effectiveHourlyRate,
        weeklyRate: plan.weeklyRate,
        monthlyRate: plan.monthlyRate,
        currency: currency,
      ),
      mileagePlan: mileagePlan,
      extras: extras,
      discount: discount,
      taxConfig: taxConfig,
      depositAmount: depositAmount,
    );
  }

  static double _seasonBoost(DateTime date) {
    final month = date.month;
    if (month >= 6 && month <= 9) {
      return 1.08;
    }
    if (month == 12 || month == 1) {
      return 1.12;
    }
    return 1.0;
  }

  static String _rateSourceForDate(DateTime date) {
    final month = date.month;
    if (month >= 6 && month <= 9) {
      return 'peak-season rate';
    }
    if (month == 12 || month == 1) {
      return 'holiday rate';
    }
    return 'standard rate';
  }
}
