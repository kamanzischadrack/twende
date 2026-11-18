import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routing/twende_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money_utils.dart';
import '../../core/widgets/status_badge.dart';
import '../../shared/domain/enums.dart';
import '../../shared/repositories/store_repositories.dart';
import '../../shared/repositories/repository_interfaces.dart';
import '../../widgets/app_header.dart';
import '../../widgets/custom_drawer.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  CustomerType? _selectedTypeFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _riskColor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.standard:
        return Colors.green;
      case RiskLevel.watch:
        return Colors.orange;
      case RiskLevel.blacklisted:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerRepo = ref.watch(customerRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppHeader(
        title: AppStrings.t('CUSTOMERS'),
      ),
      drawer: const CustomDrawer(currentRoute: TwendeRoutes.customers),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by customer name, phone, or company...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: Colors.black),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: const Text('All Types'),
                          selected: _selectedTypeFilter == null,
                          selectedColor: const Color(0xFFFEEEE4),
                          onSelected: (val) {
                            if (val) setState(() => _selectedTypeFilter = null);
                          },
                        ),
                      ),
                      ...CustomerType.values.map((t) {
                        final isSel = _selectedTypeFilter == t;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(t.label),
                            selected: isSel,
                            selectedColor: const Color(0xFFFEEEE4),
                            onSelected: (val) {
                              setState(() => _selectedTypeFilter = val ? t : null);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<PaginatedResult<TwendeCustomer>>(
              future: customerRepo.getCustomers(
                type: _selectedTypeFilter,
                search: _searchController.text,
              ),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final customers = snapshot.data?.items ?? [];
                if (customers.isEmpty) {
                  return const Center(child: Text('No customers found.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: customers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final c = customers[idx];
                    return InkWell(
                      onTap: () => context.push('/customers/${c.id}'),
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.fullName,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                      ),
                                      if (c.companyName != null)
                                        Text(
                                          c.companyName!,
                                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                                        ),
                                    ],
                                  ),
                                ),
                                StatusBadge(
                                  label: '${c.riskLevel.name.toUpperCase()} RISK',
                                  color: _riskColor(c.riskLevel),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 14, color: Colors.black),
                                const SizedBox(width: 4),
                                Text(c.phone, style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 16),
                                const Icon(Icons.badge, size: 14, color: Colors.black),
                                const SizedBox(width: 4),
                                Text(c.type.label, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Credit Limit: ${MoneyUtils.format(c.creditLimit)}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                Text(
                                  'Balance: ${MoneyUtils.format(c.outstandingBalance)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: c.outstandingBalance > 0 ? AppColors.error : Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
