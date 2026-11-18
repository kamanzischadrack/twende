import 'package:flutter_test/flutter_test.dart';
import 'package:twende_flutter/core/store/json_document_store.dart';
import 'package:twende_flutter/shared/domain/enums.dart';
import 'package:twende_flutter/shared/repositories/repository_interfaces.dart';
import 'package:twende_flutter/shared/repositories/store_finance_repositories.dart';

void main() {
  group('StoreContractRepository', () {
    test('activates the contract after a complete handover', () async {
      final repository = StoreContractRepository(
        store: JsonDocumentStore(useInMemory: true),
      );
      final inspection = TwendeInspection(
        id: 'insp_handover_501',
        contractId: 'cnt_01',
        vehicleId: 'veh_02',
        inspectionType: 'handover',
        odometerKm: 42000,
        fuelFraction: 1,
        checklist: const {'body': true},
        damages: const [],
        photoUrls: List.generate(7, (index) => 'photo-$index'),
        signatureData: 'signature-data',
        inspectorName: 'Test Inspector',
        createdAt: DateTime.utc(2026, 11, 14),
      );

      expect(await repository.submitInspection(inspection), isTrue);
      final contract = await repository.getContractById('cnt_01');
      expect(contract?.status, ContractStatus.active);
      expect(contract?.handoverInspectionId, inspection.id);
    });

    test('persists inspection and closes contract on return', () async {
      final store = JsonDocumentStore(useInMemory: true);
      final repository = StoreContractRepository(store: store);
      final inspection = TwendeInspection(
        id: 'insp_return_501',
        contractId: 'cnt_01',
        vehicleId: 'veh_02',
        inspectionType: 'return',
        odometerKm: 42000,
        fuelFraction: 0.75,
        checklist: const {'body': true},
        damages: const [],
        photoUrls: List.generate(7, (index) => 'photo-$index'),
        signatureData: 'signature-data',
        inspectorName: 'Test Inspector',
        createdAt: DateTime.utc(2026, 11, 14),
      );

      expect(await repository.submitInspection(inspection), isTrue);
      final contract = await repository.getContractById('cnt_01');
      expect(contract?.status, ContractStatus.closed);
      expect(contract?.returnInspectionId, inspection.id);
      expect(await store.readDocument('inspections', inspection.id), isNotEmpty);
      expect(await store.readCollection('audit_log'), hasLength(2));
      expect(await store.readCollection('sync_queue'), isEmpty);
    });

    test('rejects invalid inspections and ignores an unknown contract', () async {
      final repository = StoreContractRepository(
        store: JsonDocumentStore(useInMemory: true),
      );
      final inspection = TwendeInspection(
        id: 'insp_invalid',
        contractId: 'missing_contract',
        vehicleId: 'veh_01',
        inspectionType: 'other',
        odometerKm: -1,
        fuelFraction: 2,
        checklist: const {'verified': true},
        damages: const [],
        inspectorName: '',
        createdAt: DateTime.utc(2026, 11, 14),
      );
      await expectLater(
        repository.submitInspection(inspection),
        throwsA(isA<FormatException>()),
      );

      final validButUnlinked = TwendeInspection(
        id: 'insp_unlinked',
        contractId: 'missing_contract',
        vehicleId: 'veh_01',
        inspectionType: 'handover',
        odometerKm: 100,
        fuelFraction: 0.5,
        checklist: const {'verified': true},
        damages: const [],
        photoUrls: List.generate(7, (index) => 'photo-$index'),
        signatureData: 'signature-data',
        inspectorName: 'Test Inspector',
        createdAt: DateTime.utc(2026, 11, 14),
      );
      expect(await repository.submitInspection(validButUnlinked), isFalse);
    });

    test('rejects handover without required photos, signature, and checklist',
        () async {
      final repository = StoreContractRepository(
        store: JsonDocumentStore(useInMemory: true),
      );
      final incomplete = TwendeInspection(
        id: 'insp_incomplete',
        contractId: 'cnt_01',
        vehicleId: 'veh_01',
        inspectionType: 'handover',
        odometerKm: 100,
        fuelFraction: 0.5,
        checklist: const {'tyres': true, 'lights': false},
        damages: const [],
        inspectorName: 'Test Inspector',
        createdAt: DateTime.utc(2026, 11, 14),
      );

      await expectLater(
        repository.submitInspection(incomplete),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('StoreBillingRepository', () {
    test('records payment as an immutable event and derives invoice balance', () async {
      final store = JsonDocumentStore(useInMemory: true);
      final repository = StoreBillingRepository(store: store);

      expect(
        await repository.recordPayment(
          'inv_01',
          95000,
          PaymentMethod.cash,
          'cash-receipt-501',
        ),
        isTrue,
      );
      final invoices = await repository.getInvoices();
      final invoice = invoices.items.firstWhere((item) => item.id == 'inv_01');
      expect(invoice.paidAmount, 195000);
      expect(invoice.balanceDue, 0);
      expect(invoice.status, FinancialDocStatus.confirmed);
      expect(await store.readCollection('payments'), hasLength(1));
      expect(await store.readCollection('audit_log'), hasLength(1));
      expect(await store.readCollection('sync_queue'), isEmpty);
    });

    test('rejects invalid and over-balance payments', () async {
      final repository = StoreBillingRepository(
        store: JsonDocumentStore(useInMemory: true),
      );
      await expectLater(
        repository.recordPayment(
          'inv_01',
          0,
          PaymentMethod.cash,
          'cash-receipt-502',
        ),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        repository.recordPayment(
          'inv_01',
          95001,
          PaymentMethod.cash,
          'cash-receipt-503',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
