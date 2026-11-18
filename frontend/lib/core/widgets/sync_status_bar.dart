// lib/core/widgets/sync_status_bar.dart
// Slim offline/syncing banner — invisible when online.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../auth/session_provider.dart';

class SyncStatusBar extends ConsumerWidget {
  final AppSyncStatus? status;
  const SyncStatusBar({super.key, this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveStatus = status ?? ref.watch(syncStatusProvider);
    if (effectiveStatus == AppSyncStatus.online) return const SizedBox.shrink();
    final isOffline = effectiveStatus == AppSyncStatus.offline;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: isOffline ? AppColors.error : AppColors.warning,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOffline ? Icons.wifi_off : Icons.sync,
            color: Colors.black,
            size: 15,
          ),
          const SizedBox(width: 8),
          Text(
            isOffline ? 'Offline — data saved locally' : 'Syncing...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
