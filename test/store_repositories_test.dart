import 'package:flutter_test/flutter_test.dart';
import 'package:twende_flutter/core/store/json_document_store.dart';
import 'package:twende_flutter/shared/domain/enums.dart';
import 'package:twende_flutter/shared/repositories/mock_repositories.dart';
import 'package:twende_flutter/shared/repositories/repository_interfaces.dart';
import 'package:twende_flutter/shared/repositories/store_repositories.dart';

void main() {
  group('StoreFleetRepository', () {
    test('persists status changes and keeps demo changes out of sync queue', () async {
      final store = JsonDocumentStore(useInMemory: true);
      final repository = StoreFleetRepository(store: store);

      expect(await repository.updateVehicleStatus(
        'veh_01',
        VehicleStatus.underInspection,
        'Prepare vehicle inspection',
      ), isTrue);

      final vehicle = await repository.getVehicleById('veh_01');
      expect(vehicle?.status, VehicleStatus.underInspection);
      expect(await store.readCollection('audit_log'), hasLength(1));
      expect(await store.readCollection('sync_queue'), isEmpty);

      final result = await repository.getVehicles(
        status: VehicleStatus.underInspection,
      );
      expect(result.items.map((item) => item.id), contains('veh_01'));
    });

    test('rejects status changes without a reason', () async {
      final repository = StoreFleetRepository(
        store: JsonDocumentStore(useInMemory: true),
      );
      await expectLater(
        repository.updateVehicleStatus('veh_01', VehicleStatus.rented, ' '),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('StoreCustomerRepository', () {
    test('persists a new customer with audit and sync records', () async {
      final store = JsonDocumentStore(useInMemory: true);
      final repository = StoreCustomerRepository(store: store);
      const customer = TwendeCustomer(
        id: 'cst_501',
        fullName: 'Sample Customer',
        email: 'sample@example.test',
        phone: '+250700000501',
        type: CustomerType.individual,
      );

      final created = await repository.createCustomer(customer);
      expect(created.id, customer.id);
      expect((await repository.getCustomerById(customer.id))?.email, customer.email);
      expect(await store.readCollection('audit_log'), hasLength(1));
      expect(await store.readCollection('sync_queue'), hasLength(1));
    });

    test('rejects duplicate email and invalid customer data', () async {
      final repository = StoreCustomerRepository(
        store: JsonDocumentStore(useInMemory: true),
        demoFallback: MockCustomerRepository(),
      );
      const duplicate = TwendeCustomer(
        id: 'cst_duplicate',
        fullName: 'Duplicate Record',
        email: 'jp.mugisha@gmail.com',
        phone: '+250700000502',
        type: CustomerType.individual,
      );
      await expectLater(
        repository.createCustomer(duplicate),
        throwsA(isA<FormatException>()),
      );

      const invalid = TwendeCustomer(
        id: 'cst_invalid',
        fullName: 'Invalid Record',
        email: 'not-an-email',
        phone: '+250700000503',
        type: CustomerType.individual,
      );
      await expectLater(
        repository.createCustomer(invalid),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
