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

class VehicleListScreen extends ConsumerStatefulWidget {
  const VehicleListScreen({super.key});

  @override
  ConsumerState<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends ConsumerState<VehicleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  VehicleStatus? _selectedStatusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fleetRepo = ref.watch(fleetRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppHeader(
        title: AppStrings.t('FLEET'),
      ),
      drawer: const CustomDrawer(currentRoute: TwendeRoutes.fleet),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by model, plate (e.g. RAC 452 K)...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: Colors.black),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: const Text('All Vehicles'),
                          selected: _selectedStatusFilter == null,
                          selectedColor: const Color(0xFFFEEEE4),
                          onSelected: (val) {
                            if (val) setState(() => _selectedStatusFilter = null);
                          },
                        ),
                      ),
                      ...[
                        VehicleStatus.available,
                        VehicleStatus.rented,
                        VehicleStatus.reserved,
                        VehicleStatus.underInspection,
                        VehicleStatus.underMaintenance,
                      ].map((s) {
                        final isSel = _selectedStatusFilter == s;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(s.label),
                            selected: isSel,
                            selectedColor: const Color(0xFFFEEEE4),
                            onSelected: (val) {
                              setState(() => _selectedStatusFilter = val ? s : null);
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

          // Vehicle list
          Expanded(
            child: FutureBuilder<PaginatedResult<TwendeVehicle>>(
              future: fleetRepo.getVehicles(
                status: _selectedStatusFilter,
                search: _searchController.text,
              ),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final vehicles = snapshot.data?.items ?? [];
                if (vehicles.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_car_outlined, size: 64, color: Colors.black),
                        const SizedBox(height: 12),
                        const Text(
                          'No vehicles match your criteria.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        if (_selectedStatusFilter != null || _searchController.text.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedStatusFilter = null;
                                _searchController.clear();
                              });
                            },
                            child: const Text('Reset Filters'),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: vehicles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final v = vehicles[idx];
                    return InkWell(
                      onTap: () => context.push('/fleet/${v.id}'),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Vehicle avatar icon
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.directions_car, color: Colors.black, size: 28),
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
                                          Expanded(
                                            child: Text(
                                              v.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          StatusBadge.vehicle(v.status),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Plate: ${v.plateNumber} • ${v.category}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Branch: ${v.branchName}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.speed, size: 14, color: Colors.black),
                                    const SizedBox(width: 4),
                                    Text('${v.mileage} km', style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.local_gas_station, size: 14, color: Colors.black),
                                    const SizedBox(width: 4),
                                    Text(v.fuelType, style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                Text(
                                  '${MoneyUtils.format(v.dailyRate)} / day',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    fontSize: 13,
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
