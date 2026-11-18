import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money_utils.dart';
import '../../core/widgets/audit_timeline.dart';
import '../../core/widgets/status_badge.dart';
import '../../shared/domain/enums.dart';
import '../../shared/repositories/store_finance_repositories.dart';
import '../../shared/repositories/repository_interfaces.dart';
import '../../widgets/app_header.dart';

class ContractDetailScreen extends ConsumerWidget {
  final String contractId;

  const ContractDetailScreen({super.key, required this.contractId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractRepo = ref.watch(contractRepositoryProvider);
    final dateFormat = DateFormat('EEE, MMM dd, yyyy HH:mm');

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: const AppHeader(
        title: 'Contract Detail',
      ),
      body: FutureBuilder<TwendeContract?>(
        future: contractRepo.getContractById(contractId),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final contract = snapshot.data;
          if (contract == null) {
            return const Center(child: Text('Contract not found.'));
          }

          final isOverdue = contract.status == ContractStatus.active &&
              DateTime.now().isAfter(contract.returnDateTime);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Info Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isOverdue ? AppColors.error : AppColors.cardBorder,
                      width: isOverdue ? 1.5 : 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            contract.contractNumber,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                          ),
                          StatusBadge(
                            label: isOverdue ? 'OVERDUE' : contract.status.label,
                            color: isOverdue ? AppColors.error : AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (contract.isSigned)
                        Row(
                          children: [
                            const Icon(Icons.lock, size: 14, color: Colors.black),
                            const SizedBox(width: 4),
                            Text(
                              'Signed & Locked (BR-15 Compliant)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade800),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      _buildRow('Customer / Hirer', contract.customerName),
                      const SizedBox(height: 6),
                      _buildRow('Assigned Vehicle', '${contract.vehicleName} (${contract.vehiclePlate})'),
                      const SizedBox(height: 6),
                      _buildRow('Pickup Schedule', dateFormat.format(contract.pickupDateTime)),
                      const SizedBox(height: 6),
                      _buildRow('Scheduled Return', dateFormat.format(contract.returnDateTime)),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Value', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(MoneyUtils.format(contract.totalAmount), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Deposit Held', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(MoneyUtils.format(contract.depositAmount), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.teal)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Balance Due', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(
                                MoneyUtils.format(contract.balanceDue),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: contract.balanceDue > 0 ? AppColors.error : Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Operational Action Button
                if (contract.status == ContractStatus.draft) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.assignment_turned_in),
                      label: const Text('Start Handover Inspection Wizard', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () => context.push('/handover/${contract.id}'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (contract.status == ContractStatus.active) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOverdue ? AppColors.error : AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.assignment_return),
                      label: const Text('Perform Return Inspection & Reconciliation', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () => context.push('/return/${contract.id}'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Lifecycle & Audit History
                AuditTimelineWidget(
                  events: [
                    AuditEventItem(
                      timestamp: contract.pickupDateTime.subtract(const Duration(hours: 2)),
                      title: 'Booking Confirmed & Contract Created',
                      actor: 'Rental Agent (Eric Kwizera)',
                      details: 'Generated from Quote with 18% VAT applied.',
                      icon: Icons.create,
                      color: AppColors.badgeBlue,
                    ),
                    if (contract.isSigned)
                      AuditEventItem(
                        timestamp: contract.pickupDateTime,
                        title: 'Handover Completed & Customer Signed',
                        actor: 'Field Agent (Aline Uwera)',
                        details: 'Key & documents issued. Handover inspection saved.',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    if (isOverdue)
                      AuditEventItem(
                        timestamp: contract.returnDateTime,
                        title: 'Scheduled Return Window Elapsed',
                        actor: 'System Automated Monitor',
                        details: 'Grace period (60 min) exceeded. Vehicle flagged as overdue.',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.error,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
