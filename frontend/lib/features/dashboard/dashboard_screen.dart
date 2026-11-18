import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/session_provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routing/twende_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money_utils.dart';
import '../../core/widgets/approval_banner.dart';
import '../../core/widgets/kpi_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/sync_status_bar.dart';
import '../../shared/domain/enums.dart';
import '../../shared/repositories/mock_repositories.dart';
import '../../shared/repositories/store_finance_repositories.dart';
import '../../shared/repositories/repository_interfaces.dart';
import '../../widgets/app_header.dart';
import '../../widgets/custom_drawer.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final selectedBranch = ref.watch(selectedBranchProvider);
    final dashboardRepo = ref.watch(dashboardRepositoryProvider);
    final contractRepo = ref.watch(contractRepositoryProvider);
    final approvalRepo = ref.watch(approvalRepositoryProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.screenBackground,
      appBar: AppHeader(
        title: AppStrings.t('DASHBOARD'),
      ),
      drawer: const CustomDrawer(currentRoute: TwendeRoutes.dashboard),
      body: Column(
        children: [
          const SyncStatusBar(),
          // Branch selector subheader bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.storefront, size: 18, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Operating Branch:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                PopupMenuButton<Branch>(
                  tooltip: 'Select Branch',
                  initialValue: selectedBranch,
                  onSelected: (branch) {
                    ref.read(sessionProvider.notifier).selectBranch(branch);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEEEE4),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedBranch?.name ?? 'Select Branch',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 16, color: Colors.black),
                      ],
                    ),
                  ),
                  itemBuilder: (ctx) {
                    return session.availableBranches.map((b) {
                      return PopupMenuItem<Branch>(
                        value: b,
                        child: Row(
                          children: [
                            Icon(
                              b.id == selectedBranch?.id ? Icons.check_circle : Icons.circle_outlined,
                              size: 16,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(b.name),
                          ],
                        ),
                      );
                    }).toList();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                setState(() {});
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pending approvals notification banner
                    FutureBuilder<List<TwendeApproval>>(
                      future: approvalRepo.getApprovals(status: ApprovalStatus.pending),
                      builder: (ctx, snapshot) {
                        final pending = snapshot.data ?? [];
                        if (pending.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ApprovalBanner(
                            count: pending.length,
                            message: '${pending.length} action(s) require supervisor authorization (discounts & refunds).',
                            onViewDetails: () => context.push(TwendeRoutes.approvals),
                          ),
                        );
                      },
                    ),

                    // Section Title: Executive KPIs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Fleet Operations Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          selectedBranch?.name ?? 'All Branches',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 6 KPI Grid Cards
                    FutureBuilder<DashboardKpis>(
                      future: dashboardRepo.getKpis(branchId: selectedBranch?.id),
                      builder: (ctx, snapshot) {
                        final kpis = snapshot.data;
                        final isLoading = snapshot.connectionState == ConnectionState.waiting;

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.35,
                          children: [
                            KpiCard(
                              label: 'Available Fleet',
                              value: isLoading ? '...' : '${kpis?.availableVehicles ?? 0} / ${kpis?.totalFleet ?? 0}',
                              icon: Icons.directions_car,
                              accent: AppColors.vehicleAvailable,
                              subLabel: 'Ready to dispatch',
                              onTap: () => context.push(TwendeRoutes.fleet),
                            ),
                            KpiCard(
                              label: 'Active Rentals',
                              value: isLoading ? '...' : '${kpis?.activeRentals ?? 0}',
                              icon: Icons.key,
                              accent: AppColors.vehicleRented,
                              subLabel: 'On the road',
                              onTap: () => context.push(TwendeRoutes.activeRentals),
                            ),
                            KpiCard(
                              label: 'Pickups Today',
                              value: isLoading ? '...' : '${kpis?.pickupsToday ?? 0}',
                              icon: Icons.outbox,
                              accent: AppColors.badgeBlue,
                              subLabel: 'Scheduled checkouts',
                              onTap: () => context.push(TwendeRoutes.activeRentals),
                            ),
                            KpiCard(
                              label: 'Returns Today',
                              value: isLoading ? '...' : '${kpis?.returnsToday ?? 0}',
                              icon: Icons.inbox,
                              accent: AppColors.primary,
                              subLabel: 'Due for check-in',
                              onTap: () => context.push(TwendeRoutes.activeRentals),
                            ),
                            KpiCard(
                              label: 'Overdue Returns',
                              value: isLoading ? '...' : '${kpis?.overdueReturns ?? 0}',
                              icon: Icons.warning_amber_rounded,
                              accent: AppColors.error,
                              subLabel: 'Action required',
                              onTap: () => context.push(TwendeRoutes.activeRentals),
                            ),
                            KpiCard(
                              label: 'Revenue (MTD)',
                              value: isLoading ? '...' : MoneyUtils.format(kpis?.revenueMtd ?? 0, kpis?.currency ?? 'RWF'),
                              icon: Icons.payments_outlined,
                              accent: Colors.teal,
                              subLabel: 'Rental revenue',
                              onTap: () => context.push(TwendeRoutes.billing),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Quick Operations Hub
                    const Text(
                      'Operational Modules',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        children: [
                          _buildModuleTile(
                            context: context,
                            icon: Icons.directions_car_filled_outlined,
                            iconColor: AppColors.primary,
                            title: 'Fleet & Vehicle Catalog',
                            subtitle: 'Status lifecycle, documents, equipment & maintenance',
                            route: TwendeRoutes.fleet,
                          ),
                          const Divider(height: 1),
                          _buildModuleTile(
                            context: context,
                            icon: Icons.people_alt_outlined,
                            iconColor: Colors.indigo,
                            title: 'Customer & Risk Registry',
                            subtitle: 'Corporate accounts, licences, eligibility & credit limits',
                            route: TwendeRoutes.customers,
                          ),
                          const Divider(height: 1),
                          _buildModuleTile(
                            context: context,
                            icon: Icons.assignment_outlined,
                            iconColor: Colors.teal,
                            title: 'Active Rentals & Handover / Returns',
                            subtitle: 'Field checklists, damage diagrams, signatures & reconciliation',
                            route: TwendeRoutes.activeRentals,
                          ),
                          const Divider(height: 1),
                          _buildModuleTile(
                            context: context,
                            icon: Icons.receipt_long_outlined,
                            iconColor: Colors.deepPurple,
                            title: 'Billing, Invoices & Payments',
                            subtitle: 'MoMo, Airtel Money, card settlements & deposits',
                            route: TwendeRoutes.billing,
                          ),
                          const Divider(height: 1),
                          _buildModuleTile(
                            context: context,
                            icon: Icons.smart_toy_outlined,
                            iconColor: AppColors.primary,
                            title: 'Ask Your Fleet (AI Advisory)',
                            subtitle: 'Demand forecast, pricing recommendations & turnaround suggestions',
                            route: TwendeRoutes.askFleet,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Recent / Critical Contracts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Contracts & Dispatches',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push(TwendeRoutes.activeRentals),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    FutureBuilder<PaginatedResult<TwendeContract>>(
                      future: contractRepo.getContracts(),
                      builder: (ctx, snapshot) {
                        final contracts = snapshot.data?.items ?? [];
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          );
                        }

                        if (contracts.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: const Center(
                              child: Text('No active contracts found for this branch.'),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: contracts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, idx) {
                            final contract = contracts[idx];
                            final isOverdue = contract.status == ContractStatus.active &&
                                DateTime.now().isAfter(contract.returnDateTime);

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: isOverdue ? AppColors.error : AppColors.cardBorder,
                                  width: isOverdue ? 1.5 : 1.0,
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isOverdue
                                          ? AppColors.error.withValues(alpha: 0.1)
                                          : const Color(0xFFFEEEE4),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      isOverdue ? Icons.timer_off_outlined : Icons.directions_car,
                                      color: Colors.black,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              contract.contractNumber,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                            StatusBadge(
                                              label: isOverdue ? 'OVERDUE' : contract.status.label,
                                              color: isOverdue ? AppColors.error : AppColors.primary,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${contract.vehicleName} (${contract.vehiclePlate})',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          'Customer: ${contract.customerName}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios, size: 14),
                                    onPressed: () => context.push('/contract/${contract.id}'),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.black, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.black),
      onTap: () => context.push(route),
    );
  }
}
