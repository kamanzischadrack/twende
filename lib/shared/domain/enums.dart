// lib/shared/domain/enums.dart
// Twende domain enums — pure Dart, no Flutter deps.

/// Vehicle lifecycle status (SRS §4.3)
enum VehicleStatus {
  available,
  reserved,
  rented,
  returned,
  underInspection,
  underMaintenance,
  accident,
  outOfService,
  sold,
  archived,
}

extension VehicleStatusX on VehicleStatus {
  String get label {
    switch (this) {
      case VehicleStatus.available:        return 'Available';
      case VehicleStatus.reserved:         return 'Reserved';
      case VehicleStatus.rented:           return 'Rented';
      case VehicleStatus.returned:         return 'Returned';
      case VehicleStatus.underInspection:  return 'Under Inspection';
      case VehicleStatus.underMaintenance: return 'Under Maintenance';
      case VehicleStatus.accident:         return 'Accident';
      case VehicleStatus.outOfService:     return 'Out of Service';
      case VehicleStatus.sold:             return 'Sold';
      case VehicleStatus.archived:         return 'Archived';
    }
  }
  bool get isRentable => this == VehicleStatus.available;
  bool get isActive   => this == VehicleStatus.rented;
  bool get isArchived => this == VehicleStatus.sold || this == VehicleStatus.archived;

  static VehicleStatus fromString(String s) {
    return VehicleStatus.values.firstWhere(
      (e) => e.name == s || e.label.toLowerCase() == s.toLowerCase(),
      orElse: () => VehicleStatus.outOfService,
    );
  }
}

/// Booking lifecycle status (SRS §4.3)
enum TwendeBookingStatus {
  inquiry,
  pending,
  confirmed,
  cancelled,
  noShow,
  convertedToRental,
  completed,
}

extension TwendeBookingStatusX on TwendeBookingStatus {
  String get label {
    switch (this) {
      case TwendeBookingStatus.inquiry:           return 'Inquiry';
      case TwendeBookingStatus.pending:           return 'Pending';
      case TwendeBookingStatus.confirmed:         return 'Confirmed';
      case TwendeBookingStatus.cancelled:         return 'Cancelled';
      case TwendeBookingStatus.noShow:            return 'No Show';
      case TwendeBookingStatus.convertedToRental: return 'Active Rental';
      case TwendeBookingStatus.completed:         return 'Completed';
    }
  }
}

/// Contract lifecycle status (SRS §4.3)
enum ContractStatus { draft, active, extended, closed, cancelled }

extension ContractStatusX on ContractStatus {
  String get label {
    switch (this) {
      case ContractStatus.draft:      return 'Draft';
      case ContractStatus.active:     return 'Active';
      case ContractStatus.extended:   return 'Extended';
      case ContractStatus.closed:     return 'Closed';
      case ContractStatus.cancelled:  return 'Cancelled';
    }
  }
  bool get isLocked =>
      this == ContractStatus.active || this == ContractStatus.closed;
}

/// Damage workflow status
enum DamageStatus {
  reported,
  underAssessment,
  approved,
  underRepair,
  repaired,
  insuranceClaim,
  customerCharged,
  closed,
}

/// Work order status (maintenance)
enum WorkOrderStatus { planned, inProgress, completed, cancelled }

extension WorkOrderStatusX on WorkOrderStatus {
  String get label {
    switch (this) {
      case WorkOrderStatus.planned:
        return 'Planned';
      case WorkOrderStatus.inProgress:
        return 'In Progress';
      case WorkOrderStatus.completed:
        return 'Completed';
      case WorkOrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Trip status (truck operations)
enum TripStatus { planned, inProgress, delivered, closed, cancelled }

extension TripStatusX on TripStatus {
  String get label {
    switch (this) {
      case TripStatus.planned:
        return 'Planned';
      case TripStatus.inProgress:
        return 'In Progress';
      case TripStatus.delivered:
        return 'Delivered';
      case TripStatus.closed:
        return 'Closed';
      case TripStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Payment/financial document display status
enum FinancialDocStatus { pending, confirmed, failed, reversed }

/// Approval workflow status
enum ApprovalStatus { pending, approved, rejected }

/// Offline sync item status
enum SyncItemStatus { queued, syncing, synced, conflict, failed }

extension SyncItemStatusX on SyncItemStatus {
  bool get needsAction => this == SyncItemStatus.conflict || this == SyncItemStatus.failed;
}

/// Fuel policy (Twende-extended)
enum TwendeFuelPolicy {
  likeForLike,
  fullToFull,
  prepaid,
  fuelIncluded, // trucks
}

extension TwendeFuelPolicyX on TwendeFuelPolicy {
  String get label {
    switch (this) {
      case TwendeFuelPolicy.likeForLike:   return 'Like for Like';
      case TwendeFuelPolicy.fullToFull:    return 'Full to Full';
      case TwendeFuelPolicy.prepaid:       return 'Prepaid';
      case TwendeFuelPolicy.fuelIncluded:  return 'Fuel Included';
    }
  }
}

/// Customer type
enum CustomerType {
  individual, corporate, government, ngo, agency, hotel, insurer
}

extension CustomerTypeX on CustomerType {
  String get label {
    switch (this) {
      case CustomerType.individual:  return 'Individual';
      case CustomerType.corporate:   return 'Corporate';
      case CustomerType.government:  return 'Government';
      case CustomerType.ngo:         return 'NGO';
      case CustomerType.agency:      return 'Agency';
      case CustomerType.hotel:       return 'Hotel';
      case CustomerType.insurer:     return 'Insurer';
    }
  }
}

/// Customer risk level
enum RiskLevel { standard, watch, blacklisted }

extension RiskLevelX on RiskLevel {
  bool get blocksBooking => this == RiskLevel.blacklisted;
  bool get requiresApproval => this == RiskLevel.watch;
}

/// Damage severity
enum DamageSeverity { minor, moderate, major, totalLoss }

extension DamageSeverityX on DamageSeverity {
  String get label {
    switch (this) {
      case DamageSeverity.minor:      return 'Minor';
      case DamageSeverity.moderate:   return 'Moderate';
      case DamageSeverity.major:      return 'Major';
      case DamageSeverity.totalLoss:  return 'Total Loss';
    }
  }
}

/// Payment method
enum PaymentMethod {
  cash, momoMtn, momoAirtel, bankTransfer, card, corporateAccount, paymentLink
}

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:             return 'Cash';
      case PaymentMethod.momoMtn:          return 'MTN MoMo';
      case PaymentMethod.momoAirtel:       return 'Airtel Money';
      case PaymentMethod.bankTransfer:     return 'Bank Transfer';
      case PaymentMethod.card:             return 'Card';
      case PaymentMethod.corporateAccount: return 'Corporate Account';
      case PaymentMethod.paymentLink:      return 'Payment Link';
    }
  }
}

/// Checklist item category (handover/return)
enum ChecklistCategory {
  exterior, interior, tyres, lights, documents, equipment, cargo
}
