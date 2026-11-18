import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/constants/app_strings.dart';
import 'core/network/dio_client.dart';
import 'core/store/json_document_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DioClient.instance.initialize();
  await AppStrings.init();
  await JsonDocumentStore.instance.initialize();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const ProviderScope(
        child: TwendeApp(),
      ),
    ),
  );
}
