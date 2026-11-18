import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/enums.dart';
import 'repository_interfaces.dart';

/// In-memory Mock Fleet Repository
class MockFleetRepository implements FleetRepository {
  final List<TwendeVehicle> _vehicles = [
    const TwendeVehicle(
      id: 'veh_01',
      name: 'Toyota Land Cruiser Prado',
      make: 'Toyota',
      model: 'Prado TXL',
      year: 2023,
      plateNumber: 'RAC 452 K',
      category: 'SUV / 4x4',
      status: VehicleStatus.available,
      fuelType: 'Diesel',
      mileage: 28400,
      branchId: 'b_kgl_01',
      branchName: 'Kigali HQ (Downtown)',
      dailyRate: 120000.0,
      equipment: ['4WD High/Low', 'Roof Rack', 'Tow Hitch', 'GPS Tracker'],
    ),
    const TwendeVehicle(
      id: 'veh_02',
      name: 'Toyota RAV4 AWD',
      make: 'Toyota',
      model: 'RAV4',
      year: 2022,
      plateNumber: 'RAD 118 B',
      category: 'Compact SUV',
      status: VehicleStatus.rented,
      fuelType: 'Gasoline',
      mileage: 41250,
      branchId: 'b_kgl_01',
      branchName: 'Kigali HQ (Downtown)',
      dailyRate: 65000.0,
      equipment: ['Sunroof', 'Reverse Camera', 'Apple CarPlay'],
    ),
    const TwendeVehicle(
      id: 'veh_03',
      name: 'Toyota Hilux Double Cab',
      make: 'Toyota',
      model: 'Hilux 2.8D',
      year: 2023,
      plateNumber: 'RAE 889 L',
      category: 'Pickup / Light Commercial',
      status: VehicleStatus.available,
      fuelType: 'Diesel',
      mileage: 19800,
      branchId: 'b_kgl_02',
      branchName: 'Kigali International Airport (KGL)',
      dailyRate: 90000.0,
      equipment: ['Bedliner', 'Bull Bar', 'Canopy', 'Winch'],
    ),
    const TwendeVehicle(
      id: 'veh_04',
      name: 'Toyota HiAce Minibus (14-seater)',
      make: 'Toyota',
      model: 'HiAce Commuter',
      year: 2021,
      plateNumber: 'RAB 771 Z',
      category: 'Passenger Van',
      status: VehicleStatus.underInspection,
      fuelType: 'Diesel',
      mileage: 82300,
      branchId: 'b_msz_01',
      branchName: 'Musanze Branch',
      dailyRate: 110000.0,
      equipment: ['AC front/rear', 'PA microphone', 'First Aid Kit'],
    ),
    const TwendeVehicle(
      id: 'veh_05',
      name: 'Fuso Canter 5-Ton Truck',
      make: 'Mitsubishi Fuso',
      model: 'Canter FE',
      year: 2020,
      plateNumber: 'RAC 902 M',
      category: 'Heavy Commercial / Truck',
      status: VehicleStatus.available,
      fuelType: 'Diesel',
      mileage: 112000,
      branchId: 'b_rbv_01',
      branchName: 'Rubavu / Gisenyi Border',
      dailyRate: 150000.0,
      equipment: ['Hydraulic Tailgate', 'Side Tarpaulins', 'Heavy Straps'],
    ),
    const TwendeVehicle(
      id: 'veh_06',
      name: 'Toyota Land Cruiser V8 (VIP)',
      make: 'Toyota',
      model: 'Land Cruiser 300 ZX',
      year: 2024,
      plateNumber: 'RAF 007 A',
      category: 'Luxury SUV',
      status: VehicleStatus.reserved,
      fuelType: 'Diesel',
      mileage: 8500,
      branchId: 'b_kgl_01',
      branchName: 'Kigali HQ (Downtown)',
      dailyRate: 250000.0,
      equipment: ['Executive Leather', 'Chauffeur Partition', 'Armored Glass (B4)'],
    ),
    const TwendeVehicle(
      id: 'veh_07',
      name: 'Suzuki Jimny 4x4',
      make: 'Suzuki',
      model: 'Jimny Sierra',
      year: 2023,
      plateNumber: 'RAD 543 X',
      category: 'Compact 4x4',
      status: VehicleStatus.underMaintenance,
      fuelType: 'Gasoline',
      mileage: 33100,
      branchId: 'b_msz_01',
      branchName: 'Musanze Branch',
      dailyRate: 50000.0,
      equipment: ['All-Terrain Tyres', 'Snorkel', 'Roof Tent Mount'],
    ),
  ];

  @override
  Future<PaginatedResult<TwendeVehicle>> getVehicles({
    String? branchId,
    VehicleStatus? status,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    var filtered = _vehicles.where((v) {
      if (branchId != null && branchId.isNotEmpty && v.branchId != branchId) {
        return false;
      }
      if (status != null && v.status != status) {
        return false;
      }
      if (search != null && search.trim().isNotEmpty) {
        final q = search.toLowerCase();
        final match = v.name.toLowerCase().contains(q) ||
            v.plateNumber.toLowerCase().contains(q) ||
            v.category.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();

    return PaginatedResult(
      items: filtered,
      totalCount: filtered.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<TwendeVehicle?> getVehicleById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _vehicles.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> updateVehicleStatus(String id, VehicleStatus newStatus, String reason) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _vehicles.indexWhere((v) => v.id == id);
    if (index >= 0) {
      final old = _vehicles[index];
      _vehicles[index] = TwendeVehicle(
        id: old.id,
        name: old.name,
        make: old.make,
        model: old.model,
        year: old.year,
        plateNumber: old.plateNumber,
        category: old.category,
        status: newStatus,
        fuelType: old.fuelType,
        mileage: old.mileage,
        branchId: old.branchId,
        branchName: old.branchName,
        dailyRate: old.dailyRate,
        imageUrl: old.imageUrl,
        equipment: old.equipment,
      );
      return true;
    }
    return false;
  }
}

/// In-memory Mock Customer Repository
class MockCustomerRepository implements CustomerRepository {
  final List<TwendeCustomer> _customers = [
    TwendeCustomer(
      id: 'cust_01',
      fullName: 'Jean-Paul Mugisha',
      email: 'jp.mugisha@gmail.com',
      phone: '+250 788 123 456',
      type: CustomerType.individual,
      nationalId: '1198580012345098',
      licenceNumber: 'DL-RWA-2015-8839',
      licenceExpiry: DateTime.now().add(const Duration(days: 450)),
      riskLevel: RiskLevel.standard,
      creditLimit: 500000.0,
      outstandingBalance: 0.0,
    ),
    TwendeCustomer(
      id: 'cust_02',
      fullName: 'Aline Umutoni',
      email: 'a.umutoni@safariadventures.rw',
      phone: '+250 788 654 321',
      type: CustomerType.corporate,
      companyName: 'Akagera Safari Expeditions Ltd',
      nationalId: '1199080034567112',
      licenceNumber: 'DL-RWA-2018-4421',
      licenceExpiry: DateTime.now().add(const Duration(days: 180)),
      riskLevel: RiskLevel.standard,
      creditLimit: 3000000.0,
      outstandingBalance: 450000.0,
    ),
    TwendeCustomer(
      id: 'cust_03',
      fullName: 'David Karenzi',
      email: 'karenzi.d@unicef-partner.org',
      phone: '+250 788 999 888',
      type: CustomerType.ngo,
      companyName: 'Global Health Relief Rwanda',
      nationalId: '1198280056789045',
      licenceNumber: 'DL-RWA-2012-1029',
      licenceExpiry: DateTime.now().add(const Duration(days: 720)),
      riskLevel: RiskLevel.standard,
      creditLimit: 5000000.0,
      outstandingBalance: 0.0,
    ),
  ];

  @override
  Future<PaginatedResult<TwendeCustomer>> getCustomers({
    String? search,
    CustomerType? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
    var filtered = _customers.where((c) {
      if (type != null && c.type != type) return false;
      if (search != null && search.trim().isNotEmpty) {
        final q = search.toLowerCase();
        final match = c.fullName.toLowerCase().contains(q) ||
            c.phone.contains(q) ||
            (c.companyName?.toLowerCase().contains(q) ?? false);
        if (!match) return false;
      }
      return true;
    }).toList();

    return PaginatedResult(
      items: filtered,
      totalCount: filtered.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<TwendeCustomer?> getCustomerById(String id) async {
    await Future.delayed(const Duration(milliseconds: 80));
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TwendeCustomer> createCustomer(TwendeCustomer customer) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _customers.insert(0, customer);
    return customer;
  }
}

/// In-memory Mock Contract Repository
class MockContractRepository implements ContractRepository {
  final List<TwendeContract> _contracts = [
    TwendeContract(
      id: 'cnt_01',
      contractNumber: 'CNT-2026-0042',
      bookingId: 'bk_901',
      customerId: 'cust_02',
      customerName: 'Akagera Safari Expeditions Ltd',
      vehicleId: 'veh_02',
      vehicleName: 'Toyota RAV4 AWD',
      vehiclePlate: 'RAD 118 B',
      pickupDateTime: DateTime.now().subtract(const Duration(days: 2)),
      returnDateTime: DateTime.now().add(const Duration(days: 1)),
      status: ContractStatus.active,
      totalAmount: 195000.0,
      depositAmount: 100000.0,
      balanceDue: 95000.0,
      isSigned: true,
      handoverInspectionId: 'insp_ho_01',
    ),
    TwendeContract(
      id: 'cnt_02',
      contractNumber: 'CNT-2026-0039',
      bookingId: 'bk_895',
      customerId: 'cust_01',
      customerName: 'Jean-Paul Mugisha',
      vehicleId: 'veh_01',
      vehicleName: 'Toyota Land Cruiser Prado',
      vehiclePlate: 'RAC 452 K',
      pickupDateTime: DateTime.now().subtract(const Duration(days: 5)),
      returnDateTime: DateTime.now().subtract(const Duration(hours: 3)), // Overdue by 3h!
      status: ContractStatus.active,
      totalAmount: 600000.0,
      depositAmount: 200000.0,
      balanceDue: 400000.0,
      isSigned: true,
      handoverInspectionId: 'insp_ho_02',
    ),
    TwendeContract(
      id: 'cnt_03',
      contractNumber: 'CNT-2026-0045',
      bookingId: 'bk_912',
      customerId: 'cust_03',
      customerName: 'Global Health Relief Rwanda',
      vehicleId: 'veh_03',
      vehicleName: 'Toyota Hilux Double Cab',
      vehiclePlate: 'RAE 889 L',
      pickupDateTime: DateTime.now().add(const Duration(hours: 4)),
      returnDateTime: DateTime.now().add(const Duration(days: 7)),
      status: ContractStatus.draft,
      totalAmount: 540000.0,
      depositAmount: 150000.0,
      balanceDue: 540000.0,
      isSigned: false,
    ),
  ];

  @override
  Future<PaginatedResult<TwendeContract>> getContracts({
    String? branchId,
    ContractStatus? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 140));
    var filtered = _contracts.where((c) {
      if (status != null && c.status != status) return false;
      return true;
    }).toList();

    return PaginatedResult(
      items: filtered,
      totalCount: filtered.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<TwendeContract> createContract(TwendeContract contract) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _contracts.add(contract);
    return contract;
  }

  @override
  Future<TwendeContract?> getContractById(String id) async {
    await Future.delayed(const Duration(milliseconds: 90));
    try {
      return _contracts.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> submitInspection(TwendeInspection inspection) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _contracts.indexWhere((c) => c.id == inspection.contractId);
    if (idx >= 0) {
      final old = _contracts[idx];
      _contracts[idx] = TwendeContract(
        id: old.id,
        contractNumber: old.contractNumber,
        bookingId: old.bookingId,
        customerId: old.customerId,
        customerName: old.customerName,
        vehicleId: old.vehicleId,
        vehicleName: old.vehicleName,
        vehiclePlate: old.vehiclePlate,
        pickupDateTime: old.pickupDateTime,
        returnDateTime: old.returnDateTime,
        status: inspection.inspectionType == 'return' ? ContractStatus.closed : old.status,
        totalAmount: old.totalAmount,
        depositAmount: old.depositAmount,
        balanceDue: old.balanceDue,
        isSigned: true,
        handoverInspectionId: inspection.inspectionType == 'handover' ? inspection.id : old.handoverInspectionId,
        returnInspectionId: inspection.inspectionType == 'return' ? inspection.id : old.returnInspectionId,
      );
    }
    return true;
  }
}

/// In-memory Mock Billing Repository
class MockBillingRepository implements BillingRepository {
  final List<TwendeInvoice> _invoices = [
    TwendeInvoice(
      id: 'inv_01',
      invoiceNumber: 'INV-2026-0081',
      contractId: 'cnt_01',
      customerName: 'Akagera Safari Expeditions Ltd',
      issueDate: DateTime.now().subtract(const Duration(days: 2)),
      dueDate: DateTime.now().add(const Duration(days: 28)),
      totalAmount: 195000.0,
      paidAmount: 100000.0,
      balanceDue: 95000.0,
      status: FinancialDocStatus.pending,
    ),
    TwendeInvoice(
      id: 'inv_02',
      invoiceNumber: 'INV-2026-0078',
      contractId: 'cnt_02',
      customerName: 'Jean-Paul Mugisha',
      issueDate: DateTime.now().subtract(const Duration(days: 5)),
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      totalAmount: 600000.0,
      paidAmount: 200000.0,
      balanceDue: 400000.0,
      status: FinancialDocStatus.pending,
    ),
  ];

  @override
  Future<PaginatedResult<TwendeInvoice>> getInvoices({
    FinancialDocStatus? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
    var filtered = _invoices.where((i) {
      if (status != null && i.status != status) return false;
      return true;
    }).toList();

    return PaginatedResult(
      items: filtered,
      totalCount: filtered.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<bool> recordPayment(String invoiceId, double amount, PaymentMethod method, String reference) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final idx = _invoices.indexWhere((i) => i.id == invoiceId);
    if (idx >= 0) {
      final old = _invoices[idx];
      final newPaid = old.paidAmount + amount;
      final newBal = (old.totalAmount - newPaid).clamp(0.0, double.infinity);
      _invoices[idx] = TwendeInvoice(
        id: old.id,
        invoiceNumber: old.invoiceNumber,
        contractId: old.contractId,
        customerName: old.customerName,
        issueDate: old.issueDate,
        dueDate: old.dueDate,
        totalAmount: old.totalAmount,
        paidAmount: newPaid,
        balanceDue: newBal,
        status: newBal <= 0 ? FinancialDocStatus.confirmed : FinancialDocStatus.pending,
      );
      return true;
    }
    return false;
  }
}

/// In-memory Mock Dashboard Repository
class MockDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardKpis> getKpis({String? branchId}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return const DashboardKpis(
      availableVehicles: 4,
      totalFleet: 7,
      activeRentals: 2,
      pickupsToday: 1,
      returnsToday: 2,
      overdueReturns: 1,
      revenueMtd: 14750000.0,
      currency: 'RWF',
    );
  }
}

/// In-memory Mock Approvals Repository
class MockApprovalRepository implements ApprovalRepository {
  final List<TwendeApproval> _approvals = [
    TwendeApproval(
      id: 'appr_01',
      title: 'Commercial Discount Override',
      type: 'discount',
      requestedBy: 'Eric Kwizera (Rental Agent)',
      amount: 45000.0,
      reason: 'Long-term safari booking discount (25% requested, threshold is 20%)',
      status: ApprovalStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    TwendeApproval(
      id: 'appr_02',
      title: 'Caution / Deposit Refund',
      type: 'refund',
      requestedBy: 'Clarisse Mukamana (Return Inspector)',
      amount: 150000.0,
      reason: 'Clean vehicle return with 0 damages for CNT-2026-0038',
      status: ApprovalStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  @override
  Future<List<TwendeApproval>> getApprovals({ApprovalStatus? status}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (status == null) return _approvals;
    return _approvals.where((a) => a.status == status).toList();
  }

  @override
  Future<bool> processApproval(String id, bool approve, String notes) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final idx = _approvals.indexWhere((a) => a.id == id);
    if (idx >= 0) {
      final old = _approvals[idx];
      _approvals[idx] = TwendeApproval(
        id: old.id,
        title: old.title,
        type: old.type,
        requestedBy: old.requestedBy,
        amount: old.amount,
        reason: old.reason,
        status: approve ? ApprovalStatus.approved : ApprovalStatus.rejected,
        createdAt: old.createdAt,
      );
      return true;
    }
    return false;
  }
}

// -------------------------------------------------------------
// Riverpod Global Repository Providers
// -------------------------------------------------------------

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return MockDashboardRepository();
});

final approvalRepositoryProvider = Provider<ApprovalRepository>((ref) {
  return MockApprovalRepository();
});
