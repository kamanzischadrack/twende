// lib/features/portal/portal_documents_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_badge.dart';

class _CustomerDoc {
  final String title;
  final String refNumber;
  final String category;
  final DateTime date;
  final String size;
  final String status;
  final Color statusColor;

  const _CustomerDoc({
    required this.title,
    required this.refNumber,
    required this.category,
    required this.date,
    required this.size,
    required this.status,
    required this.statusColor,
  });
}

class PortalDocumentsScreen extends ConsumerWidget {
  const PortalDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    final docs = [
      _CustomerDoc(
        title: 'Master Vehicle Rental Agreement',
        refNumber: 'CNT-2026-0042',
        category: 'Rental Contract',
        date: DateTime.now().subtract(const Duration(days: 2)),
        size: '1.4 MB',
        status: 'SIGNED & SEALED',
        statusColor: Colors.green,
      ),
      _CustomerDoc(
        title: 'Rwanda Revenue Authority EBM Tax Invoice',
        refNumber: 'INV-2026-0089',
        category: 'VAT Invoice (18%)',
        date: DateTime.now().subtract(const Duration(days: 2)),
        size: '480 KB',
        status: 'PAID IN FULL',
        statusColor: Colors.teal,
      ),
      _CustomerDoc(
        title: 'Security Caution Deposit Escrow Holding Receipt',
        refNumber: 'DEP-2026-0042',
        category: 'Deposit Certificate',
        date: DateTime.now().subtract(const Duration(days: 2)),
        size: '320 KB',
        status: 'ESCROW ACTIVE',
        statusColor: AppColors.primary,
      ),
      _CustomerDoc(
        title: 'Digital Vehicle Handover 360° Inspection Report',
        refNumber: 'INSP-HO-2026-0012',
        category: 'Inspection Report',
        date: DateTime.now().subtract(const Duration(days: 1)),
        size: '3.8 MB',
        status: 'VERIFIED',
        statusColor: AppColors.badgeBlue,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1B2E), // Twende Navy
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'twende.',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'My Documents Hub',
              style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notice Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.folder_shared_outlined, color: Colors.black, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Digital Rental Files',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0E1B2E)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Official PDF copies of your signed agreements, EBM invoices, and condition reports.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Available Documents',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0E1B2E)),
            ),
            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final d = docs[idx];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              d.title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0E1B2E)),
                            ),
                          ),
                          StatusBadge(label: d.status, color: d.statusColor),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ref: ${d.refNumber} • ${d.category}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 12, color: Colors.black),
                              const SizedBox(width: 4),
                              Text(dateFormat.format(d.date), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(width: 12),
                              const Icon(Icons.picture_as_pdf, size: 12, color: Colors.black),
                              const SizedBox(width: 4),
                              Text(d.size, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 18, color: Colors.black),
                                tooltip: 'Preview PDF',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Opening ${d.refNumber} in document viewer…')),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.file_download_outlined, size: 18, color: Colors.black),
                                tooltip: 'Download',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Downloading ${d.refNumber}.pdf…')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
