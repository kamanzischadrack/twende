import 'package:flutter_test/flutter_test.dart';
import 'package:twende_flutter/shared/domain/availability_checker.dart';
import 'package:twende_flutter/shared/domain/enums.dart';

void main() {
  group('AvailabilityChecker', () {
    test('marks a vehicle unavailable when it is out of service', () {
      final result = AvailabilityChecker.checkVehicle(
        vehicleId: 'veh_09',
        currentStatus: VehicleStatus.outOfService,
        targetPickup: DateTime(2026, 1, 10, 10),
        targetReturn: DateTime(2026, 1, 12, 10),
        existingBlocks: const [],
      );

      expect(result.isAvailable, isFalse);
      expect(result.conflicts.any((c) => c.reasonCode == 'STATUS_UNAVAILABLE'), isTrue);
    });

    test('detects schedule overlap with the turnaround buffer', () {
      final blocks = [
        VehicleScheduleBlock(
          id: 'bk_001',
          vehicleId: 'veh_09',
          startDateTime: DateTime(2026, 1, 10, 8),
          endDateTime: DateTime(2026, 1, 10, 18),
          type: 'booking',
          referenceCode: 'BK-2026-1001',
        ),
      ];

      final result = AvailabilityChecker.checkVehicle(
        vehicleId: 'veh_09',
        currentStatus: VehicleStatus.available,
        targetPickup: DateTime(2026, 1, 10, 17),
        targetReturn: DateTime(2026, 1, 10, 22),
        existingBlocks: blocks,
      );

      expect(result.isAvailable, isFalse);
      expect(result.conflicts.any((c) => c.reasonCode == 'SCHEDULE_OVERLAP'), isTrue);
    });

    test('flags expired vehicle documents before the requested return', () {
      final result = AvailabilityChecker.checkVehicle(
        vehicleId: 'veh_09',
        currentStatus: VehicleStatus.available,
        targetPickup: DateTime(2026, 1, 15, 10),
        targetReturn: DateTime(2026, 1, 18, 10),
        existingBlocks: const [],
        documents: [
          VehicleDocumentInfo(
            type: 'insurance',
            expiryDate: DateTime(2026, 1, 16),
            isValid: true,
          ),
        ],
      );

      expect(result.isAvailable, isFalse);
      expect(result.conflicts.any((c) => c.reasonCode == 'EXPIRED_DOCUMENT'), isTrue);
    });

    test('allows a vehicle when status, branch and documents are compliant', () {
      final result = AvailabilityChecker.checkVehicle(
        vehicleId: 'veh_09',
        currentStatus: VehicleStatus.available,
        targetPickup: DateTime(2026, 2, 2, 9),
        targetReturn: DateTime(2026, 2, 5, 9),
        existingBlocks: const [],
        documents: [
          VehicleDocumentInfo(
            type: 'insurance',
            expiryDate: DateTime(2026, 12, 31),
            isValid: true,
          ),
          VehicleDocumentInfo(
            type: 'inspection',
            expiryDate: DateTime(2026, 9, 30),
            isValid: true,
          ),
        ],
        requiredBranchId: 'b_kgl_01',
        vehicleCurrentBranchId: 'b_kgl_01',
      );

      expect(result.isAvailable, isTrue);
      expect(result.conflicts, isEmpty);
    });
  });
}
