import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routing/twende_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money_utils.dart';
import '../../core/widgets/status_badge.dart';
import '../../shared/domain/enums.dart';
import '../../shared/repositories/store_repositories.dart';
import '../../shared/repositories/repository_interfaces.dart';
import '../../widgets/app_header.dart';

class VehicleDetailScreen extends ConsumerStatefulWidget {
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends ConsumerState<VehicleDetailScreen> {
  void _showStatusOverrideDialog(TwendeVehicle vehicle) {
    VehicleStatus newStatus = vehicle.status;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Override Vehicle Status (BR-10)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manual state changes are recorded in the audit log and require operational justification.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              const Text('Target Status:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<VehicleStatus>(
                initialValue: newStatus,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: VehicleStatus.values.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s.label));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => newStatus = val);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Justification / Reason *',
                  hintText: 'e.g. Scheduled for 40,000 km oil change',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide an operational justification.')),
                  );
                  return;
                }
                final fleetRepo = ref.read(fleetRepositoryProvider);
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(ctx);
                await fleetRepo.updateVehicleStatus(
                  vehicle.id,
                  newStatus,
                  reasonController.text.trim(),
                );
                if (!mounted) return;
                nav.pop();
                setState(() {});
                messenger.showSnackBar(
                  SnackBar(content: Text('Vehicle status updated to ${newStatus.label}.')),
                );
              },
              child: const Text('Apply Override'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fleetRepo = ref.watch(fleetRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: const AppHeader(
        title: 'Vehicle Profile',
      ),
      body: FutureBuilder<TwendeVehicle?>(
        future: fleetRepo.getVehicleById(widget.vehicleId),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final vehicle = snapshot.data;
          if (vehicle == null) {
            return const Center(child: Text('Vehicle not found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              vehicle.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                            ),
                          ),
                          StatusBadge.vehicle(vehicle.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Plate: ${vehicle.plateNumber} • ${vehicle.year} • ${vehicle.category}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Assigned Branch: ${vehicle.branchName}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Base Daily Rate', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(
                                '${MoneyUtils.format(vehicle.dailyRate)} / day',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                            ),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Override Status'),
                            onPressed: () => _showStatusOverrideDialog(vehicle),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Specifications Grid
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Specifications & Telematics',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildSpecItem('Odometer', '${vehicle.mileage} km', Icons.speed)),
                          Expanded(child: _buildSpecItem('Fuel Type', vehicle.fuelType, Icons.local_gas_station)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildSpecItem('Make', vehicle.make, Icons.business)),
                          Expanded(child: _buildSpecItem('Model', vehicle.model, Icons.directions_car)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Compliance & Documents
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified_user_outlined, size: 18, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            'Regulatory Compliance & Documents',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentRow('Motor Insurance (Comprehensive)', 'Expires in 184 days (Valid)', true),
                      const Divider(height: 12),
                      _buildDocumentRow('Technical Control / Inspection (Contrôle Technique)', 'Expires in 42 days (Valid)', true),
                      const Divider(height: 12),
                      _buildDocumentRow('Road Fund / Vignette', 'Valid through Dec 2026', true),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Equipment List
                if (vehicle.equipment.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Equipped Gear & Options',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: vehicle.equipment.map((eq) {
                            return Chip(
                              backgroundColor: const Color(0xFFF5F5F5),
                              label: Text(eq, style: const TextStyle(fontSize: 12)),
                              avatar: const Icon(Icons.check_circle, size: 14, color: Colors.black),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action Button: Create Quote / Booking
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Create Quote / Booking with this Vehicle', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () {
                      context.push(TwendeRoutes.bookingNew, extra: {'vehicleId': vehicle.id});
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpecItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentRow(String docName, String validity, bool isValid) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(docName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              Text(validity, style: TextStyle(fontSize: 11, color: isValid ? Colors.green.shade800 : AppColors.error)),
            ],
          ),
        ),
        Icon(isValid ? Icons.check_circle : Icons.warning, size: 18, color: Colors.black),
      ],
    );
  }
}
