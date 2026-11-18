/// Result of a domain validation check
class ValidationResult {
  final bool isValid;
  final String? errorCode;
  final String? errorMessage;

  const ValidationResult.valid()
      : isValid = true,
        errorCode = null,
        errorMessage = null;

  const ValidationResult.invalid({
    required this.errorCode,
    required this.errorMessage,
  }) : isValid = false;

  @override
  String toString() => isValid ? 'Valid' : 'Invalid($errorCode: $errorMessage)';
}

/// Twende Domain Business Rules Validator (Pure Dart, SRS aligned)
class ValidationRules {
  /// BR-05: Rental Date Range Check
  static ValidationResult checkDateRange({
    required DateTime pickup,
    required DateTime returnTime,
    int minimumRentalHours = 1,
    bool allowPastPickup = false,
  }) {
    final now = DateTime.now();

    if (!allowPastPickup && pickup.isBefore(now.subtract(const Duration(minutes: 15)))) {
      return const ValidationResult.invalid(
        errorCode: 'BR-05-PAST-PICKUP',
        errorMessage: 'Pickup time cannot be in the past.',
      );
    }

    if (!returnTime.isAfter(pickup)) {
      return const ValidationResult.invalid(
        errorCode: 'BR-05-ORDER',
        errorMessage: 'Return date & time must be strictly after pickup time.',
      );
    }

    final diff = returnTime.difference(pickup);
    if (diff.inHours < minimumRentalHours) {
      return ValidationResult.invalid(
        errorCode: 'BR-05-MIN-DURATION',
        errorMessage: 'Minimum rental duration is $minimumRentalHours hour(s).',
      );
    }

    return const ValidationResult.valid();
  }

  /// BR-04: Driver Licence & Eligibility Check
  static ValidationResult checkDriverEligibility({
    required DateTime? licenceExpiry,
    required DateTime? dateOfBirth,
    int minimumAgeYears = 21,
    int minimumLicenceYears = 1,
    bool isBlacklisted = false,
  }) {
    if (isBlacklisted) {
      return const ValidationResult.invalid(
        errorCode: 'BR-04-BLACKLIST',
        errorMessage: 'Driver is blacklisted or flagged for high risk.',
      );
    }

    final now = DateTime.now();

    if (licenceExpiry != null && licenceExpiry.isBefore(now)) {
      return const ValidationResult.invalid(
        errorCode: 'BR-04-EXPIRED-LICENCE',
        errorMessage: 'Driver licence has expired.',
      );
    }

    if (dateOfBirth != null) {
      final age = (now.difference(dateOfBirth).inDays / 365.25).floor();
      if (age < minimumAgeYears) {
        return ValidationResult.invalid(
          errorCode: 'BR-04-UNDERAGE',
          errorMessage: 'Driver is $age years old; minimum required age is $minimumAgeYears.',
        );
      }
    }

    return const ValidationResult.valid();
  }

  /// BR-06: Odometer / Mileage Check
  static ValidationResult checkMileage({
    required int startKm,
    required int returnKm,
    int maxSensibleDailyKm = 2000,
    int billableDays = 1,
  }) {
    if (returnKm < startKm) {
      return ValidationResult.invalid(
        errorCode: 'BR-06-REVERSED-ODOMETER',
        errorMessage: 'Return odometer ($returnKm km) cannot be less than pickup odometer ($startKm km).',
      );
    }

    final totalDriven = returnKm - startKm;
    final maxAllowed = (billableDays <= 0 ? 1 : billableDays) * maxSensibleDailyKm;
    if (totalDriven > maxAllowed) {
      return ValidationResult.invalid(
        errorCode: 'BR-06-UNREALISTIC-KM',
        errorMessage: 'Reported distance of $totalDriven km exceeds realistic threshold ($maxAllowed km). Please verify odometer reading.',
      );
    }

    return const ValidationResult.valid();
  }

  /// BR-07: Payment Amount Check
  static ValidationResult checkPaymentAmount({
    required double amount,
    required double balanceDue,
    bool allowOverpayment = false,
  }) {
    if (amount <= 0) {
      return const ValidationResult.invalid(
        errorCode: 'BR-07-NON-POSITIVE',
        errorMessage: 'Payment amount must be greater than zero.',
      );
    }

    if (!allowOverpayment && amount > (balanceDue + 1.0)) { // 1 unit float tolerance
      return const ValidationResult.invalid(
        errorCode: 'BR-07-OVERPAYMENT',
        errorMessage: 'Payment amount exceeds outstanding balance due.',
      );
    }

    return const ValidationResult.valid();
  }

  /// BR-13: Truck Cargo Payload Check
  static ValidationResult checkTruckPayload({
    required double cargoWeightKg,
    required double maxPayloadKg,
  }) {
    if (cargoWeightKg < 0) {
      return const ValidationResult.invalid(
        errorCode: 'BR-13-NEGATIVE-WEIGHT',
        errorMessage: 'Cargo weight cannot be negative.',
      );
    }

    if (cargoWeightKg > maxPayloadKg) {
      return ValidationResult.invalid(
        errorCode: 'BR-13-OVERLOAD',
        errorMessage: 'Cargo weight (${cargoWeightKg.toStringAsFixed(0)} kg) exceeds vehicle payload limit (${maxPayloadKg.toStringAsFixed(0)} kg).',
      );
    }

    return const ValidationResult.valid();
  }

  /// BR-14: Driver Schedule Conflict Check
  static ValidationResult checkDriverAvailability({
    required DateTime targetStart,
    required DateTime targetEnd,
    required List<({DateTime start, DateTime end, String tripId})> existingTrips,
    int bufferMinutes = 60,
  }) {
    final buffer = Duration(minutes: bufferMinutes);

    for (final trip in existingTrips) {
      final tripStartWithBuffer = trip.start.subtract(buffer);
      final tripEndWithBuffer = trip.end.add(buffer);

      // Overlap: (targetStart < tripEnd) && (targetEnd > tripStart)
      if (targetStart.isBefore(tripEndWithBuffer) && targetEnd.isAfter(tripStartWithBuffer)) {
        return ValidationResult.invalid(
          errorCode: 'BR-14-DRIVER-CONFLICT',
          errorMessage: 'Driver is already scheduled for Trip #${trip.tripId} during this period.',
        );
      }
    }

    return const ValidationResult.valid();
  }
}
