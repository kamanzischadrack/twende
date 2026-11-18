// lib/features/driver_app/driver_job_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money_utils.dart';
import '../../shared/domain/enums.dart';
import '../../shared/repositories/repository_interfaces.dart';
import '../../shared/repositories/trip_repository.dart';

class DriverJobDetailScreen extends ConsumerStatefulWidget {
  final String tripId;

  const DriverJobDetailScreen({super.key, required this.tripId});

  @override
  ConsumerState<DriverJobDetailScreen> createState() => _DriverJobDetailScreenState();
}

class _DriverJobDetailScreenState extends ConsumerState<DriverJobDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(tripRepositoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Trip ${widget.tripId}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<TwendeTrip?>(
        initialData: StoreTripRepository.seedTrips[widget.tripId],
        future: repo.getTripById(widget.tripId),
        builder: (context, snapshot) {
          if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final trip = snapshot.data;
          if (trip == null) {
            return const Center(child: Text('Trip not found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Card: Plate, Status, Route
                _buildHeaderCard(trip),

                const SizedBox(height: 16),

                // 2. Client & Contact Box with Direct Call Action
                _buildClientContactCard(trip),

                const SizedBox(height: 16),

                // 3. Cargo & Freight Specification Card
                _buildCargoCard(trip),

                const SizedBox(height: 20),

                // 4. Primary Driver Actions Grid (Big 48dp touch targets)
                const Text(
                  'Driver Action Hub',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildActionsGrid(trip),

                const SizedBox(height: 24),

                // 5. Trip Expense Log List
                _buildExpensesList(),

                const SizedBox(height: 24),

                // 6. Emergency & Incidents Section
                _buildIncidentsList(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Header Card
  // ---------------------------------------------------------------------------
  Widget _buildHeaderCard(TwendeTrip trip) {
    final statusColor = _statusColor(trip.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.vehicleName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Plate: ${trip.vehiclePlate}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  trip.status == TripStatus.inProgress
                      ? 'In Progress'
                      : trip.status == TripStatus.delivered
                          ? 'Delivered'
                          : 'Scheduled',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.trip_origin, color: Colors.black, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Origin: ${trip.origin}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          if (trip.stops.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                'Stops: ${trip.stops.join(', ')}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.black, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Destination: ${trip.destination}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Client Contact Card
  // ---------------------------------------------------------------------------
  Widget _buildClientContactCard(TwendeTrip trip) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.business, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.clientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  trip.clientPhone,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dialing ${trip.clientPhone}...')),
              );
            },
            icon: const Icon(Icons.call, size: 16),
            label: const Text('Call'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: const Size(0, 44),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Cargo Specification Card
  // ---------------------------------------------------------------------------
  Widget _buildCargoCard(TwendeTrip trip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cargo & Consignment',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCargoItem('Type', trip.cargoType),
              _buildCargoItem('Weight', '${(trip.cargoWeightKg / 1000).toStringAsFixed(1)} Tons'),
              _buildCargoItem('Volume', '${trip.cargoVolumeM3.toStringAsFixed(1)} m³'),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 16, color: Colors.black),
                const SizedBox(width: 8),
                Text(
                  'Container Seal #: ${trip.sealNumber}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCargoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Action Hub Grid
  // ---------------------------------------------------------------------------
  Widget _buildActionsGrid(TwendeTrip trip) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBigActionButton(
                icon: Icons.checklist_rtl,
                label: trip.checklistCompleted ? 'Checklist Done ✓' : 'Pre-Trip Check',
                subtitle: 'Walkaround & load',
                color: trip.checklistCompleted ? AppColors.success : AppColors.primary,
                onTap: () {
                  context.push('/driver/jobs/${trip.id}/checklist').then((_) => setState(() {}));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBigActionButton(
                icon: Icons.receipt_long,
                label: 'Log Expense',
                subtitle: 'Fuel, toll & border',
                color: AppColors.secondary,
                onTap: () {
                  context.push('/driver/jobs/${trip.id}/expense').then((_) => setState(() {}));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildBigActionButton(
                icon: Icons.warning_amber_rounded,
                label: 'Report Issue',
                subtitle: 'Breakdown / delay',
                color: AppColors.error,
                onTap: () {
                  context.push('/driver/jobs/${trip.id}/incident').then((_) => setState(() {}));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBigActionButton(
                icon: Icons.assignment_turned_in,
                label: trip.status == TripStatus.delivered ? 'POD Sealed ✓' : 'Proof of Delivery',
                subtitle: 'Sign on glass (POD)',
                color: trip.status == TripStatus.delivered ? AppColors.success : const Color(0xFF1E2F4D),
                onTap: () {
                  context.push('/driver/jobs/${trip.id}/pod').then((_) => setState(() {}));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBigActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.black, size: 24),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Trip Expense Log List
  // ---------------------------------------------------------------------------
  Widget _buildExpensesList() {
    final repo = ref.watch(tripRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Trip Expenses Logged',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                context.push('/driver/jobs/${widget.tripId}/expense').then((_) => setState(() {}));
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Expense', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        FutureBuilder<List<TripExpense>>(
          future: repo.getExpensesForTrip(widget.tripId),
          builder: (context, snapshot) {
            final expenses = snapshot.data ?? [];
            if (expenses.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: Text(
                    'No expenses logged yet. Tap Add Expense above.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              );
            }

            return Column(
              children: expenses.map((e) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt, color: Colors.black, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.type,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            if (e.notes != null)
                              Text(
                                e.notes!,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        MoneyUtils.formatRwf(e.amountRwf),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Incidents List
  // ---------------------------------------------------------------------------
  Widget _buildIncidentsList() {
    final repo = ref.watch(tripRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Incident & Breakdown Reports',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<TripIncident>>(
          future: repo.getIncidents(tripId: widget.tripId),
          builder: (context, snapshot) {
            final incidents = snapshot.data ?? [];
            if (incidents.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: Text(
                    'No issues reported on this trip.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              );
            }

            return Column(
              children: incidents.map((inc) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.black, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${inc.type} (${inc.severity} Severity)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              inc.description,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          inc.status,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Color _statusColor(TripStatus status) {
    switch (status) {
      case TripStatus.planned:
        return AppColors.badgeBlue;
      case TripStatus.inProgress:
        return AppColors.secondary;
      case TripStatus.delivered:
        return AppColors.success;
      case TripStatus.closed:
        return AppColors.textSecondary;
      case TripStatus.cancelled:
        return AppColors.error;
    }
  }
}
