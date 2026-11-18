import '../domain/enums.dart';

/// Standard pagination container
class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => (page * pageSize) < totalCount;
}

/// Twende Vehicle Domain Entity
class TwendeVehicle {
  final String id;
  final String name;
  final String make;
  final String model;
  final int year;
  final String plateNumber;
  final String category;
  final VehicleStatus status;
  final String fuelType;
  final int mileage;
  final String branchId;
  final String branchName;
  final double dailyRate;
  final String? imageUrl;
  final List<String> equipment;

  const TwendeVehicle({
    required this.id,
    required this.name,
    required this.make,
    required this.model,
    required this.year,
    required this.plateNumber,
    required this.category,
    required this.status,
    required this.fuelType,
    required this.mileage,
    required this.branchId,
    required this.branchName,
    required this.dailyRate,
    this.imageUrl,
    this.equipment = const [],
  });
}

/// Twende Customer Entity
class TwendeCustomer {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final CustomerType type;
  final String? companyName;
  final String? nationalId;
  final String? licenceNumber;
  final DateTime? licenceExpiry;
  final RiskLevel riskLevel;
  final double creditLimit;
  final double outstandingBalance;

  const TwendeCustomer({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.type,
    this.companyName,
    this.nationalId,
    this.licenceNumber,
    this.licenceExpiry,
    this.riskLevel = RiskLevel.standard,
    this.creditLimit = 0.0,
    this.outstandingBalance = 0.0,
  });
}

/// Twende Contract Entity
class TwendeContract {
  final String id;
  final String contractNumber;
  final String? bookingId;
  final String customerId;
  final String customerName;
  final String vehicleId;
  final String vehicleName;
  final String vehiclePlate;
  final DateTime pickupDateTime;
  final DateTime returnDateTime;
  final ContractStatus status;
  final double totalAmount;
  final double depositAmount;
  final double balanceDue;
  final bool isSigned;
  final String? handoverInspectionId;
  final String? returnInspectionId;

  const TwendeContract({
    required this.id,
    required this.contractNumber,
    this.bookingId,
    required this.customerId,
    required this.customerName,
    required this.vehicleId,
    required this.vehicleName,
    required this.vehiclePlate,
    required this.pickupDateTime,
    required this.returnDateTime,
    required this.status,
    required this.totalAmount,
    required this.depositAmount,
    required this.balanceDue,
    this.isSigned = false,
    this.handoverInspectionId,
    this.returnInspectionId,
  });
}

/// Twende Handover/Return Inspection Entity
class TwendeInspection {
  final String id;
  final String contractId;
  final String vehicleId;
  final String inspectionType; // 'handover' | 'return'
  final int odometerKm;
  final double fuelFraction;
  final Map<String, bool> checklist;
  final List<Map<String, dynamic>> damages;
  final List<String> photoUrls;
  final String? signatureData;
  final String inspectorName;
  final DateTime createdAt;

  const TwendeInspection({
    required this.id,
    required this.contractId,
    required this.vehicleId,
    required this.inspectionType,
    required this.odometerKm,
    required this.fuelFraction,
    required this.checklist,
    required this.damages,
    this.photoUrls = const [],
    this.signatureData,
    required this.inspectorName,
    required this.createdAt,
  });
}

/// Twende Invoice Entity
class TwendeInvoice {
  final String id;
  final String invoiceNumber;
  final String contractId;
  final String customerName;
  final DateTime issueDate;
  final DateTime dueDate;
  final double totalAmount;
  final double paidAmount;
  final double balanceDue;
  final FinancialDocStatus status;
  final String currency;

  const TwendeInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.contractId,
    required this.customerName,
    required this.issueDate,
    required this.dueDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceDue,
    required this.status,
    this.currency = 'RWF',
  });
}

/// Twende Work Order (Maintenance)
class TwendeWorkOrder {
  final String id;
  final String workOrderNumber;
  final String vehicleId;
  final String vehiclePlate;
  final String serviceType;
  final WorkOrderStatus status;
  final double estimatedCost;
  final double actualCost;
  final DateTime scheduledDate;
  final String notes;

  const TwendeWorkOrder({
    required this.id,
    required this.workOrderNumber,
    required this.vehicleId,
    required this.vehiclePlate,
    required this.serviceType,
    required this.status,
    required this.estimatedCost,
    required this.actualCost,
    required this.scheduledDate,
    required this.notes,
  });
}

/// Twende Trip Entity (Drivers & Logistics)
class TwendeTrip {
  final String id;
  final String tripNumber;
  final String contractId;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String vehicleId;
  final String vehiclePlate;
  final String vehicleName;
  final String clientName;
  final String clientPhone;
  final String origin;
  final String destination;
  final List<String> stops;
  final String cargoType;
  final double cargoWeightKg;
  final double cargoVolumeM3;
  final String sealNumber;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final TripStatus status;
  final int estimatedKm;
  final double revenueRwf;
  final double fuelCostRwf;
  final double tollCostRwf;
  final double driverAllowanceRwf;
  final double otherExpensesRwf;
  final bool checklistCompleted;
  final DateTime? checklistCompletedAt;
  final String? podRecipientName;
  final String? podRecipientPhone;
  final String? podSignatureData;
  final DateTime? podCompletedAt;
  final List<String> deliveryPhotoUrls;
  final String? notes;

  const TwendeTrip({
    required this.id,
    required this.tripNumber,
    required this.contractId,
    required this.driverId,
    required this.driverName,
    this.driverPhone = '+250 788 112 233',
    required this.vehicleId,
    required this.vehiclePlate,
    this.vehicleName = 'Commercial Hauler',
    this.clientName = 'Corporate Logistics Client',
    this.clientPhone = '+250 788 445 566',
    required this.origin,
    required this.destination,
    this.stops = const [],
    this.cargoType = 'General Cargo',
    required this.cargoWeightKg,
    this.cargoVolumeM3 = 20.0,
    this.sealNumber = 'RW-SEAL-88902',
    required this.startDateTime,
    required this.endDateTime,
    required this.status,
    this.estimatedKm = 180,
    this.revenueRwf = 650000.0,
    this.fuelCostRwf = 120000.0,
    this.tollCostRwf = 25000.0,
    this.driverAllowanceRwf = 40000.0,
    this.otherExpensesRwf = 10000.0,
    this.checklistCompleted = false,
    this.checklistCompletedAt,
    this.podRecipientName,
    this.podRecipientPhone,
    this.podSignatureData,
    this.podCompletedAt,
    this.deliveryPhotoUrls = const [],
    this.notes,
  });

  double get totalCosts =>
      fuelCostRwf + tollCostRwf + driverAllowanceRwf + otherExpensesRwf;

  double get marginRwf => revenueRwf - totalCosts;

  double get marginPercent =>
      revenueRwf > 0 ? (marginRwf / revenueRwf) * 100 : 0.0;

  TwendeTrip copyWith({
    String? id,
    String? tripNumber,
    String? contractId,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? vehicleId,
    String? vehiclePlate,
    String? vehicleName,
    String? clientName,
    String? clientPhone,
    String? origin,
    String? destination,
    List<String>? stops,
    String? cargoType,
    double? cargoWeightKg,
    double? cargoVolumeM3,
    String? sealNumber,
    DateTime? startDateTime,
    DateTime? endDateTime,
    TripStatus? status,
    int? estimatedKm,
    double? revenueRwf,
    double? fuelCostRwf,
    double? tollCostRwf,
    double? driverAllowanceRwf,
    double? otherExpensesRwf,
    bool? checklistCompleted,
    DateTime? checklistCompletedAt,
    String? podRecipientName,
    String? podRecipientPhone,
    String? podSignatureData,
    DateTime? podCompletedAt,
    List<String>? deliveryPhotoUrls,
    String? notes,
  }) {
    return TwendeTrip(
      id: id ?? this.id,
      tripNumber: tripNumber ?? this.tripNumber,
      contractId: contractId ?? this.contractId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      vehicleId: vehicleId ?? this.vehicleId,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleName: vehicleName ?? this.vehicleName,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      stops: stops ?? this.stops,
      cargoType: cargoType ?? this.cargoType,
      cargoWeightKg: cargoWeightKg ?? this.cargoWeightKg,
      cargoVolumeM3: cargoVolumeM3 ?? this.cargoVolumeM3,
      sealNumber: sealNumber ?? this.sealNumber,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      status: status ?? this.status,
      estimatedKm: estimatedKm ?? this.estimatedKm,
      revenueRwf: revenueRwf ?? this.revenueRwf,
      fuelCostRwf: fuelCostRwf ?? this.fuelCostRwf,
      tollCostRwf: tollCostRwf ?? this.tollCostRwf,
      driverAllowanceRwf: driverAllowanceRwf ?? this.driverAllowanceRwf,
      otherExpensesRwf: otherExpensesRwf ?? this.otherExpensesRwf,
      checklistCompleted: checklistCompleted ?? this.checklistCompleted,
      checklistCompletedAt: checklistCompletedAt ?? this.checklistCompletedAt,
      podRecipientName: podRecipientName ?? this.podRecipientName,
      podRecipientPhone: podRecipientPhone ?? this.podRecipientPhone,
      podSignatureData: podSignatureData ?? this.podSignatureData,
      podCompletedAt: podCompletedAt ?? this.podCompletedAt,
      deliveryPhotoUrls: deliveryPhotoUrls ?? this.deliveryPhotoUrls,
      notes: notes ?? this.notes,
    );
  }
}

/// Trip Expense Entity (Fuel, Tolls, Allowances)
class TripExpense {
  final String id;
  final String tripId;
  final String type; // Fuel, Toll, Border, Parking, Allowance, Loading
  final int amountRwf;
  final String? receiptPhotoUrl;
  final DateTime timestamp;
  final String? locationGps;
  final String? notes;
  final bool isSynced;

  const TripExpense({
    required this.id,
    required this.tripId,
    required this.type,
    required this.amountRwf,
    this.receiptPhotoUrl,
    required this.timestamp,
    this.locationGps,
    this.notes,
    this.isSynced = true,
  });
}

/// Trip Incident Entity (Breakdown, Accident, Flat tyre)
class TripIncident {
  final String id;
  final String tripId;
  final String vehiclePlate;
  final String driverName;
  final String type; // Breakdown, Flat Tyre, Accident, Roadblock, Other
  final String severity; // Low, Medium, Critical
  final String description;
  final String? photoUrl;
  final DateTime timestamp;
  final String? locationGps;
  final String status; // Reported, Under Assessment, Resolved

  const TripIncident({
    required this.id,
    required this.tripId,
    required this.vehiclePlate,
    required this.driverName,
    required this.type,
    required this.severity,
    required this.description,
    this.photoUrl,
    required this.timestamp,
    this.locationGps,
    this.status = 'Reported',
  });
}

/// Twende Approval Request
class TwendeApproval {
  final String id;
  final String title;
  final String type; // 'discount', 'refund', 'status_override'
  final String requestedBy;
  final double amount;
  final String reason;
  final ApprovalStatus status;
  final DateTime createdAt;

  const TwendeApproval({
    required this.id,
    required this.title,
    required this.type,
    required this.requestedBy,
    required this.amount,
    required this.reason,
    required this.status,
    required this.createdAt,
  });
}

/// Twende KPI Dashboard Data
class DashboardKpis {
  final int availableVehicles;
  final int totalFleet;
  final int activeRentals;
  final int pickupsToday;
  final int returnsToday;
  final int overdueReturns;
  final double revenueMtd;
  final String currency;

  const DashboardKpis({
    required this.availableVehicles,
    required this.totalFleet,
    required this.activeRentals,
    required this.pickupsToday,
    required this.returnsToday,
    required this.overdueReturns,
    required this.revenueMtd,
    this.currency = 'RWF',
  });

  double get totalRevenueRwf => revenueMtd;
  double get fleetUtilizationPct =>
      totalFleet > 0 ? (activeRentals / totalFleet) * 100 : 0.0;
}

// -------------------------------------------------------------
// Abstract Repository Interfaces (Mock vs Remote Swappable via DI)
// -------------------------------------------------------------

abstract class FleetRepository {
  Future<PaginatedResult<TwendeVehicle>> getVehicles({
    String? branchId,
    VehicleStatus? status,
    String? search,
    int page = 1,
    int pageSize = 20,
  });
  Future<TwendeVehicle?> getVehicleById(String id);
  Future<bool> updateVehicleStatus(String id, VehicleStatus newStatus, String reason);
}

abstract class CustomerRepository {
  Future<PaginatedResult<TwendeCustomer>> getCustomers({
    String? search,
    CustomerType? type,
    int page = 1,
    int pageSize = 20,
  });
  Future<TwendeCustomer?> getCustomerById(String id);
  Future<TwendeCustomer> createCustomer(TwendeCustomer customer);
}

abstract class ContractRepository {
  Future<PaginatedResult<TwendeContract>> getContracts({
    String? branchId,
    ContractStatus? status,
    int page = 1,
    int pageSize = 20,
  });
  Future<TwendeContract?> getContractById(String id);
  Future<TwendeContract> createContract(TwendeContract contract);
  Future<bool> submitInspection(TwendeInspection inspection);
}

abstract class BillingRepository {
  Future<PaginatedResult<TwendeInvoice>> getInvoices({
    FinancialDocStatus? status,
    int page = 1,
    int pageSize = 20,
  });
  Future<bool> recordPayment(String invoiceId, double amount, PaymentMethod method, String reference);
}

abstract class DashboardRepository {
  Future<DashboardKpis> getKpis({String? branchId});
}

abstract class MaintenanceRepository {
  Future<PaginatedResult<TwendeWorkOrder>> getWorkOrders({
    WorkOrderStatus? status,
    int page = 1,
    int pageSize = 20,
  });
  Future<TwendeWorkOrder> createWorkOrder(TwendeWorkOrder order);
}

abstract class TripRepository {
  Future<PaginatedResult<TwendeTrip>> getTrips({
    TripStatus? status,
    String? driverId,
    String? search,
    int page = 1,
    int pageSize = 20,
  });
  Future<TwendeTrip?> getTripById(String id);
  Future<TwendeTrip> createTrip(TwendeTrip trip);
  Future<TwendeTrip> updateTrip(TwendeTrip trip);
  Future<void> submitPreTripChecklist(
    String tripId, {
    required String sealNumber,
    required List<String> photos,
  });
  Future<void> logExpense(TripExpense expense);
  Future<List<TripExpense>> getExpensesForTrip(String tripId);
  Future<void> reportIncident(TripIncident incident);
  Future<List<TripIncident>> getIncidents({String? tripId});
  Future<void> submitPod(
    String tripId, {
    required String recipientName,
    required String recipientPhone,
    required String signatureData,
    required List<String> photoUrls,
    String? notes,
  });
}

abstract class ApprovalRepository {
  Future<List<TwendeApproval>> getApprovals({ApprovalStatus? status});
  Future<bool> processApproval(String id, bool approve, String notes);
}
