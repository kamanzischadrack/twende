import '../../core/constants/app_constants.dart';
import 'enums.dart';

/// Representation of an existing vehicle booking or maintenance block
class VehicleScheduleBlock {
  final String id;
  final String vehicleId;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String type; // 'booking', 'maintenance', 'out_of_service'
  final String? referenceCode;

  const VehicleScheduleBlock({
    required this.id,
    required this.vehicleId,
    required this.startDateTime,
    required this.endDateTime,
    required this.type,
    this.referenceCode,
  });
}

/// Vehicle document status
class VehicleDocumentInfo {
  final String type; // 'insurance', 'inspection', 'road_tax'
  final DateTime expiryDate;
  final bool isValid;

  const VehicleDocumentInfo({
    required this.type,
    required this.expiryDate,
    required this.isValid,
  });
}

/// Conflict details when vehicle is not available
class AvailabilityConflict {
  final String reasonCode;
  final String message;
  final DateTime? conflictingPeriodStart;
  final DateTime? conflictingPeriodEnd;
  final String? conflictingReference;

  const AvailabilityConflict({
    required this.reasonCode,
    required this.message,
    this.conflictingPeriodStart,
    this.conflictingPeriodEnd,
    this.conflictingReference,
  });
}

/// Result of checking vehicle availability
class AvailabilityCheckResult {
  final bool isAvailable;
  final List<AvailabilityConflict> conflicts;

  const AvailabilityCheckResult({
    required this.isAvailable,
    this.conflicts = const [],
  });

  bool get hasConflict => !isAvailable;
}

/// Twende Deterministic Availability Checker (SRS §11 & BR-01)
class AvailabilityChecker {
  /// Check if a vehicle is available for a proposed window
  static AvailabilityCheckResult checkVehicle({
    required String vehicleId,
    required VehicleStatus currentStatus,
    required DateTime targetPickup,
    required DateTime targetReturn,
    required List<VehicleScheduleBlock> existingBlocks,
    List<VehicleDocumentInfo> documents = const [],
    int turnaroundBufferHours = AppConstants.turnaroundBufferHours,
    String? requiredBranchId,
    String? vehicleCurrentBranchId,
  }) {
    final conflicts = <AvailabilityConflict>[];

    // 1. Vehicle Lifecycle / Status Check (BR-10)
    if (currentStatus == VehicleStatus.outOfService ||
        currentStatus == VehicleStatus.accident ||
        currentStatus == VehicleStatus.sold ||
        currentStatus == VehicleStatus.archived) {
      conflicts.add(AvailabilityConflict(
        reasonCode: 'STATUS_UNAVAILABLE',
        message: 'Vehicle is currently ${currentStatus.label} and cannot be booked.',
      ));
    }

    // 2. Branch matching (if provided)
    if (requiredBranchId != null &&
        vehicleCurrentBranchId != null &&
        requiredBranchId != vehicleCurrentBranchId) {
      conflicts.add(const AvailabilityConflict(
        reasonCode: 'BRANCH_MISMATCH',
        message: 'Vehicle is stationed at a different branch.',
      ));
    }

    // 3. Document validity throughout requested rental window
    for (final doc in documents) {
      if (!doc.isValid || doc.expiryDate.isBefore(targetReturn)) {
        conflicts.add(AvailabilityConflict(
          reasonCode: 'EXPIRED_DOCUMENT',
          message: '${doc.type} expires on ${doc.expiryDate.toIso8601String().split("T").first}, before the requested return date.',
        ));
      }
    }

    // 4. Overlap detection with Turnaround Buffer (BR-01)
    final buffer = Duration(hours: turnaroundBufferHours);

    for (final block in existingBlocks) {
      if (block.vehicleId != vehicleId) continue;

      // Expand block by turnaround buffer to guarantee prep/cleaning time
      final blockStartWithBuffer = block.startDateTime.subtract(buffer);
      final blockEndWithBuffer = block.endDateTime.add(buffer);

      // Overlap formula: (targetPickup < blockEnd) AND (targetReturn > blockStart)
      if (targetPickup.isBefore(blockEndWithBuffer) && targetReturn.isAfter(blockStartWithBuffer)) {
        conflicts.add(AvailabilityConflict(
          reasonCode: 'SCHEDULE_OVERLAP',
          message: 'Conflicts with ${block.type} (${block.referenceCode ?? block.id}) from ${block.startDateTime.toLocal()} to ${block.endDateTime.toLocal()} including $turnaroundBufferHours-hour buffer.',
          conflictingPeriodStart: block.startDateTime,
          conflictingPeriodEnd: block.endDateTime,
          conflictingReference: block.referenceCode ?? block.id,
        ));
      }
    }

    return AvailabilityCheckResult(
      isAvailable: conflicts.isEmpty,
      conflicts: conflicts,
    );
  }
}
