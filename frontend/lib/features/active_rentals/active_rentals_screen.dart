import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routing/twende_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_badge.dart';
import '../../shared/domain/enums.dart';
import '../../shared/repositories/store_finance_repositories.dart';
import '../../shared/repositories/repository_interfaces.dart';
import '../../widgets/app_header.dart';
import '../../widgets/custom_drawer.dart';

class ActiveRentalsScreen extends ConsumerStatefulWidget {
  const ActiveRentalsScreen({super.key});

  @override
  ConsumerState<ActiveRentalsScreen> createState() =>
      _ActiveRentalsScreenState();
}

class _ActiveRentalsScreenState extends ConsumerState<ActiveRentalsScreen> {
  bool _filterOverdueOnly = false;

  @override
  Widget build(BuildContext context) {
    final contractRepo = ref.watch(contractRepositoryProvider);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppHeader(
        title: AppStrings.t('ACTIVE_RENTALS'),
      ),
      drawer: const CustomDrawer(currentRoute: TwendeRoutes.activeRentals),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Show Overdue Only:',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Switch(
                  value: _filterOverdueOnly,
                  activeThumbColor: AppColors.error,
                  onChanged: (val) => setState(() => _filterOverdueOnly = val),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<PaginatedResult<TwendeContract>>(
              future: contractRepo.getContracts(status: ContractStatus.active),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Unable to load active rentals.'),
                        TextButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                var contracts = snapshot.data?.items ?? [];
                if (_filterOverdueOnly) {
                  contracts = contracts
                      .where((c) => DateTime.now().isAfter(c.returnDateTime))
                      .toList();
                }

                if (contracts.isEmpty) {
                  return const Center(
                    child: Text('No active rentals matching filter.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: contracts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final c = contracts[idx];
                    final isOverdue = DateTime.now().isAfter(c.returnDateTime);
                    final overdueDuration = isOverdue
                        ? DateTime.now().difference(c.returnDateTime)
                        : null;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: isOverdue
                              ? AppColors.error
                              : AppColors.cardBorder,
                          width: isOverdue ? 1.5 : 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(c.contractNumber,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              StatusBadge(
                                label: isOverdue
                                    ? 'OVERDUE (${overdueDuration!.inHours}h)'
                                    : 'ON TIME',
                                color:
                                    isOverdue ? AppColors.error : Colors.green,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${c.vehicleName} (${c.vehiclePlate})',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Text(
                            'Customer: ${c.customerName}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.schedule,
                                  size: 14, color: Colors.black),
                              const SizedBox(width: 4),
                              Text(
                                'Due: ${dateFormat.format(c.returnDateTime)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOverdue
                                      ? AppColors.error
                                      : AppColors.textPrimary,
                                  fontWeight: isOverdue
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    context.push('/contract/${c.id}'),
                                child: const Text('View Contract'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isOverdue
                                      ? AppColors.error
                                      : AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.assignment_return,
                                    size: 16),
                                label: const Text('Start Return'),
                                onPressed: () =>
                                    context.push('/return/${c.id}'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
