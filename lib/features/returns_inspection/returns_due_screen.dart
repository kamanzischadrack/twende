import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/auth/session_provider.dart';
import '../../core/routing/twende_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money_utils.dart';
import '../../shared/domain/enums.dart';
import '../../shared/repositories/repository_interfaces.dart';
import '../../shared/repositories/store_finance_repositories.dart';
import '../../widgets/app_header.dart';
import '../../widgets/custom_drawer.dart';

class ReturnsDueScreen extends ConsumerStatefulWidget {
  const ReturnsDueScreen({super.key});

  @override
  ConsumerState<ReturnsDueScreen> createState() => _ReturnsDueScreenState();
}

class _ReturnsDueScreenState extends ConsumerState<ReturnsDueScreen> {
  late Future<List<TwendeContract>> _contractsFuture;

  @override
  void initState() {
    super.initState();
    _contractsFuture = _loadContracts();
  }

  Future<List<TwendeContract>> _loadContracts() async {
    final repository = ref.read(contractRepositoryProvider);
    const pageSize = 100;
    final firstPage = await repository.getContracts(
      page: 1,
      pageSize: pageSize,
    );
    final contracts = [...firstPage.items];
    for (var page = 2; (page - 1) * pageSize < firstPage.totalCount; page++) {
      final result = await repository.getContracts(
        page: page,
        pageSize: pageSize,
      );
      contracts.addAll(result.items);
    }
    return contracts;
  }

  Future<void> _refresh() async {
    final future = _loadContracts();
    setState(() => _contractsFuture = future);
    await future;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  Widget build(BuildContext context) {
    final graceMinutes = ref.watch(tenantConfigProvider).lateReturnGraceMinutes;
    final today = _dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: const AppHeader(title: 'Returns Due'),
      drawer: const CustomDrawer(currentRoute: TwendeRoutes.returnsDue),
      body: FutureBuilder<List<TwendeContract>>(
        future: _contractsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Returns due could not be loaded.'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => setState(
                      () => _contractsFuture = _loadContracts(),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final now = DateTime.now();
          final activeContracts = (snapshot.data ?? const [])
              .where((contract) =>
                  contract.status == ContractStatus.active ||
                  contract.status == ContractStatus.extended)
              .toList()
            ..sort((first, second) =>
                first.returnDateTime.compareTo(second.returnDateTime));

          final overdue = activeContracts.where((contract) {
            final overdueAt =
                contract.returnDateTime.add(Duration(minutes: graceMinutes));
            return overdueAt.isBefore(now);
          }).toList();
          final dueToday = activeContracts.where((contract) {
            return _dateOnly(contract.returnDateTime) == today &&
                !overdue.contains(contract);
          }).toList();
          final dueTomorrow = activeContracts
              .where(
                  (contract) => _dateOnly(contract.returnDateTime) == tomorrow)
              .toList();

          if (overdue.isEmpty && dueToday.isEmpty && dueTomorrow.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Icon(
                    Icons.event_available_outlined,
                    size: 52,
                    color: Colors.black,
                  ),
                  SizedBox(height: 12),
                  Center(child: Text('No returns due today or tomorrow.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildGroup(
                  context,
                  title: 'Overdue',
                  contracts: overdue,
                  isOverdue: true,
                ),
                _buildGroup(
                  context,
                  title: 'Today',
                  contracts: dueToday,
                ),
                _buildGroup(
                  context,
                  title: 'Tomorrow',
                  contracts: dueTomorrow,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroup(
    BuildContext context, {
    required String title,
    required List<TwendeContract> contracts,
    bool isOverdue = false,
  }) {
    if (contracts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
            child: Text(
              '$title (${contracts.length})',
              style: TextStyle(
                color: isOverdue ? AppColors.error : AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final contract in contracts)
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${contract.vehiclePlate} · ${contract.customerName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isOverdue)
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.black,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${contract.contractNumber} · ${contract.vehicleName}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Due ${DateFormat('EEE, d MMM · HH:mm').format(contract.returnDateTime)}',
                      style: TextStyle(
                        color:
                            isOverdue ? AppColors.error : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Balance: ${MoneyUtils.format(contract.balanceDue)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () => context.push(
                          TwendeRoutes.returnInspection
                              .replaceFirst(':id', contract.id),
                        ),
                        icon: const Icon(Icons.assignment_return, size: 18),
                        label: const Text('Start return'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
