import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'json_document_store.dart';

final jsonDocumentStoreProvider = Provider<JsonDocumentStore>((ref) => JsonDocumentStore.instance);

final storeCollectionProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, collection) {
  final store = ref.watch(jsonDocumentStoreProvider);
  return store.watchCollection(collection);
});
