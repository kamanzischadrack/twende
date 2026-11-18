import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:twende_flutter/core/store/json_document_store.dart';

void main() {
  group('JsonDocumentStore', () {
    test('stores a document and appends audit + sync entries', () async {
      final store = JsonDocumentStore(useInMemory: true);
      await store.initialize();

      final result = await store.apply(
        const StoreWriteCommand(
          collection: 'fleet',
          entityId: 'veh_101',
          action: 'create',
          actor: 'ops@twende',
          reason: 'Add demo fleet record',
          before: {},
          after: {
            'id': 'veh_101',
            'status': 'available',
            'branchId': 'branch-kigali-main',
            'dailyRate': 120000,
          },
        ),
      );

      expect(result.document['status'], 'available');
      expect(result.auditEntry.collection, 'fleet');
      expect(result.syncQueueEntry.action, 'create');

      final auditCollection = await store.readCollection('audit_log');
      expect(auditCollection.length, 1);

      final syncCollection = await store.readCollection('sync_queue');
      expect(syncCollection.length, 1);
    });

    test('readDocument returns the stored document', () async {
      final store = JsonDocumentStore(useInMemory: true);
      await store.initialize();

      await store.apply(
        const StoreWriteCommand(
          collection: 'booking',
          entityId: 'bk_201',
          action: 'update',
          actor: 'ops@twende',
          reason: 'Reserve car for customer',
          before: {'status': 'inquiry'},
          after: {
            'id': 'bk_201',
            'status': 'confirmed',
            'customerId': 'cst_202',
          },
        ),
      );

      final document = await store.readDocument('booking', 'bk_201');
      expect(document['status'], 'confirmed');
      expect(document['customerId'], 'cst_202');
    });

    test('persists a versioned database and reloads it', () async {
      final directory = await Directory.systemTemp.createTemp('twende-store-');
      addTearDown(() => directory.delete(recursive: true));

      final store = JsonDocumentStore(rootDirectory: directory);
      await store.apply(
        const StoreWriteCommand(
          collection: 'fleet',
          entityId: 'veh_303',
          action: 'create',
          actor: 'ops@twende',
          reason: 'Create test vehicle',
          after: {'id': 'veh_303', 'status': 'available'},
        ),
      );
      await store.apply(
        const StoreWriteCommand(
          collection: 'fleet',
          entityId: 'veh_303',
          action: 'update',
          actor: 'ops@twende',
          reason: 'Update test vehicle status',
          before: {'id': 'veh_303', 'status': 'available'},
          after: {'id': 'veh_303', 'status': 'reserved'},
        ),
      );

      final file = File('${directory.path}\\twende_store.json');
      final persisted = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(persisted['schemaVersion'], JsonDocumentStore.schemaVersion);
      expect(persisted['collections'], contains('fleet'));

      final reloadedStore = JsonDocumentStore(rootDirectory: directory);
      final document = await reloadedStore.readDocument('fleet', 'veh_303');
      expect(document['status'], 'reserved');
      expect((await reloadedStore.readCollection('audit_log')).length, 2);
      expect((await reloadedStore.readCollection('sync_queue')).length, 2);
    });

    test('rejects unsupported database schema versions', () async {
      final directory = await Directory.systemTemp.createTemp('twende-store-');
      addTearDown(() => directory.delete(recursive: true));
      await File('${directory.path}\\twende_store.json').writeAsString(
        jsonEncode({
          'schemaVersion': JsonDocumentStore.schemaVersion + 1,
          'collections': <String, dynamic>{},
        }),
      );

      final store = JsonDocumentStore(rootDirectory: directory);
      await expectLater(
        store.initialize(),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects incomplete write commands without changing data', () async {
      final store = JsonDocumentStore(useInMemory: true);
      await expectLater(
        store.apply(
          const StoreWriteCommand(
            collection: 'fleet',
            entityId: 'veh_404',
            after: {'id': 'veh_404'},
            reason: '',
          ),
        ),
        throwsA(isA<FormatException>()),
      );

      expect(await store.readDocument('fleet', 'veh_404'), isEmpty);
      expect(await store.readCollection('audit_log'), isEmpty);
      expect(await store.readCollection('sync_queue'), isEmpty);
    });
  });
}
