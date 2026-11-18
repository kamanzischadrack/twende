import '../core/auth/session_provider.dart';
import '../shared/domain/availability_checker.dart';
import '../shared/domain/enums.dart';
import '../shared/repositories/repository_interfaces.dart';

class FleetAvailabilitySummary {
  final TwendeVehicle vehicle;
  final AvailabilityCheckResult availability;

  const FleetAvailabilitySummary({
    required this.vehicle,
    required this.availability,
  });
}

class AvailabilityService {
  const AvailabilityService._();

  static List<FleetAvailabilitySummary> evaluateFleet({
    required List<TwendeVehicle> vehicles,
    required DateTime pickupDateTime,
    required DateTime returnDateTime,
    String? requiredBranchId,
    TenantConfig? tenantConfig,
  }) {
    final blocksByVehicle = <String, List<VehicleScheduleBlock>>{};
    final now = DateTime.now();
    final turnaroundBufferHours = tenantConfig?.turnaroundBufferHours ?? 2;

    for (final vehicle in vehicles) {
      final blocks = <VehicleScheduleBlock>[];

      switch (vehicle.status) {
        case VehicleStatus.rented:
          blocks.add(
            VehicleScheduleBlock(
              id: '${vehicle.id}-active-rental',
              vehicleId: vehicle.id,
              startDateTime: now.subtract(const Duration(days: 1)),
              endDateTime: now.add(const Duration(days: 2)),
              type: 'booking',
              referenceCode: 'ACTIVE_RENTAL',
            ),
          );
          break;
        case VehicleStatus.reserved:
          blocks.add(
            VehicleScheduleBlock(
              id: '${vehicle.id}-reservation',
              vehicleId: vehicle.id,
              startDateTime: now.add(const Duration(hours: 2)),
              endDateTime: now.add(const Duration(days: 1)),
              type: 'booking',
              referenceCode: 'RESERVED',
            ),
          );
          break;
        case VehicleStatus.underMaintenance:
          blocks.add(
            VehicleScheduleBlock(
              id: '${vehicle.id}-maintenance',
              vehicleId: vehicle.id,
              startDateTime: now.subtract(const Duration(days: 1)),
              endDateTime: now.add(const Duration(days: 4)),
              type: 'maintenance',
              referenceCode: 'MAINTENANCE',
            ),
          );
          break;
        case VehicleStatus.underInspection:
          blocks.add(
            VehicleScheduleBlock(
              id: '${vehicle.id}-inspection',
              vehicleId: vehicle.id,
              startDateTime: now.subtract(const Duration(hours: 3)),
              endDateTime: now.add(const Duration(hours: 18)),
              type: 'inspection',
              referenceCode: 'INSPECTION',
            ),
          );
          break;
        case VehicleStatus.outOfService:
        case VehicleStatus.accident:
        case VehicleStatus.sold:
        case VehicleStatus.archived:
        case VehicleStatus.returned:
        case VehicleStatus.available:
          break;
      }

      if (blocks.isNotEmpty) {
        blocksByVehicle[vehicle.id] = blocks;
      }
    }

    final summaries = <FleetAvailabilitySummary>[];
    for (final vehicle in vehicles) {
      final docs = <VehicleDocumentInfo>[
        VehicleDocumentInfo(
          type: 'insurance',
          expiryDate: DateTime.now().add(const Duration(days: 240)),
          isValid: true,
        ),
        VehicleDocumentInfo(
          type: 'inspection',
          expiryDate: returnDateTime.add(const Duration(days: 30)),
          isValid: true,
        ),
        VehicleDocumentInfo(
          type: 'road_tax',
          expiryDate: returnDateTime.add(const Duration(days: 120)),
          isValid: true,
        ),
      ];

      final result = AvailabilityChecker.checkVehicle(
        vehicleId: vehicle.id,
        currentStatus: vehicle.status,
        targetPickup: pickupDateTime,
        targetReturn: returnDateTime,
        existingBlocks: blocksByVehicle[vehicle.id] ?? const [],
        documents: docs,
        turnaroundBufferHours: turnaroundBufferHours,
        requiredBranchId: requiredBranchId,
        vehicleCurrentBranchId: vehicle.branchId,
      );

      summaries.add(
        FleetAvailabilitySummary(vehicle: vehicle, availability: result),
      );
    }

    summaries.sort((a, b) {
      final availableCompare = b.availability.isAvailable ? 1 : 0;
      final otherAvailableCompare = a.availability.isAvailable ? 1 : 0;
      final comparison = availableCompare.compareTo(otherAvailableCompare);
      if (comparison != 0) {
        return comparison;
      }
      return a.vehicle.name.compareTo(b.vehicle.name);
    });

    return summaries;
  }
}
