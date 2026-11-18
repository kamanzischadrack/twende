import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/store/json_document_store.dart';
import '../../core/store/store_provider.dart';
import '../domain/enums.dart';
import 'mock_repositories.dart';
import 'repository_interfaces.dart';

class StoreFleetRepository implements FleetRepository {
  StoreFleetRepository({
    required this.store,
    FleetRepository? demoFallback,
  }) : _demoFallback = demoFallback ?? MockFleetRepository();

  final JsonDocumentStore store;
  final FleetRepository _demoFallback;
  static const String _collection = 'fleet';

  @override
  Future<PaginatedResult<TwendeVehicle>> getVehicles({
    String? branchId,
    VehicleStatus? status,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    _validatePage(page, pageSize);
    final demoResult = await _demoFallback.getVehicles(pageSize: 10000);
    final documents = await store.readCollection(_collection);
    final vehicles = <String, TwendeVehicle>{
      for (final vehicle in demoResult.items) vehicle.id: vehicle,
    };
    for (final entry in documents.entries) {
      vehicles[entry.key] = _vehicleFromJson(_asMap(entry.value));
    }

    final query = search?.trim().toLowerCase() ?? '';
    final filtered = vehicles.values.where((vehicle) {
      if (branchId != null && branchId.isNotEmpty && vehicle.branchId != branchId) {
        return false;
      }
      if (status != null && vehicle.status != status) {
        return false;
      }
      if (query.isNotEmpty &&
          !vehicle.name.toLowerCase().contains(query) &&
          !vehicle.plateNumber.toLowerCase().contains(query) &&
          !vehicle.category.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((first, second) => first.id.compareTo(second.id));

    return _paginate(filtered, page, pageSize);
  }

  @override
  Future<TwendeVehicle?> getVehicleById(String id) async {
    final document = await store.readDocument(_collection, id);
    if (document.isNotEmpty) {
      return _vehicleFromJson(document);
    }
    return _demoFallback.getVehicleById(id);
  }

  @override
  Future<bool> updateVehicleStatus(
    String id,
    VehicleStatus newStatus,
    String reason,
  ) async {
    if (reason.trim().isEmpty) {
      throw const FormatException('A reason is required to change vehicle status.');
    }
    final storedDocument = await store.readDocument(_collection, id);
    final vehicle = storedDocument.isNotEmpty
        ? _vehicleFromJson(storedDocument)
        : await _demoFallback.getVehicleById(id);
    if (vehicle == null) {
      return false;
    }

    final before = _vehicleToJson(vehicle);
    final isDemoRecord =
        storedDocument['_demoData'] == true || storedDocument.isEmpty;
    final after = <String, dynamic>{
      ...before,
      'status': newStatus.name,
      if (isDemoRecord) '_demoData': true,
    };
    await store.apply(
      StoreWriteCommand(
        collection: _collection,
        entityId: id,
        action: 'status_change',
        actor: 'current-user',
        reason: reason.trim(),
        before: before,
        after: after,
        metadata: {'source': isDemoRecord ? 'demo' : 'local'},
        enqueueSync: !isDemoRecord,
      ),
    );
    return true;
  }
}

class StoreCustomerRepository implements CustomerRepository {
  StoreCustomerRepository({
    required this.store,
    CustomerRepository? demoFallback,
  }) : _demoFallback = demoFallback ?? MockCustomerRepository();

  final JsonDocumentStore store;
  final CustomerRepository _demoFallback;
  static const String _collection = 'customers';

  @override
  Future<PaginatedResult<TwendeCustomer>> getCustomers({
    String? search,
    CustomerType? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    _validatePage(page, pageSize);
    final demoResult = await _demoFallback.getCustomers(pageSize: 10000);
    final documents = await store.readCollection(_collection);
    final customers = <String, TwendeCustomer>{
      for (final customer in demoResult.items) customer.id: customer,
    };
    for (final entry in documents.entries) {
      customers[entry.key] = _customerFromJson(_asMap(entry.value));
    }

    final query = search?.trim().toLowerCase() ?? '';
    final filtered = customers.values.where((customer) {
      if (type != null && customer.type != type) {
        return false;
      }
      if (query.isNotEmpty &&
          !customer.fullName.toLowerCase().contains(query) &&
          !customer.phone.toLowerCase().contains(query) &&
          !(customer.companyName?.toLowerCase().contains(query) ?? false) &&
          !customer.email.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((first, second) => first.id.compareTo(second.id));

    return _paginate(filtered, page, pageSize);
  }

  @override
  Future<TwendeCustomer?> getCustomerById(String id) async {
    final document = await store.readDocument(_collection, id);
    if (document.isNotEmpty) {
      return _customerFromJson(document);
    }
    return _demoFallback.getCustomerById(id);
  }

  @override
  Future<TwendeCustomer> createCustomer(TwendeCustomer customer) async {
    _validateCustomer(customer);
    final allCustomers = await getCustomers(pageSize: 10000);
    final normalizedEmail = customer.email.trim().toLowerCase();
    final normalizedPhone = customer.phone.trim();
    final duplicate = allCustomers.items.any((existing) =>
        existing.email.trim().toLowerCase() == normalizedEmail ||
        existing.phone.trim() == normalizedPhone);
    if (duplicate) {
      throw const FormatException('A customer with this email or phone already exists.');
    }

    final document = _customerToJson(customer);
    await store.apply(
      StoreWriteCommand(
        collection: _collection,
        entityId: customer.id,
        action: 'create',
        actor: 'current-user',
        reason: 'Create customer record',
        after: document,
      ),
    );
    return customer;
  }
}

final fleetRepositoryProvider = Provider<FleetRepository>((ref) {
  return StoreFleetRepository(store: ref.watch(jsonDocumentStoreProvider));
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return StoreCustomerRepository(store: ref.watch(jsonDocumentStoreProvider));
});

void _validatePage(int page, int pageSize) {
  if (page < 1 || pageSize < 1) {
    throw const FormatException('Page and page size must be greater than zero.');
  }
}

PaginatedResult<T> _paginate<T>(List<T> items, int page, int pageSize) {
  final startIndex = (page - 1) * pageSize;
  final endIndex = (startIndex + pageSize).clamp(0, items.length);
  return PaginatedResult<T>(
    items: startIndex >= items.length ? <T>[] : items.sublist(startIndex, endIndex),
    totalCount: items.length,
    page: page,
    pageSize: pageSize,
  );
}

TwendeVehicle _vehicleFromJson(Map<String, dynamic> json) => TwendeVehicle(
      id: _stringValue(json, 'id'),
      name: _stringValue(json, 'name'),
      make: _stringValue(json, 'make'),
      model: _stringValue(json, 'model'),
      year: _intValue(json, 'year'),
      plateNumber: _stringValue(json, 'plateNumber'),
      category: _stringValue(json, 'category'),
      status: VehicleStatusX.fromString(_stringValue(json, 'status')),
      fuelType: _stringValue(json, 'fuelType'),
      mileage: _intValue(json, 'mileage'),
      branchId: _stringValue(json, 'branchId'),
      branchName: _stringValue(json, 'branchName'),
      dailyRate: _doubleValue(json, 'dailyRate'),
      imageUrl: json['imageUrl'] as String?,
      equipment: (json['equipment'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );

Map<String, dynamic> _vehicleToJson(TwendeVehicle vehicle) => {
      'id': vehicle.id,
      'name': vehicle.name,
      'make': vehicle.make,
      'model': vehicle.model,
      'year': vehicle.year,
      'plateNumber': vehicle.plateNumber,
      'category': vehicle.category,
      'status': vehicle.status.name,
      'fuelType': vehicle.fuelType,
      'mileage': vehicle.mileage,
      'branchId': vehicle.branchId,
      'branchName': vehicle.branchName,
      'dailyRate': vehicle.dailyRate,
      'imageUrl': vehicle.imageUrl,
      'equipment': vehicle.equipment,
    };

TwendeCustomer _customerFromJson(Map<String, dynamic> json) => TwendeCustomer(
      id: _stringValue(json, 'id'),
      fullName: _stringValue(json, 'fullName'),
      email: _stringValue(json, 'email'),
      phone: _stringValue(json, 'phone'),
      type: CustomerType.values.firstWhere(
        (type) => type.name == _stringValue(json, 'type'),
        orElse: () => CustomerType.individual,
      ),
      companyName: json['companyName'] as String?,
      nationalId: json['nationalId'] as String?,
      licenceNumber: json['licenceNumber'] as String?,
      licenceExpiry: DateTime.tryParse(json['licenceExpiry'] as String? ?? ''),
      riskLevel: RiskLevel.values.firstWhere(
        (risk) => risk.name == _stringValue(json, 'riskLevel'),
        orElse: () => RiskLevel.standard,
      ),
      creditLimit: _doubleValue(json, 'creditLimit'),
      outstandingBalance: _doubleValue(json, 'outstandingBalance'),
    );

Map<String, dynamic> _customerToJson(TwendeCustomer customer) => {
      'id': customer.id,
      'fullName': customer.fullName,
      'email': customer.email,
      'phone': customer.phone,
      'type': customer.type.name,
      'companyName': customer.companyName,
      'nationalId': customer.nationalId,
      'licenceNumber': customer.licenceNumber,
      'licenceExpiry': customer.licenceExpiry?.toUtc().toIso8601String(),
      'riskLevel': customer.riskLevel.name,
      'creditLimit': customer.creditLimit,
      'outstandingBalance': customer.outstandingBalance,
    };

void _validateCustomer(TwendeCustomer customer) {
  if (customer.id.trim().isEmpty ||
      customer.fullName.trim().isEmpty ||
      customer.email.trim().isEmpty ||
      customer.phone.trim().isEmpty) {
    throw const FormatException('Customer ID, name, email, and phone are required.');
  }
  if (!customer.email.contains('@')) {
    throw const FormatException('Customer email address is invalid.');
  }
  if (customer.creditLimit < 0 || customer.outstandingBalance < 0) {
    throw const FormatException('Customer balances cannot be negative.');
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is! Map) {
    throw const FormatException('Stored record must be a JSON object.');
  }
  return value.map((key, data) => MapEntry(key.toString(), data));
}

String _stringValue(Map<String, dynamic> json, String key) =>
    json[key] as String? ?? '';

int _intValue(Map<String, dynamic> json, String key) =>
    (json[key] as num?)?.toInt() ?? 0;

double _doubleValue(Map<String, dynamic> json, String key) =>
    (json[key] as num?)?.toDouble() ?? 0;
