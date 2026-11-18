import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session_provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routing/twende_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_badge.dart';
import '../../services/availability_service.dart';
import '../../shared/repositories/store_repositories.dart';
import '../../shared/repositories/repository_interfaces.dart';
import '../../widgets/app_header.dart';
import '../../widgets/custom_drawer.dart';

class AvailabilityScreen extends ConsumerWidget {
  const AvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fleetRepo = ref.watch(fleetRepositoryProvider);
    final tenant = ref.watch(tenantConfigProvider);
    final start = DateTime.now().add(const Duration(days: 2));
    final pickup = DateTime(start.year, start.month, start.day, 10, 0, 0);
    final returnDate = pickup.add(const Duration(days: 3));

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppHeader(title: AppStrings.t('AVAILABILITY')),
      drawer: const CustomDrawer(currentRoute: TwendeRoutes.availability),
      body: FutureBuilder<PaginatedResult<TwendeVehicle>>(
        future: fleetRepo.getVehicles(pageSize: 200),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final vehicles = snapshot.data?.items ?? const <TwendeVehicle>[];
          final summaries = AvailabilityService.evaluateFleet(
            vehicles: vehicles,
            pickupDateTime: pickup,
            returnDateTime: returnDate,
            tenantConfig: tenant,
          );
          final availableCount = summaries
              .where((entry) => entry.availability.isAvailable)
              .length;

          return Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Availability window',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pickup.day}/${pickup.month}/${pickup.year} → ${returnDate.day}/${returnDate.month}/${returnDate.year}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEEEE4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$availableCount / ${summaries.length} available',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: summaries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final summary = summaries[index];
                    final vehicle = summary.vehicle;
                    final isAvailable = summary.availability.isAvailable;

                    return InkWell(
                      onTap: () => context.push('/fleet/${vehicle.id}'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vehicle.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${vehicle.plateNumber} • ${vehicle.category}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge.vehicle(vehicle.status),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isAvailable ? 'Available for booking' : 'Blocked by rule',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isAvailable ? AppColors.vehicleAvailable : AppColors.vehicleOos,
                                  ),
                                ),
                                Text(
                                  vehicle.branchName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            if (!isAvailable) ...[
                              const SizedBox(height: 10),
                              ...summary.availability.conflicts.take(2).map((conflict) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.all(8),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    conflict.message,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
