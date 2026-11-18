import 'dart:math' as math;
import '../../core/constants/app_constants.dart';

/// Late return fee breakdown
class LateReturnResult {
  final int lateMinutes;
  final int billableLateHours;
  final double lateFee;
  final bool withinGracePeriod;
  final String description;

  const LateReturnResult({
    required this.lateMinutes,
    required this.billableLateHours,
    required this.lateFee,
    required this.withinGracePeriod,
    required this.description,
  });
}

/// Excess mileage fee breakdown
class ExcessMileageResult {
  final int startOdometerKm;
  final int returnOdometerKm;
  final int totalDrivenKm;
  final int allowedKm;
  final int excessKm;
  final double ratePerExcessKm;
  final double fee;
  final bool isUnlimited;
  final String description;

  const ExcessMileageResult({
    required this.startOdometerKm,
    required this.returnOdometerKm,
    required this.totalDrivenKm,
    required this.allowedKm,
    required this.excessKm,
    required this.ratePerExcessKm,
    required this.fee,
    required this.isUnlimited,
    required this.description,
  });
}

/// Fuel charge breakdown
class FuelReconciliationResult {
  final double handoverFraction; // 0.0 - 1.0
  final double returnFraction;   // 0.0 - 1.0
  final double tankCapacityLitres;
  final double fuelPricePerLitre;
  final double refuelAdminFee;
  final double shortageLitres;
  final double fuelCharge;
  final bool isShortage;
  final String description;

  const FuelReconciliationResult({
    required this.handoverFraction,
    required this.returnFraction,
    required this.tankCapacityLitres,
    required this.fuelPricePerLitre,
    required this.refuelAdminFee,
    required this.shortageLitres,
    required this.fuelCharge,
    required this.isShortage,
    required this.description,
  });
}

/// Complete return reconciliation statement
class ReconciliationSummary {
  final LateReturnResult lateReturn;
  final ExcessMileageResult excessMileage;
  final FuelReconciliationResult fuel;
  final double newDamageCharges;
  final double cleaningOrOtherFees;
  final double totalAdditionalCharges;
  final double depositHeld;
  final double balanceDue;   // customer pays this
  final double refundDue;    // refund to customer
  final bool requiresRefundApproval;
  final String? refundApprovalReason;
  final bool isEstimate;

  const ReconciliationSummary({
    required this.lateReturn,
    required this.excessMileage,
    required this.fuel,
    required this.newDamageCharges,
    required this.cleaningOrOtherFees,
    required this.totalAdditionalCharges,
    required this.depositHeld,
    required this.balanceDue,
    required this.refundDue,
    required this.requiresRefundApproval,
    this.refundApprovalReason,
    this.isEstimate = true,
  });
}

/// Twende Return Reconciliation Engine (Pure Dart)
class ReconciliationEngine {
  /// Calculate late return fee
  static LateReturnResult calculateLateReturn({
    required DateTime scheduledReturn,
    required DateTime actualReturn,
    required double dailyRate,
    int graceMinutes = AppConstants.lateReturnGraceMinutes,
    double? customHourlyLateRate,
  }) {
    final diff = actualReturn.difference(scheduledReturn);
    final totalMinutes = diff.inMinutes;

    if (totalMinutes <= graceMinutes) {
      return LateReturnResult(
        lateMinutes: math.max(0, totalMinutes),
        billableLateHours: 0,
        lateFee: 0.0,
        withinGracePeriod: true,
        description: totalMinutes <= 0
            ? 'Returned on time'
            : 'Within $graceMinutes min grace period',
      );
    }

    // Hourly rate default: dailyRate / 24, or custom rate
    final hourlyRate = customHourlyLateRate ?? (dailyRate / 24.0);
    // Round up partial hours after grace period
    final billableHours = ((totalMinutes - graceMinutes) / 60.0).ceil();
    // Cap fee per 24 hours at dailyRate
    final daysLate = billableHours ~/ 24;
    final remHours = billableHours % 24;
    final fee = (daysLate * dailyRate) + math.min(remHours * hourlyRate, dailyRate);

    return LateReturnResult(
      lateMinutes: totalMinutes,
      billableLateHours: billableHours,
      lateFee: fee,
      withinGracePeriod: false,
      description: 'Late by ${billableHours}h (exceeded $graceMinutes min grace)',
    );
  }

  /// Calculate excess mileage charge (BR-06: return >= start)
  static ExcessMileageResult calculateExcessMileage({
    required int startOdometerKm,
    required int returnOdometerKm,
    required int billableDays,
    required int dailyAllowanceKm,
    required double ratePerExcessKm,
    bool isUnlimited = false,
  }) {
    if (returnOdometerKm < startOdometerKm) {
      throw ArgumentError(
        'Return odometer ($returnOdometerKm km) cannot be less than handover odometer ($startOdometerKm km).',
      );
    }

    final totalDriven = returnOdometerKm - startOdometerKm;
    if (isUnlimited) {
      return ExcessMileageResult(
        startOdometerKm: startOdometerKm,
        returnOdometerKm: returnOdometerKm,
        totalDrivenKm: totalDriven,
        allowedKm: -1,
        excessKm: 0,
        ratePerExcessKm: ratePerExcessKm,
        fee: 0.0,
        isUnlimited: true,
        description: 'Unlimited mileage plan ($totalDriven km driven)',
      );
    }

    final allowed = dailyAllowanceKm * billableDays;
    final excess = math.max(0, totalDriven - allowed);
    final fee = excess * ratePerExcessKm;

    return ExcessMileageResult(
      startOdometerKm: startOdometerKm,
      returnOdometerKm: returnOdometerKm,
      totalDrivenKm: totalDriven,
      allowedKm: allowed,
      excessKm: excess,
      ratePerExcessKm: ratePerExcessKm,
      fee: fee,
      isUnlimited: false,
      description: excess > 0
          ? '$excess km excess @ $ratePerExcessKm/km ($totalDriven of $allowed km)'
          : 'Within allowance ($totalDriven of $allowed km)',
    );
  }

  /// Calculate fuel discrepancy charge
  static FuelReconciliationResult calculateFuel({
    required double handoverFraction,
    required double returnFraction,
    double tankCapacityLitres = 55.0,
    double fuelPricePerLitre = 1650.0,
    double refuelAdminFee = 5000.0,
  }) {
    final diff = handoverFraction - returnFraction;
    if (diff > 0.02) { // Allow 2% tolerance
      final shortageLitres = diff * tankCapacityLitres;
      final fuelCost = shortageLitres * fuelPricePerLitre;
      final totalCharge = fuelCost + refuelAdminFee;

      return FuelReconciliationResult(
        handoverFraction: handoverFraction,
        returnFraction: returnFraction,
        tankCapacityLitres: tankCapacityLitres,
        fuelPricePerLitre: fuelPricePerLitre,
        refuelAdminFee: refuelAdminFee,
        shortageLitres: shortageLitres,
        fuelCharge: totalCharge,
        isShortage: true,
        description: 'Fuel shortage: ${(diff * 100).toStringAsFixed(0)}% (~${shortageLitres.toStringAsFixed(1)}L)',
      );
    }

    return FuelReconciliationResult(
      handoverFraction: handoverFraction,
      returnFraction: returnFraction,
      tankCapacityLitres: tankCapacityLitres,
      fuelPricePerLitre: fuelPricePerLitre,
      refuelAdminFee: refuelAdminFee,
      shortageLitres: 0.0,
      fuelCharge: 0.0,
      isShortage: false,
      description: 'Fuel level matches or exceeds handover',
    );
  }

  /// Assemble full final reconciliation summary
  static ReconciliationSummary reconcile({
    required LateReturnResult lateReturn,
    required ExcessMileageResult excessMileage,
    required FuelReconciliationResult fuel,
    double newDamageCharges = 0.0,
    double cleaningOrOtherFees = 0.0,
    double depositHeld = 0.0,
    double refundApprovalThreshold = AppConstants.refundApprovalThresholdRwf,
  }) {
    final totalCharges = lateReturn.lateFee +
        excessMileage.fee +
        fuel.fuelCharge +
        newDamageCharges +
        cleaningOrOtherFees;

    double balanceDue = 0.0;
    double refundDue = 0.0;
    bool requiresRefundApproval = false;
    String? approvalReason;

    if (totalCharges > depositHeld) {
      balanceDue = totalCharges - depositHeld;
      refundDue = 0.0;
    } else {
      refundDue = depositHeld - totalCharges;
      balanceDue = 0.0;
      if (refundDue > refundApprovalThreshold) {
        requiresRefundApproval = true;
        approvalReason = 'Deposit refund of ${refundDue.toStringAsFixed(0)} RWF exceeds threshold (${refundApprovalThreshold.toStringAsFixed(0)} RWF)';
      }
    }

    return ReconciliationSummary(
      lateReturn: lateReturn,
      excessMileage: excessMileage,
      fuel: fuel,
      newDamageCharges: newDamageCharges,
      cleaningOrOtherFees: cleaningOrOtherFees,
      totalAdditionalCharges: totalCharges,
      depositHeld: depositHeld,
      balanceDue: balanceDue,
      refundDue: refundDue,
      requiresRefundApproval: requiresRefundApproval,
      refundApprovalReason: approvalReason,
      isEstimate: true,
    );
  }
}
