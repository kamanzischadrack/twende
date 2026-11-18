import 'dart:math' as math;
import '../../core/constants/app_constants.dart';
import '../../core/utils/duration_utils.dart';

/// Line item in a quote breakdown
class QuoteLine {
  final String description;
  final int quantity;
  final double unitPrice;
  final double amount;
  final bool isDiscount;
  final bool isTax;

  const QuoteLine({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    this.isDiscount = false,
    this.isTax = false,
  });

  Map<String, dynamic> toJson() => {
    'description': description,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'amount': amount,
    'isDiscount': isDiscount,
    'isTax': isTax,
  };
}

/// Rate plan pricing input
class RatePlanInput {
  final double dailyRate;
  final double? hourlyRate;
  final double? weeklyRate;
  final double? monthlyRate;
  final String currency;

  const RatePlanInput({
    required this.dailyRate,
    this.hourlyRate,
    this.weeklyRate,
    this.monthlyRate,
    this.currency = AppConstants.defaultCurrency,
  });

  double get effectiveHourlyRate => hourlyRate ?? (dailyRate / 24.0);
  double get effectiveWeeklyRate => weeklyRate ?? (dailyRate * 7);
  double get effectiveMonthlyRate => monthlyRate ?? (effectiveWeeklyRate * 4);
}

/// Mileage plan input
class MileagePlanInput {
  final bool isUnlimited;
  final int dailyAllowanceKm;
  final double ratePerExcessKm;
  final double dailyPackageFee;

  const MileagePlanInput({
    this.isUnlimited = false,
    this.dailyAllowanceKm = 150,
    this.ratePerExcessKm = 200.0,
    this.dailyPackageFee = 0.0,
  });
}

/// Extra item input (GPS, child seat, additional driver, etc.)
class ExtraInput {
  final String id;
  final String name;
  final double unitPrice;
  final bool perDay;
  final int quantity;
  final bool isTaxable;

  const ExtraInput({
    required this.id,
    required this.name,
    required this.unitPrice,
    this.perDay = true,
    this.quantity = 1,
    this.isTaxable = true,
  });
}

/// Discount input
class DiscountInput {
  final String id;
  final String name;
  final double? percent; // e.g. 15.0 for 15%
  final double? fixedAmount;

  const DiscountInput({
    required this.id,
    required this.name,
    this.percent,
    this.fixedAmount,
  });
}

/// Tax configuration
enum TaxMode { inclusive, exclusive, exempt }

class TaxConfig {
  final TaxMode mode;
  final double rate; // e.g. 0.18 for 18% VAT

  const TaxConfig({
    this.mode = TaxMode.exclusive,
    this.rate = 0.18,
  });
}

/// Complete computed quote result
class QuoteResult {
  final int billableDays;
  final String rateDecompositionDescription;
  final double baseRentalAmount;
  final double extrasAmount;
  final double mileagePackageAmount;
  final double subtotal;
  final double discountAmount;
  final double taxableAmount;
  final double taxAmount;
  final double totalAmount;
  final double depositAmount;
  final double totalPayableWithDeposit;
  final String currency;
  final List<QuoteLine> lines;
  final bool requiresApproval;
  final String? approvalReason;
  final bool isEstimate;

  const QuoteResult({
    required this.billableDays,
    required this.rateDecompositionDescription,
    required this.baseRentalAmount,
    required this.extrasAmount,
    required this.mileagePackageAmount,
    required this.subtotal,
    required this.discountAmount,
    required this.taxableAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.depositAmount,
    required this.totalPayableWithDeposit,
    required this.currency,
    required this.lines,
    this.requiresApproval = false,
    this.approvalReason,
    this.isEstimate = true,
  });
}

/// Twende SRS §8.1 Deterministic Cap-and-Compose Pricing Engine
class PricingEngine {
  /// Compute quote preview
  static QuoteResult compute({
    required DateTime pickupDateTime,
    required DateTime returnDateTime,
    required RatePlanInput ratePlan,
    MileagePlanInput mileagePlan = const MileagePlanInput(),
    List<ExtraInput> extras = const [],
    DiscountInput? discount,
    TaxConfig taxConfig = const TaxConfig(),
    double depositAmount = 0.0,
    double discountApprovalThresholdPercent = AppConstants.discountApprovalThreshold * 100,
  }) {
    final totalMinutes = returnDateTime.difference(pickupDateTime).inMinutes;
    final days = DurationUtils.billableDays(pickupDateTime, returnDateTime);
    final currency = ratePlan.currency;
    final lines = <QuoteLine>[];

    if (ratePlan.hourlyRate != null && totalMinutes > 0 && totalMinutes < 24 * 60) {
      final hourlyQuantity = (totalMinutes / 60.0).ceil();
      final hourlyBase = hourlyQuantity * ratePlan.effectiveHourlyRate;
      final decompositionDescription = '$hourlyQuantity hour${hourlyQuantity == 1 ? '' : 's'} @ ${ratePlan.effectiveHourlyRate.toStringAsFixed(0)} $currency';

      lines.add(QuoteLine(
        description: 'Vehicle Rental ($decompositionDescription)',
        quantity: hourlyQuantity,
        unitPrice: ratePlan.effectiveHourlyRate,
        amount: hourlyBase,
      ));

      final subtotal = hourlyBase;
      double discountAmount = 0.0;
      bool requiresApproval = false;
      String? approvalReason;

      if (discount != null) {
        if (discount.percent != null && discount.percent! > 0) {
          final pct = discount.percent!;
          discountAmount = (subtotal * pct) / 100.0;
          if (pct > discountApprovalThresholdPercent) {
            requiresApproval = true;
            approvalReason = 'Discount of ${pct.toStringAsFixed(1)}% exceeds approval threshold (${discountApprovalThresholdPercent.toStringAsFixed(0)}%)';
          }
        } else if (discount.fixedAmount != null && discount.fixedAmount! > 0) {
          discountAmount = math.min(subtotal, discount.fixedAmount!);
          final effectivePct = subtotal > 0 ? (discountAmount / subtotal) * 100.0 : 0.0;
          if (effectivePct > discountApprovalThresholdPercent) {
            requiresApproval = true;
            approvalReason = 'Discount of ${discountAmount.toStringAsFixed(0)} $currency exceeds approval threshold';
          }
        }

        if (discountAmount > 0) {
          lines.add(QuoteLine(
            description: 'Discount: ${discount.name}',
            quantity: 1,
            unitPrice: -discountAmount,
            amount: -discountAmount,
            isDiscount: true,
          ));
        }
      }

      final netSubtotal = math.max(0.0, subtotal - discountAmount);
      double taxableAmount = netSubtotal;
      double taxAmount = 0.0;
      double totalAmount = netSubtotal;

      if (taxConfig.mode == TaxMode.exclusive) {
        taxAmount = netSubtotal * taxConfig.rate;
        totalAmount = netSubtotal + taxAmount;
        if (taxAmount > 0) {
          lines.add(QuoteLine(
            description: 'VAT (${(taxConfig.rate * 100).toStringAsFixed(0)}%)',
            quantity: 1,
            unitPrice: taxAmount,
            amount: taxAmount,
            isTax: true,
          ));
        }
      } else if (taxConfig.mode == TaxMode.inclusive) {
        taxAmount = netSubtotal - (netSubtotal / (1.0 + taxConfig.rate));
        taxableAmount = netSubtotal - taxAmount;
        totalAmount = netSubtotal;
        lines.add(QuoteLine(
          description: 'Includes VAT (${(taxConfig.rate * 100).toStringAsFixed(0)}%): ${taxAmount.toStringAsFixed(0)} $currency',
          quantity: 1,
          unitPrice: 0,
          amount: 0,
          isTax: true,
        ));
      }

      final totalPayableWithDeposit = totalAmount + depositAmount;
      return QuoteResult(
        billableDays: 1,
        rateDecompositionDescription: decompositionDescription,
        baseRentalAmount: hourlyBase,
        extrasAmount: 0,
        mileagePackageAmount: 0,
        subtotal: subtotal,
        discountAmount: discountAmount,
        taxableAmount: taxableAmount,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        depositAmount: depositAmount,
        totalPayableWithDeposit: totalPayableWithDeposit,
        currency: currency,
        lines: lines,
        requiresApproval: requiresApproval,
        approvalReason: approvalReason,
        isEstimate: true,
      );
    }

    // 1. Cap-and-compose vehicle rental decomposition
    final decomposition = _calculateBestRate(
      days: days,
      dailyRate: ratePlan.dailyRate,
      weeklyRate: ratePlan.effectiveWeeklyRate,
      monthlyRate: ratePlan.effectiveMonthlyRate,
    );

    lines.add(QuoteLine(
      description: 'Vehicle Rental (${decomposition.description})',
      quantity: days,
      unitPrice: days > 0 ? (decomposition.totalCost / days) : 0,
      amount: decomposition.totalCost,
    ));

    // 2. Mileage package charge (if any)
    double mileagePackageAmount = 0.0;
    if (mileagePlan.dailyPackageFee > 0) {
      mileagePackageAmount = mileagePlan.dailyPackageFee * days;
      lines.add(QuoteLine(
        description: 'Mileage Package (${mileagePlan.isUnlimited ? "Unlimited" : "${mileagePlan.dailyAllowanceKm} km/day"})',
        quantity: days,
        unitPrice: mileagePlan.dailyPackageFee,
        amount: mileagePackageAmount,
      ));
    }

    // 3. Extras
    double extrasAmount = 0.0;
    for (final extra in extras) {
      if (extra.quantity <= 0) continue;
      final extraQty = extra.perDay ? (extra.quantity * days) : extra.quantity;
      final extraTotal = extra.unitPrice * extraQty;
      extrasAmount += extraTotal;
      lines.add(QuoteLine(
        description: '${extra.name} (${extra.perDay ? "$days days x ${extra.quantity}" : "qty ${extra.quantity}"})',
        quantity: extraQty,
        unitPrice: extra.unitPrice,
        amount: extraTotal,
      ));
    }

    final subtotal = decomposition.totalCost + mileagePackageAmount + extrasAmount;

    // 4. Discount computation
    double discountAmount = 0.0;
    bool requiresApproval = false;
    String? approvalReason;

    if (discount != null) {
      if (discount.percent != null && discount.percent! > 0) {
        final pct = discount.percent!;
        discountAmount = (subtotal * pct) / 100.0;
        if (pct > discountApprovalThresholdPercent) {
          requiresApproval = true;
          approvalReason = 'Discount of ${pct.toStringAsFixed(1)}% exceeds approval threshold (${discountApprovalThresholdPercent.toStringAsFixed(0)}%)';
        }
      } else if (discount.fixedAmount != null && discount.fixedAmount! > 0) {
        discountAmount = math.min(subtotal, discount.fixedAmount!);
        final effectivePct = subtotal > 0 ? (discountAmount / subtotal) * 100.0 : 0.0;
        if (effectivePct > discountApprovalThresholdPercent) {
          requiresApproval = true;
          approvalReason = 'Discount of ${discountAmount.toStringAsFixed(0)} $currency exceeds approval threshold';
        }
      }

      if (discountAmount > 0) {
        lines.add(QuoteLine(
          description: 'Discount: ${discount.name}',
          quantity: 1,
          unitPrice: -discountAmount,
          amount: -discountAmount,
          isDiscount: true,
        ));
      }
    }

    final netSubtotal = math.max(0.0, subtotal - discountAmount);

    // 5. Tax computation (VAT)
    double taxableAmount = netSubtotal;
    double taxAmount = 0.0;
    double totalAmount = netSubtotal;

    if (taxConfig.mode == TaxMode.exclusive) {
      taxAmount = netSubtotal * taxConfig.rate;
      totalAmount = netSubtotal + taxAmount;
      if (taxAmount > 0) {
        lines.add(QuoteLine(
          description: 'VAT (${(taxConfig.rate * 100).toStringAsFixed(0)}%)',
          quantity: 1,
          unitPrice: taxAmount,
          amount: taxAmount,
          isTax: true,
        ));
      }
    } else if (taxConfig.mode == TaxMode.inclusive) {
      taxAmount = netSubtotal - (netSubtotal / (1.0 + taxConfig.rate));
      taxableAmount = netSubtotal - taxAmount;
      totalAmount = netSubtotal;
      lines.add(QuoteLine(
        description: 'Includes VAT (${(taxConfig.rate * 100).toStringAsFixed(0)}%): ${taxAmount.toStringAsFixed(0)} $currency',
        quantity: 1,
        unitPrice: 0,
        amount: 0,
        isTax: true,
      ));
    }

    final totalPayableWithDeposit = totalAmount + depositAmount;

    return QuoteResult(
      billableDays: days,
      rateDecompositionDescription: decomposition.description,
      baseRentalAmount: decomposition.totalCost,
      extrasAmount: extrasAmount,
      mileagePackageAmount: mileagePackageAmount,
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxableAmount: taxableAmount,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      depositAmount: depositAmount,
      totalPayableWithDeposit: totalPayableWithDeposit,
      currency: currency,
      lines: lines,
      requiresApproval: requiresApproval,
      approvalReason: approvalReason,
      isEstimate: true,
    );
  }

  /// Evaluates combinations of months (30d), weeks (7d), and days, applying caps.
  /// Meets SRS §8.1 reference test cases:
  /// - 3d: 3*50k = 150k
  /// - 6d: 300k (W cap)
  /// - 10d: 450k (W + 3D)
  /// - 13d: 600k (2W cap)
  /// - 35d: 1,150k (M + 5D)
  static _DecompositionResult _calculateBestRate({
    required int days,
    required double dailyRate,
    required double weeklyRate,
    required double monthlyRate,
  }) {
    if (days <= 0) {
      return const _DecompositionResult(0, '0 days');
    }

    // Helper to evaluate days with weekly cap
    // e.g. for 6 days: min(6*D, W)
    // for 13 days: 1*W + min(6*D, W)
    double evalDaysWithWeeklyCap(int d) {
      final w = d ~/ 7;
      final remD = d % 7;
      final remCost = math.min(remD * dailyRate, weeklyRate);
      return (w * weeklyRate) + remCost;
    }

    // Option A: purely days capped by week
    double bestCost = evalDaysWithWeeklyCap(days);
    String bestDesc = '$days days';

    // Option B: decompose with month (30-day block) + remainder evaluated with weekly cap
    if (days >= 30) {
      final m = days ~/ 30;
      final remAfterM = days % 30;
      final costWithM = (m * monthlyRate) + evalDaysWithWeeklyCap(remAfterM);
      if (costWithM < bestCost) {
        bestCost = costWithM;
      }
    }

    // Also check if days >= 28 or near month whether monthlyRate caps it
    if (evalDaysWithWeeklyCap(days) > monthlyRate && days <= 30) {
      if (monthlyRate < bestCost) {
        bestCost = monthlyRate;
      }
    }

    // Formulate human readable description
    if (days >= 30 && bestCost >= monthlyRate) {
      final m = days ~/ 30;
      final rem = days % 30;
      final w = rem ~/ 7;
      final d = rem % 7;
      final parts = <String>[];
      if (m > 0) parts.add('$m month${m > 1 ? "s" : ""}');
      if (w > 0) parts.add('$w week${w > 1 ? "s" : ""}');
      if (d > 0) parts.add('$d day${d > 1 ? "s" : ""}');
      bestDesc = parts.join(' + ');
    } else if (days >= 7) {
      final w = days ~/ 7;
      final rem = days % 7;
      if (rem * dailyRate >= weeklyRate) {
        bestDesc = '${w + 1} weeks (capped)';
      } else if (rem > 0) {
        bestDesc = '$w week${w > 1 ? "s" : ""} + $rem day${rem > 1 ? "s" : ""}';
      } else {
        bestDesc = '$w week${w > 1 ? "s" : ""}';
      }
    } else {
      if (days * dailyRate >= weeklyRate) {
        bestDesc = '1 week (capped)';
      } else {
        bestDesc = '$days days';
      }
    }

    return _DecompositionResult(bestCost, bestDesc);
  }
}

class _DecompositionResult {
  final double totalCost;
  final String description;

  const _DecompositionResult(this.totalCost, this.description);
}
