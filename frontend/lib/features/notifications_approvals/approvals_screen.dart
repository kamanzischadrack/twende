import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routing/twende_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money_utils.dart';
import '../../core/widgets/status_badge.dart';
import '../../shared/domain/enums.dart';
import '../../shared/repositories/mock_repositories.dart';
import '../../shared/repositories/repository_interfaces.dart';
import '../../widgets/app_header.dart';
import '../../widgets/custom_drawer.dart';

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  void _process(String id, bool approve) async {
    final approvalRepo = ref.read(approvalRepositoryProvider);
    await approvalRepo.processApproval(id, approve,
        approve ? 'Approved by supervisor' : 'Rejected by supervisor');
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approve ? 'Request approved.' : 'Request rejected.'),
        backgroundColor: approve ? Colors.green : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final approvalRepo = ref.watch(approvalRepositoryProvider);
    final dateFormat = DateFormat('MMM dd, HH:mm');

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppHeader(
        title: AppStrings.t('APPROVALS'),
      ),
      drawer: const CustomDrawer(currentRoute: TwendeRoutes.approvals),
      body: FutureBuilder<List<TwendeApproval>>(
        future: approvalRepo.getApprovals(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          final approvals = snapshot.data ?? [];
          if (approvals.isEmpty) {
            return const Center(
                child: Text('No pending approvals at this time.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: approvals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              final a = approvals[idx];
              final isPending = a.status == ApprovalStatus.pending;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isPending ? AppColors.warning : AppColors.cardBorder,
                    width: isPending ? 1.5 : 1.0,
                  ),
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
                            a.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                        StatusBadge(
                          label: a.status.name.toUpperCase(),
                          color: a.status == ApprovalStatus.pending
                              ? AppColors.warning
                              : (a.status == ApprovalStatus.approved
                                  ? Colors.green
                                  : AppColors.error),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Requested by: ${a.requestedBy} • ${dateFormat.format(a.createdAt)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9FA),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reason: ${a.reason}',
                              style: const TextStyle(fontSize: 12)),
                          if (a.amount > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Amount Involved: ${MoneyUtils.format(a.amount)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isPending) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                              ),
                              onPressed: () => _process(a.id, false),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _process(a.id, true),
                              child: const Text('Authorize & Approve'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
