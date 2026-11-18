import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/store/json_document_store.dart';
import '../../core/store/store_provider.dart';
import '../domain/enums.dart';
import 'mock_repositories.dart';
import 'repository_interfaces.dart';

class StoreContractRepository implements ContractRepository {
  StoreContractRepository({
    required this.store,
    ContractRepository? demoFallback,
  }) : _demoFallback = demoFallback ?? MockContractRepository();

  final JsonDocumentStore store;
  final ContractRepository _demoFallback;
  static const String _collection = 'contracts';
  static const String _inspectionsCollection = 'inspections';

  @override
  Future<PaginatedResult<TwendeContract>> getContracts({
    String? branchId,
    ContractStatus? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    _validatePage(page, pageSize);
    final demo = await _demoFallback.getContracts(pageSize: 10000);
    final stored = await store.readCollection(_collection);
    final records = <String, TwendeContract>{
      for (final contract in demo.items) contract.id: contract,
    };
    for (final entry in stored.entries) {
      records[entry.key] = _contractFromJson(_asMap(entry.value));
    }

    final filtered = records.values
        .where((contract) => status == null || contract.status == status)
        .toList()
      ..sort((first, second) => first.id.compareTo(second.id));
    return _paginate(filtered, page, pageSize);
  }

  @override
  Future<TwendeContract?> getContractById(String id) async {
    final stored = await store.readDocument(_collection, id);
    if (stored.isNotEmpty) {
      return _contractFromJson(stored);
    }
    return _demoFallback.getContractById(id);
  }

  @override
  Future<TwendeContract> createContract(TwendeContract contract) async {
    await store.apply(
      StoreWriteCommand(
        collection: _collection,
        entityId: contract.id,
        action: 'create_contract',
        actor: 'system',
        reason: 'Customer portal reservation',
        after: _contractToJson(contract),
      ),
    );
    return contract;
  }

  @override
  Future<bool> submitInspection(TwendeInspection inspection) async {
    _validateInspection(inspection);
    final contract = await getContractById(inspection.contractId);
    if (contract == null) {
      return false;
    }

    final existing = await store.readDocument(_collection, contract.id);
    final isDemo = existing.isEmpty || existing['_demoData'] == true;
    final before = _contractToJson(contract);
    final after = <String, dynamic>{
      ...before,
      'status': inspection.inspectionType == 'return'
          ? ContractStatus.closed.name
          : ContractStatus.active.name,
      'isSigned': true,
      'handoverInspectionId': inspection.inspectionType == 'handover'
          ? inspection.id
          : contract.handoverInspectionId,
      'returnInspectionId': inspection.inspectionType == 'return'
          ? inspection.id
          : contract.returnInspectionId,
      if (isDemo) '_demoData': true,
    };

    await store.apply(
      StoreWriteCommand(
        collection: _inspectionsCollection,
        entityId: inspection.id,
        action: 'create',
        actor: 'current-user',
        reason: '${inspection.inspectionType} inspection submitted',
        after: _inspectionToJson(inspection),
        metadata: {'source': isDemo ? 'demo' : 'local'},
        enqueueSync: !isDemo,
      ),
    );
    await store.apply(
      StoreWriteCommand(
        collection: _collection,
        entityId: contract.id,
        action: inspection.inspectionType == 'return'
            ? 'return_inspection'
            : 'handover_inspection',
        actor: 'current-user',
        reason: '${inspection.inspectionType} inspection submitted',
        before: before,
        after: after,
        metadata: {'inspectionId': inspection.id, 'source': isDemo ? 'demo' : 'local'},
        enqueueSync: !isDemo,
      ),
    );
    return true;
  }
}

class StoreBillingRepository implements BillingRepository {
  StoreBillingRepository({
    required this.store,
    BillingRepository? demoFallback,
  }) : _demoFallback = demoFallback ?? MockBillingRepository();

  final JsonDocumentStore store;
  final BillingRepository _demoFallback;
  static const String _invoicesCollection = 'invoices';
  static const String _paymentsCollection = 'payments';

  @override
  Future<PaginatedResult<TwendeInvoice>> getInvoices({
    FinancialDocStatus? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    _validatePage(page, pageSize);
    final demo = await _demoFallback.getInvoices(pageSize: 10000);
    final stored = await store.readCollection(_invoicesCollection);
    final records = <String, TwendeInvoice>{
      for (final invoice in demo.items) invoice.id: invoice,
    };
    for (final entry in stored.entries) {
      records[entry.key] = _invoiceFromJson(_asMap(entry.value));
    }

    final payments = await store.readCollection(_paymentsCollection);
    final invoices = records.values.map((invoice) {
      final additionalPaid = payments.values
          .map(_asMap)
          .where((payment) => payment['invoiceId'] == invoice.id)
          .fold<double>(
            0,
            (total, payment) => total + _doubleValue(payment, 'amount'),
          );
      final paid = invoice.paidAmount + additionalPaid;
      final balance = (invoice.totalAmount - paid).clamp(0.0, double.infinity);
      return _copyInvoice(
        invoice,
        paidAmount: paid,
        balanceDue: balance,
        status: balance == 0
            ? FinancialDocStatus.confirmed
            : invoice.status,
      );
    }).where((invoice) => status == null || invoice.status == status).toList()
      ..sort((first, second) => first.id.compareTo(second.id));

    return _paginate(invoices, page, pageSize);
  }

  @override
  Future<bool> recordPayment(
    String invoiceId,
    double amount,
    PaymentMethod method,
    String reference,
  ) async {
    if (!amount.isFinite || amount <= 0) {
      throw const FormatException('Payment amount must be greater than zero.');
    }
    if (reference.trim().isEmpty) {
      throw const FormatException('A payment reference is required.');
    }

    final invoice = await _findInvoice(invoiceId);
    if (invoice == null) {
      return false;
    }
    final invoices = await getInvoices();
    final current = invoices.items.firstWhere(
      (item) => item.id == invoiceId,
      orElse: () => invoice,
    );
    if (amount > current.balanceDue) {
      throw const FormatException('Payment cannot exceed the invoice balance due.');
    }

    final isDemo = (await store.readDocument(_invoicesCollection, invoiceId))
            .isEmpty;
    final paymentId = 'pmt_${DateTime.now().microsecondsSinceEpoch}';
    await store.apply(
      StoreWriteCommand(
        collection: _paymentsCollection,
        entityId: paymentId,
        action: 'record_payment',
        actor: 'current-user',
        reason: 'Record invoice payment',
        after: {
          'id': paymentId,
          'invoiceId': invoiceId,
          'amount': amount,
          'method': method.name,
          'reference': reference.trim(),
          'recordedAt': DateTime.now().toUtc().toIso8601String(),
        },
        metadata: {'source': isDemo ? 'demo' : 'local'},
        enqueueSync: !isDemo,
      ),
    );
    return true;
  }

  Future<TwendeInvoice?> _findInvoice(String id) async {
    final stored = await store.readDocument(_invoicesCollection, id);
    if (stored.isNotEmpty) {
      return _invoiceFromJson(stored);
    }
    final result = await _demoFallback.getInvoices(pageSize: 10000);
    for (final invoice in result.items) {
      if (invoice.id == id) {
        return invoice;
      }
    }
    return null;
  }
}

final contractRepositoryProvider = Provider<ContractRepository>((ref) {
  return StoreContractRepository(store: ref.watch(jsonDocumentStoreProvider));
});

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return StoreBillingRepository(store: ref.watch(jsonDocumentStoreProvider));
});

TwendeContract _contractFromJson(Map<String, dynamic> json) => TwendeContract(
      id: _stringValue(json, 'id'),
      contractNumber: _stringValue(json, 'contractNumber'),
      bookingId: json['bookingId'] as String?,
      customerId: _stringValue(json, 'customerId'),
      customerName: _stringValue(json, 'customerName'),
      vehicleId: _stringValue(json, 'vehicleId'),
      vehicleName: _stringValue(json, 'vehicleName'),
      vehiclePlate: _stringValue(json, 'vehiclePlate'),
      pickupDateTime: _dateValue(json, 'pickupDateTime'),
      returnDateTime: _dateValue(json, 'returnDateTime'),
      status: ContractStatus.values.firstWhere(
        (status) => status.name == _stringValue(json, 'status'),
        orElse: () => ContractStatus.draft,
      ),
      totalAmount: _doubleValue(json, 'totalAmount'),
      depositAmount: _doubleValue(json, 'depositAmount'),
      balanceDue: _doubleValue(json, 'balanceDue'),
      isSigned: json['isSigned'] == true,
      handoverInspectionId: json['handoverInspectionId'] as String?,
      returnInspectionId: json['returnInspectionId'] as String?,
    );

Map<String, dynamic> _contractToJson(TwendeContract contract) => {
      'id': contract.id,
      'contractNumber': contract.contractNumber,
      'bookingId': contract.bookingId,
      'customerId': contract.customerId,
      'customerName': contract.customerName,
      'vehicleId': contract.vehicleId,
      'vehicleName': contract.vehicleName,
      'vehiclePlate': contract.vehiclePlate,
      'pickupDateTime': contract.pickupDateTime.toUtc().toIso8601String(),
      'returnDateTime': contract.returnDateTime.toUtc().toIso8601String(),
      'status': contract.status.name,
      'totalAmount': contract.totalAmount,
      'depositAmount': contract.depositAmount,
      'balanceDue': contract.balanceDue,
      'isSigned': contract.isSigned,
      'handoverInspectionId': contract.handoverInspectionId,
      'returnInspectionId': contract.returnInspectionId,
    };

Map<String, dynamic> _inspectionToJson(TwendeInspection inspection) => {
      'id': inspection.id,
      'contractId': inspection.contractId,
      'vehicleId': inspection.vehicleId,
      'inspectionType': inspection.inspectionType,
      'odometerKm': inspection.odometerKm,
      'fuelFraction': inspection.fuelFraction,
      'checklist': inspection.checklist,
      'damages': inspection.damages,
      'photoUrls': inspection.photoUrls,
      'signatureData': inspection.signatureData,
      'inspectorName': inspection.inspectorName,
      'createdAt': inspection.createdAt.toUtc().toIso8601String(),
    };

TwendeInvoice _invoiceFromJson(Map<String, dynamic> json) => TwendeInvoice(
      id: _stringValue(json, 'id'),
      invoiceNumber: _stringValue(json, 'invoiceNumber'),
      contractId: _stringValue(json, 'contractId'),
      customerName: _stringValue(json, 'customerName'),
      issueDate: _dateValue(json, 'issueDate'),
      dueDate: _dateValue(json, 'dueDate'),
      totalAmount: _doubleValue(json, 'totalAmount'),
      paidAmount: _doubleValue(json, 'paidAmount'),
      balanceDue: _doubleValue(json, 'balanceDue'),
      status: FinancialDocStatus.values.firstWhere(
        (status) => status.name == _stringValue(json, 'status'),
        orElse: () => FinancialDocStatus.pending,
      ),
      currency: json['currency'] as String? ?? 'RWF',
    );

TwendeInvoice _copyInvoice(
  TwendeInvoice invoice, {
  required double paidAmount,
  required double balanceDue,
  required FinancialDocStatus status,
}) =>
    TwendeInvoice(
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      contractId: invoice.contractId,
      customerName: invoice.customerName,
      issueDate: invoice.issueDate,
      dueDate: invoice.dueDate,
      totalAmount: invoice.totalAmount,
      paidAmount: paidAmount,
      balanceDue: balanceDue,
      status: status,
      currency: invoice.currency,
    );

void _validateInspection(TwendeInspection inspection) {
  if (inspection.id.trim().isEmpty ||
      inspection.contractId.trim().isEmpty ||
      inspection.vehicleId.trim().isEmpty ||
      inspection.inspectorName.trim().isEmpty) {
    throw const FormatException('Inspection, contract, vehicle, and inspector are required.');
  }
  if (!const {'handover', 'return'}.contains(inspection.inspectionType)) {
    throw const FormatException('Inspection type must be handover or return.');
  }
  if (inspection.odometerKm < 0 ||
      !inspection.fuelFraction.isFinite ||
      inspection.fuelFraction < 0 ||
      inspection.fuelFraction > 1) {
    throw const FormatException('Inspection odometer or fuel reading is invalid.');
  }
  if (inspection.photoUrls.length < 7 ||
      inspection.photoUrls.any((photo) => photo.trim().isEmpty)) {
    throw const FormatException(
      'Inspection requires all seven photos and none may be empty.',
    );
  }
  if (inspection.signatureData?.trim().isNotEmpty != true) {
    throw const FormatException('A customer signature is required.');
  }
  if (inspection.inspectionType == 'handover' &&
      (inspection.checklist.isEmpty ||
          inspection.checklist.values.any((checked) => !checked))) {
    throw const FormatException(
      'Every handover checklist item must be verified before submission.',
    );
  }
}

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

Map<String, dynamic> _asMap(dynamic value) {
  if (value is! Map) {
    throw const FormatException('Stored record must be a JSON object.');
  }
  return value.map((key, data) => MapEntry(key.toString(), data));
}

String _stringValue(Map<String, dynamic> json, String key) =>
    json[key] as String? ?? '';

double _doubleValue(Map<String, dynamic> json, String key) =>
    (json[key] as num?)?.toDouble() ?? 0;

DateTime _dateValue(Map<String, dynamic> json, String key) =>
    DateTime.tryParse(json[key] as String? ?? '')?.toUtc() ??
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
