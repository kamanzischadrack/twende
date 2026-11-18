// lib/shared/repositories/trip_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/store/json_document_store.dart';
import '../../core/store/store_command.dart';
import '../../core/store/store_provider.dart';
import '../domain/enums.dart';
import 'repository_interfaces.dart';

class StoreTripRepository implements TripRepository {
  StoreTripRepository({required this.store});

  final JsonDocumentStore store;
  static const String _collection = 'trips';
  static const String _expensesCollection = 'trip_expenses';
  static const String _incidentsCollection = 'trip_incidents';

  static final Map<String, TwendeTrip> seedTrips = {
    'T-0098': TwendeTrip(
      id: 'T-0098',
      tripNumber: 'T-0098',
      contractId: 'RC-0231',
      driverId: 'driver_1',
      driverName: 'Jean Habimana',
      driverPhone: '+250 788 112 233',
      vehicleId: 'veh_03',
      vehiclePlate: 'RAF 789 T',
      vehicleName: 'Scania R500 Tipper',
      clientName: 'Cimerwa Cement Ltd',
      clientPhone: '+250 788 445 566',
      origin: 'Kigali Depot',
      destination: 'Rusizi Border',
      stops: const ['Muhanga', 'Huye'],
      cargoType: 'Cement Bags (50kg)',
      cargoWeightKg: 18000,
      cargoVolumeM3: 24.0,
      sealNumber: 'RW-SEAL-88902',
      startDateTime: DateTime.now().subtract(const Duration(hours: 3)),
      endDateTime: DateTime.now().add(const Duration(hours: 5)),
      status: TripStatus.inProgress,
      estimatedKm: 240,
      revenueRwf: 1200000,
      fuelCostRwf: 350000,
      tollCostRwf: 45000,
      driverAllowanceRwf: 80000,
      checklistCompleted: true,
      checklistCompletedAt:
          DateTime.now().subtract(const Duration(hours: 3, minutes: 15)),
      notes: 'Fragile dry load. Keep tarpaulin tied securely.',
    ),
    'T-0104': TwendeTrip(
      id: 'T-0104',
      tripNumber: 'T-0104',
      contractId: 'RC-0232',
      driverId: 'driver_1',
      driverName: 'Jean Habimana',
      driverPhone: '+250 788 112 233',
      vehicleId: 'veh_02',
      vehiclePlate: 'RAD 456 C',
      vehicleName: 'Toyota Hilux Double Cab',
      clientName: 'Aline Uwase',
      clientPhone: '+250 788 556 677',
      origin: 'Kigali Serena Hotel',
      destination: 'Rubavu Lake Kivu Resort',
      stops: const ['Nyabugogo', 'Musanze'],
      cargoType: 'VIP Chauffeur & Baggage',
      cargoWeightKg: 450,
      cargoVolumeM3: 3.5,
      sealNumber: 'N/A (Chauffeur)',
      startDateTime: DateTime.now().add(const Duration(hours: 2)),
      endDateTime: DateTime.now().add(const Duration(hours: 8)),
      status: TripStatus.planned,
      estimatedKm: 155,
      revenueRwf: 220000,
      fuelCostRwf: 60000,
      tollCostRwf: 10000,
      driverAllowanceRwf: 35000,
      checklistCompleted: false,
      notes: 'VIP client pickup at 14:00 prompt.',
    ),
    'T-0089': TwendeTrip(
      id: 'T-0089',
      tripNumber: 'T-0089',
      contractId: 'RC-0220',
      driverId: 'driver_2',
      driverName: 'Eric Mugisha',
      driverPhone: '+250 788 998 877',
      vehicleId: 'veh_01',
      vehiclePlate: 'RAC 123 B',
      vehicleName: 'Isuzu Forward 10T',
      clientName: 'Bralirwa Distribution',
      clientPhone: '+250 788 776 655',
      origin: 'Gisenyi Brewery',
      destination: 'Kigali Central Depot',
      stops: const ['Musanze Hub'],
      cargoType: 'Beverage Crates',
      cargoWeightKg: 8500,
      cargoVolumeM3: 16.0,
      sealNumber: 'RW-SEAL-77120',
      startDateTime: DateTime.now().subtract(const Duration(days: 1)),
      endDateTime: DateTime.now().subtract(const Duration(hours: 4)),
      status: TripStatus.delivered,
      estimatedKm: 160,
      revenueRwf: 850000,
      fuelCostRwf: 220000,
      tollCostRwf: 20000,
      driverAllowanceRwf: 50000,
      checklistCompleted: true,
      podRecipientName: 'Emmanuel Nkurunziza',
      podRecipientPhone: '+250 788 998 877',
      podCompletedAt: DateTime.now().subtract(const Duration(hours: 4)),
      notes: 'Delivered in full with zero breakage.',
    ),
  };

  final List<TripExpense> _seedExpenses = [
    TripExpense(
      id: 'exp_01',
      tripId: 'T-0098',
      type: 'Fuel',
      amountRwf: 120000,
      receiptPhotoUrl: 'assets/receipts/fuel_sp.png',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      locationGps: '-1.9536, 30.0605 (SP Nyabugogo)',
      notes: 'Diesel top-up 75 Litres',
      isSynced: true,
    ),
    TripExpense(
      id: 'exp_02',
      tripId: 'T-0098',
      type: 'Toll',
      amountRwf: 15000,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      locationGps: '-2.0784, 29.7562 (Muhanga Toll)',
      notes: 'Heavy commercial toll voucher',
      isSynced: true,
    ),
  ];

  final List<TripIncident> _seedIncidents = [
    TripIncident(
      id: 'inc_01',
      tripId: 'T-0098',
      vehiclePlate: 'RAF 789 T',
      driverName: 'Jean Habimana',
      type: 'Flat Tyre',
      severity: 'Low',
      description: 'Rear inner tyre low pressure; replaced with spare at Muhanga.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      locationGps: '-2.0784, 29.7562',
      status: 'Resolved',
    ),
  ];

  @override
  Future<PaginatedResult<TwendeTrip>> getTrips({
    TripStatus? status,
    String? driverId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final docs = await store.readCollection(_collection);
    final allTrips = Map<String, TwendeTrip>.from(seedTrips);

    for (final entry in docs.entries) {
      if (entry.value is Map) {
        allTrips[entry.key] = _tripFromJson(entry.key, Map<String, dynamic>.from(entry.value as Map));
      }
    }

    final query = (search ?? '').trim().toLowerCase();
    final filtered = allTrips.values.where((trip) {
      if (status != null && trip.status != status) return false;
      if (driverId != null && trip.driverId != driverId) return false;
      if (query.isNotEmpty) {
        final matches = trip.tripNumber.toLowerCase().contains(query) ||
            trip.vehiclePlate.toLowerCase().contains(query) ||
            trip.driverName.toLowerCase().contains(query) ||
            trip.origin.toLowerCase().contains(query) ||
            trip.destination.toLowerCase().contains(query) ||
            trip.clientName.toLowerCase().contains(query);
        if (!matches) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));

    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, filtered.length);
    final paged = start >= filtered.length ? <TwendeTrip>[] : filtered.sublist(start, end);

    return PaginatedResult(
      items: paged,
      totalCount: filtered.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<TwendeTrip?> getTripById(String id) async {
    final doc = await store.readDocument(_collection, id);
    if (doc.isNotEmpty) {
      return _tripFromJson(id, doc);
    }
    return seedTrips[id];
  }

  @override
  Future<TwendeTrip> createTrip(TwendeTrip trip) async {
    await store.apply(
      StoreWriteCommand(
        collection: _collection,
        entityId: trip.id,
        action: 'create_trip',
        actor: 'staff',
        reason: 'Create logistics trip ${trip.tripNumber}',
        after: _tripToJson(trip),
      ),
    );
    return trip;
  }

  @override
  Future<TwendeTrip> updateTrip(TwendeTrip trip) async {
    await store.apply(
      StoreWriteCommand(
        collection: _collection,
        entityId: trip.id,
        action: 'update_trip',
        actor: 'driver',
        reason: 'Update trip state ${trip.tripNumber}',
        after: _tripToJson(trip),
      ),
    );
    return trip;
  }

  @override
  Future<void> submitPreTripChecklist(
    String tripId, {
    required String sealNumber,
    required List<String> photos,
  }) async {
    final existing = await getTripById(tripId);
    if (existing == null) return;

    final updated = existing.copyWith(
      checklistCompleted: true,
      checklistCompletedAt: DateTime.now(),
      sealNumber: sealNumber.isNotEmpty ? sealNumber : existing.sealNumber,
      status: TripStatus.inProgress,
    );
    await updateTrip(updated);
  }

  @override
  Future<void> logExpense(TripExpense expense) async {
    _seedExpenses.add(expense);
    await store.apply(
      StoreWriteCommand(
        collection: _expensesCollection,
        entityId: expense.id,
        action: 'log_expense',
        actor: 'driver',
        reason: 'Trip expense ${expense.type} RWF ${expense.amountRwf}',
        after: {
          'id': expense.id,
          'tripId': expense.tripId,
          'type': expense.type,
          'amountRwf': expense.amountRwf,
          'receiptPhotoUrl': expense.receiptPhotoUrl,
          'timestamp': expense.timestamp.toIso8601String(),
          'locationGps': expense.locationGps,
          'notes': expense.notes,
        },
      ),
    );

    // Update parent trip costs
    final trip = await getTripById(expense.tripId);
    if (trip != null) {
      TwendeTrip updatedTrip;
      if (expense.type.toLowerCase().contains('fuel')) {
        updatedTrip = trip.copyWith(fuelCostRwf: trip.fuelCostRwf + expense.amountRwf);
      } else if (expense.type.toLowerCase().contains('toll')) {
        updatedTrip = trip.copyWith(tollCostRwf: trip.tollCostRwf + expense.amountRwf);
      } else if (expense.type.toLowerCase().contains('allowance')) {
        updatedTrip = trip.copyWith(driverAllowanceRwf: trip.driverAllowanceRwf + expense.amountRwf);
      } else {
        updatedTrip = trip.copyWith(otherExpensesRwf: trip.otherExpensesRwf + expense.amountRwf);
      }
      await updateTrip(updatedTrip);
    }
  }

  @override
  Future<List<TripExpense>> getExpensesForTrip(String tripId) async {
    return _seedExpenses.where((e) => e.tripId == tripId).toList();
  }

  @override
  Future<void> reportIncident(TripIncident incident) async {
    _seedIncidents.add(incident);
    await store.apply(
      StoreWriteCommand(
        collection: _incidentsCollection,
        entityId: incident.id,
        action: 'report_incident',
        actor: 'driver',
        reason: 'Trip incident ${incident.type} for ${incident.vehiclePlate}',
        after: {
          'id': incident.id,
          'tripId': incident.tripId,
          'vehiclePlate': incident.vehiclePlate,
          'driverName': incident.driverName,
          'type': incident.type,
          'severity': incident.severity,
          'description': incident.description,
          'photoUrl': incident.photoUrl,
          'timestamp': incident.timestamp.toIso8601String(),
          'locationGps': incident.locationGps,
          'status': incident.status,
        },
      ),
    );
  }

  @override
  Future<List<TripIncident>> getIncidents({String? tripId}) async {
    if (tripId != null) {
      return _seedIncidents.where((i) => i.tripId == tripId).toList();
    }
    return List.unmodifiable(_seedIncidents);
  }

  @override
  Future<void> submitPod(
    String tripId, {
    required String recipientName,
    required String recipientPhone,
    required String signatureData,
    required List<String> photoUrls,
    String? notes,
  }) async {
    final existing = await getTripById(tripId);
    if (existing == null) return;

    final updated = existing.copyWith(
      status: TripStatus.delivered,
      podRecipientName: recipientName,
      podRecipientPhone: recipientPhone,
      podSignatureData: signatureData,
      podCompletedAt: DateTime.now(),
      deliveryPhotoUrls: photoUrls,
      notes: notes != null && notes.isNotEmpty ? '${existing.notes ?? ""}\nPOD: $notes' : existing.notes,
    );
    await updateTrip(updated);
  }

  TwendeTrip _tripFromJson(String id, Map<String, dynamic> json) {
    return TwendeTrip(
      id: id,
      tripNumber: json['tripNumber'] as String? ?? id,
      contractId: json['contractId'] as String? ?? '',
      driverId: json['driverId'] as String? ?? '',
      driverName: json['driverName'] as String? ?? '',
      driverPhone: json['driverPhone'] as String? ?? '+250 788 112 233',
      vehicleId: json['vehicleId'] as String? ?? '',
      vehiclePlate: json['vehiclePlate'] as String? ?? '',
      vehicleName: json['vehicleName'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      clientPhone: json['clientPhone'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      stops: (json['stops'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      cargoType: json['cargoType'] as String? ?? 'General Cargo',
      cargoWeightKg: (json['cargoWeightKg'] as num?)?.toDouble() ?? 0.0,
      cargoVolumeM3: (json['cargoVolumeM3'] as num?)?.toDouble() ?? 0.0,
      sealNumber: json['sealNumber'] as String? ?? '',
      startDateTime: DateTime.tryParse(json['startDateTime'] as String? ?? '') ?? DateTime.now(),
      endDateTime: DateTime.tryParse(json['endDateTime'] as String? ?? '') ?? DateTime.now(),
      status: TripStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TripStatus.planned,
      ),
      estimatedKm: (json['estimatedKm'] as num?)?.toInt() ?? 0,
      revenueRwf: (json['revenueRwf'] as num?)?.toDouble() ?? 0.0,
      fuelCostRwf: (json['fuelCostRwf'] as num?)?.toDouble() ?? 0.0,
      tollCostRwf: (json['tollCostRwf'] as num?)?.toDouble() ?? 0.0,
      driverAllowanceRwf: (json['driverAllowanceRwf'] as num?)?.toDouble() ?? 0.0,
      otherExpensesRwf: (json['otherExpensesRwf'] as num?)?.toDouble() ?? 0.0,
      checklistCompleted: json['checklistCompleted'] as bool? ?? false,
      checklistCompletedAt: DateTime.tryParse(json['checklistCompletedAt'] as String? ?? ''),
      podRecipientName: json['podRecipientName'] as String?,
      podRecipientPhone: json['podRecipientPhone'] as String?,
      podSignatureData: json['podSignatureData'] as String?,
      podCompletedAt: DateTime.tryParse(json['podCompletedAt'] as String? ?? ''),
      deliveryPhotoUrls: (json['deliveryPhotoUrls'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> _tripToJson(TwendeTrip trip) => {
        'id': trip.id,
        'tripNumber': trip.tripNumber,
        'contractId': trip.contractId,
        'driverId': trip.driverId,
        'driverName': trip.driverName,
        'driverPhone': trip.driverPhone,
        'vehicleId': trip.vehicleId,
        'vehiclePlate': trip.vehiclePlate,
        'vehicleName': trip.vehicleName,
        'clientName': trip.clientName,
        'clientPhone': trip.clientPhone,
        'origin': trip.origin,
        'destination': trip.destination,
        'stops': trip.stops,
        'cargoType': trip.cargoType,
        'cargoWeightKg': trip.cargoWeightKg,
        'cargoVolumeM3': trip.cargoVolumeM3,
        'sealNumber': trip.sealNumber,
        'startDateTime': trip.startDateTime.toIso8601String(),
        'endDateTime': trip.endDateTime.toIso8601String(),
        'status': trip.status.name,
        'estimatedKm': trip.estimatedKm,
        'revenueRwf': trip.revenueRwf,
        'fuelCostRwf': trip.fuelCostRwf,
        'tollCostRwf': trip.tollCostRwf,
        'driverAllowanceRwf': trip.driverAllowanceRwf,
        'otherExpensesRwf': trip.otherExpensesRwf,
        'checklistCompleted': trip.checklistCompleted,
        'checklistCompletedAt': trip.checklistCompletedAt?.toIso8601String(),
        'podRecipientName': trip.podRecipientName,
        'podRecipientPhone': trip.podRecipientPhone,
        'podSignatureData': trip.podSignatureData,
        'podCompletedAt': trip.podCompletedAt?.toIso8601String(),
        'deliveryPhotoUrls': trip.deliveryPhotoUrls,
        'notes': trip.notes,
      };
}

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final store = ref.watch(jsonDocumentStoreProvider);
  return StoreTripRepository(store: store);
});
