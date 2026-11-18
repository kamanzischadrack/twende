// lib/app.dart
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'router.dart';

/// Twende — Fleet Management App
/// UI/UX design language and color theme preserved from Twende baseline.
class TwendeApp extends ConsumerWidget {
  const TwendeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Twende',
      theme: AppTheme.light, // frozen — do not change
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
    );
  }
}

// Keep alias so any stale import still compiles
typedef BookCarsApp = TwendeApp;
