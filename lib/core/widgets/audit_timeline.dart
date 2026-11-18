import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class AuditEventItem {
  final DateTime timestamp;
  final String title;
  final String actor;
  final String? details;
  final IconData icon;
  final Color? color;

  const AuditEventItem({
    required this.timestamp,
    required this.title,
    required this.actor,
    this.details,
    this.icon = Icons.circle,
    this.color,
  });
}

class AuditTimelineWidget extends StatelessWidget {
  final List<AuditEventItem> events;
  final String title;

  const AuditTimelineWidget({
    super.key,
    required this.events,
    this.title = 'Audit & Lifecycle History',
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 20, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (ctx, idx) {
              final item = events[idx];
              final isLast = idx == events.length - 1;
              final dotColor = item.color ?? AppColors.primary;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline line and icon
                    SizedBox(
                      width: 32,
                      child: Column(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: dotColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item.icon, size: 12, color: Colors.black),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: Colors.grey.shade300,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                                Text(
                                  dateFormat.format(item.timestamp),
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'By: ${item.actor}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                            ),
                            if (item.details != null && item.details!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.details!,
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
