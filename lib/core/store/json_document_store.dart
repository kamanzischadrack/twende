import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AuditEntry {
  final String id;
  final String collection;
  final String entityId;
  final String action;
  final String actor;
  final String reason;
  final DateTime occurredAt;
  final Map<String, dynamic> before;
  final Map<String, dynamic> after;
  final Map<String, dynamic> metadata;

  const AuditEntry({
    required this.id,
    required this.collection,
    required this.entityId,
    required this.action,
    required this.actor,
    required this.reason,
    required this.occurredAt,
    required this.before,
    required this.after,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'collection': collection,
        'entityId': entityId,
        'action': action,
        'actor': actor,
        'reason': reason,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        'before': before,
        'after': after,
        'metadata': metadata,
      };

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
        id: json['id'] as String? ?? '',
        collection: json['collection'] as String? ?? '',
        entityId: json['entityId'] as String? ?? '',
        action: json['action'] as String? ?? 'update',
        actor: json['actor'] as String? ?? 'system',
        reason: json['reason'] as String? ?? 'Updated',
        occurredAt: DateTime.tryParse(json['occurredAt'] as String? ?? '')?.toUtc() ??
            DateTime.now().toUtc(),
        before: _asMap(json['before']),
        after: _asMap(json['after']),
        metadata: _asMap(json['metadata']),
      );

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return value.map((key, data) => MapEntry(key.toString(), data));
    }
    return <String, dynamic>{};
  }
}

class SyncQueueEntry {
  final String id;
  final String collection;
  final String entityId;
  final String action;
  final String status;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  const SyncQueueEntry({
    required this.id,
    required this.collection,
    required this.entityId,
    required this.action,
    this.status = 'queued',
    required this.createdAt,
    required this.payload,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'collection': collection,
        'entityId': entityId,
        'action': action,
        'status': status,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'payload': payload,
      };

  factory SyncQueueEntry.fromJson(Map<String, dynamic> json) => SyncQueueEntry(
        id: json['id'] as String? ?? '',
        collection: json['collection'] as String? ?? '',
        entityId: json['entityId'] as String? ?? '',
        action: json['action'] as String? ?? 'update',
        status: json['status'] as String? ?? 'queued',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toUtc() ??
            DateTime.now().toUtc(),
        payload: AuditEntry._asMap(json['payload']),
      );
}

class StoreWriteCommand {
  final String collection;
  final String entityId;
  final String action;
  final String actor;
  final String reason;
  final Map<String, dynamic> before;
  final Map<String, dynamic> after;
  final Map<String, dynamic> metadata;
  final bool enqueueSync;

  const StoreWriteCommand({
    required this.collection,
    required this.entityId,
    this.action = 'update',
    this.actor = 'system',
    this.reason = 'Updated',
    this.before = const {},
    this.after = const {},
    this.metadata = const {},
    this.enqueueSync = true,
  });

  Future<StoreWriteResult> execute(JsonDocumentStore store) async {
    return store.apply(this);
  }
}

class StoreWriteResult {
  final Map<String, dynamic> document;
  final AuditEntry auditEntry;
  final SyncQueueEntry syncQueueEntry;
  final bool didEnqueueSync;

  const StoreWriteResult({
    required this.document,
    required this.auditEntry,
    required this.syncQueueEntry,
    required this.didEnqueueSync,
  });
}

class JsonDocumentStore {
  JsonDocumentStore({bool useInMemory = false, Directory? rootDirectory})
      : _useInMemory = useInMemory,
        _rootDirectory = rootDirectory;

  static final JsonDocumentStore instance = JsonDocumentStore();
  static const int schemaVersion = 1;
  static int _entrySequence = 0;

  final bool _useInMemory;
  Directory? _rootDirectory;
  final Map<String, Map<String, dynamic>> _memory = <String, Map<String, dynamic>>{};
  final StreamController<String> _changes = StreamController<String>.broadcast();
  Future<void> _writeQueue = Future<void>.value();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    if (_useInMemory || kIsWeb) {
      _initialized = true;
      return;
    }

    final Directory storeDir;
    if (_rootDirectory case final providedDirectory?) {
      storeDir = providedDirectory;
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      storeDir = Directory(p.join(appDir.path, 'twende_store'));
    }
    if (!storeDir.existsSync()) {
      await storeDir.create(recursive: true);
    }
    _rootDirectory = storeDir;
    await _hydrateCollectionsFromDisk();
    _initialized = true;
  }

  Future<Map<String, dynamic>> readCollection(String collectionName) async {
    await initialize();
    await _writeQueue;
    final key = collectionName.trim();
    if (key.isEmpty) {
      throw const FormatException('Collection name cannot be empty.');
    }

    if (!_memory.containsKey(key)) {
      _memory[key] = <String, dynamic>{};
    }

    return _copyCollection(_memory[key] ?? <String, dynamic>{});
  }

  Stream<Map<String, dynamic>> watchCollection(String collectionName) async* {
    yield await readCollection(collectionName);
    await for (final changedCollection in _changes.stream) {
      if (changedCollection == collectionName) {
        yield await readCollection(collectionName);
      }
    }
  }

  Future<Map<String, dynamic>> readDocument(String collectionName, String entityId) async {
    final collection = await readCollection(collectionName);
    final item = collection[entityId];
    if (item is Map) {
      return Map<String, dynamic>.from(item);
    }
    return <String, dynamic>{};
  }

  Future<StoreWriteResult> apply(StoreWriteCommand command) {
    return _serializeWrite(() => _apply(command));
  }

  Future<StoreWriteResult> _apply(StoreWriteCommand command) async {
    await initialize();

    final collectionName = command.collection.trim();
    final entityId = command.entityId.trim();
    if (collectionName.isEmpty ||
        entityId.isEmpty ||
        command.action.trim().isEmpty ||
        command.actor.trim().isEmpty ||
        command.reason.trim().isEmpty) {
      throw const FormatException(
        'Store write requires collection, entityId, action, actor, and reason.',
      );
    }

    final before = _normalizeMap(command.before);
    final after = _normalizeMap(command.after);
    final metadata = _normalizeMap(command.metadata);

    final collection = _copyCollection(
      _memory[collectionName] ?? <String, dynamic>{},
    );
    final currentDocument = collection[entityId] is Map
        ? Map<String, dynamic>.from(collection[entityId] as Map)
        : <String, dynamic>{};

    if (after.isEmpty) {
      throw const FormatException('Store write requires a non-empty document.');
    }
    final persistedDocument = after;
    collection[entityId] = persistedDocument;

    final occurredAt = DateTime.now().toUtc();
    final eventId = '${occurredAt.microsecondsSinceEpoch}_${_entrySequence++}';
    final auditEntry = AuditEntry(
      id: 'aud_$eventId',
      collection: collectionName,
      entityId: entityId,
      action: command.action,
      actor: command.actor,
      reason: command.reason,
      occurredAt: occurredAt,
      before: before.isEmpty ? currentDocument : before,
      after: persistedDocument,
      metadata: metadata,
    );

    final syncQueueEntry = SyncQueueEntry(
      id: 'sync_$eventId',
      collection: collectionName,
      entityId: entityId,
      action: command.action,
      createdAt: occurredAt,
      payload: persistedDocument,
    );

    final nextState = <String, Map<String, dynamic>>{
      for (final entry in _memory.entries) entry.key: _copyCollection(entry.value),
    };
    nextState[collectionName] = collection;
    nextState.putIfAbsent('audit_log', () => <String, dynamic>{})[auditEntry.id] =
        auditEntry.toJson();
    if (command.enqueueSync) {
      nextState.putIfAbsent('sync_queue', () => <String, dynamic>{})[
          syncQueueEntry.id] = syncQueueEntry.toJson();
    }

    await _persist(nextState);
    _memory
      ..clear()
      ..addAll(nextState);
    _changes.add(collectionName);
    _changes.add('audit_log');
    if (command.enqueueSync) {
      _changes.add('sync_queue');
    }

    return StoreWriteResult(
      document: _copyDocument(persistedDocument),
      auditEntry: auditEntry,
      syncQueueEntry: syncQueueEntry,
      didEnqueueSync: command.enqueueSync,
    );
  }

  Future<T> _serializeWrite<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _writeQueue = _writeQueue.then((_) async {
      try {
        result.complete(await operation());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  Future<void> _persist(Map<String, Map<String, dynamic>> collections) async {
    if (_useInMemory || kIsWeb || _rootDirectory == null) {
      return;
    }

    final file = File(p.join(_rootDirectory!.path, 'twende_store.json'));
    final temporaryFile = File('${file.path}.tmp');
    final payload = <String, dynamic>{
      'schemaVersion': schemaVersion,
      'collections': collections,
    };
    await temporaryFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    await temporaryFile.rename(file.path);
  }

  Future<void> _hydrateCollectionsFromDisk() async {
    if (_useInMemory || kIsWeb || _rootDirectory == null) {
      return;
    }

    final file = File(p.join(_rootDirectory!.path, 'twende_store.json'));
    if (await file.exists()) {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map ||
          decoded['schemaVersion'] is! int ||
          decoded['collections'] is! Map) {
        throw const FormatException('Invalid Twende document store format.');
      }
      final version = decoded['schemaVersion'] as int;
      if (version != schemaVersion) {
        throw FormatException(
          'Unsupported Twende document store schema version: $version.',
        );
      }
      final collections = decoded['collections'] as Map;
      for (final entry in collections.entries) {
        if (entry.value is! Map) {
          throw FormatException(
            'Invalid collection data in Twende document store: ${entry.key}.',
          );
        }
        _memory[entry.key.toString()] = _copyCollection(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
      return;
    }

    final legacyCollections = _rootDirectory!.listSync().whereType<File>();
    for (final legacyFile in legacyCollections) {
      if (!legacyFile.path.endsWith('.json') ||
          legacyFile.path.endsWith('.tmp') ||
          p.basename(legacyFile.path) == 'twende_store.json') {
        continue;
      }
      final decoded = jsonDecode(await legacyFile.readAsString());
      if (decoded is Map) {
        final name = p.basenameWithoutExtension(legacyFile.path);
        _memory[name] = _copyCollection(Map<String, dynamic>.from(decoded));
      }
    }
    if (_memory.isNotEmpty) {
      await _persist(_memory);
    }
  }

  static Map<String, dynamic> _copyCollection(Map<String, dynamic> input) =>
      input.map((key, value) {
        if (value is Map) {
          return MapEntry(key, Map<String, dynamic>.from(value));
        }
        return MapEntry(key, value);
      });

  static Map<String, dynamic> _copyDocument(Map<String, dynamic> document) =>
      Map<String, dynamic>.from(document);

  static Map<String, dynamic> _normalizeMap(Map<String, dynamic> input) {
    if (input.isEmpty) {
      return <String, dynamic>{};
    }
    return input.map(
      (key, value) => MapEntry(
        key,
        value is Map ? Map<String, dynamic>.from(value) : value,
      ),
    );
  }
}
