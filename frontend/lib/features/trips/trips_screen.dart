// lib/features/trips/trips_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_header.dart';
import '../../widgets/custom_drawer.dart';
import '../../shared/domain/enums.dart';
import '../../shared/repositories/store_repositories.dart';
import '../../shared/repositories/repository_interfaces.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Color _statusColor(TripStatus s) {
    switch (s) {
      case TripStatus.planned:
        return AppColors.badgeBlue;
      case TripStatus.inProgress:
        return AppColors.warning;
      case TripStatus.delivered:
        return AppColors.success;
      case TripStatus.closed:
        return AppColors.textSecondary;
      case TripStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _statusIcon(TripStatus s) {
    switch (s) {
      case TripStatus.planned:
        return Icons.schedule;
      case TripStatus.inProgress:
        return Icons.local_shipping;
      case TripStatus.delivered:
        return Icons.check_circle;
      case TripStatus.closed:
        return Icons.archive;
      case TripStatus.cancelled:
        return Icons.cancel;
    }
  }

  List<_TripData> get _filtered {
    return _mockTrips.where((t) {
      if (_search.isEmpty) return true;
      return t.id.toLowerCase().contains(_search) ||
          t.vehiclePlate.toLowerCase().contains(_search) ||
          t.driverName.toLowerCase().contains(_search) ||
          t.destination.toLowerCase().contains(_search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(fleetRepositoryProvider);

    return Scaffold(
      appBar: const AppHeader(),
      drawer: const CustomDrawer(currentRoute: '/trips'),
      body: FutureBuilder<PaginatedResult<TwendeVehicle>>(
        future: repo.getVehicles(),
        builder: (context, snapshot) {
          return Column(
            children: [
              // Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_shipping, color: Colors.black, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'Trips & Logistics',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () => _showNewTripDialog(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New Trip'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            textStyle:
                                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Summary row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: TripStatus.values.map((s) {
                          final count = _mockTrips.where((t) => t.status == s).length;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _Chip(
                              label: s.label,
                              count: count,
                              color: _statusColor(s),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TabBar(
                      controller: _tab,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      tabs: const [
                        Tab(text: 'Active'),
                        Tab(text: 'Planned'),
                        Tab(text: 'Completed'),
                      ],
                    ),
                  ],
                ),
              ),
              // Search
              Container(
                color: const Color(0xFFF5F5F5),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search trip ID, vehicle, driver, destination…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _TripList(
                      trips: _filtered
                          .where((t) => t.status == TripStatus.inProgress)
                          .toList(),
                      statusColor: _statusColor,
                      statusIcon: _statusIcon,
                      onTap: (t) => _showTripDetail(context, t),
                    ),
                    _TripList(
                      trips: _filtered
                          .where((t) => t.status == TripStatus.planned)
                          .toList(),
                      statusColor: _statusColor,
                      statusIcon: _statusIcon,
                      onTap: (t) => _showTripDetail(context, t),
                    ),
                    _TripList(
                      trips: _filtered
                          .where((t) =>
                              t.status == TripStatus.delivered ||
                              t.status == TripStatus.closed ||
                              t.status == TripStatus.cancelled)
                          .toList(),
                      statusColor: _statusColor,
                      statusIcon: _statusIcon,
                      onTap: (t) => _showTripDetail(context, t),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTripDetail(BuildContext context, _TripData trip) {
    final color = _statusColor(trip.status);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  trip.id,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(trip.status), size: 13, color: color),
                      const SizedBox(width: 4),
                      Text(trip.status.label,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(icon: Icons.directions_car, label: 'Vehicle', value: trip.vehiclePlate),
            _DetailRow(icon: Icons.person, label: 'Driver', value: trip.driverName),
            _DetailRow(
                icon: Icons.location_on, label: 'Route', value: '${trip.origin} → ${trip.destination}'),
            _DetailRow(
                icon: Icons.calendar_today,
                label: 'Scheduled',
                value: _fmt(trip.scheduledDate)),
            _DetailRow(icon: Icons.straighten, label: 'Distance', value: '${trip.estimatedKm} km'),
            _DetailRow(
                icon: Icons.local_gas_station,
                label: 'Fuel Budget',
                value: 'RWF ${trip.fuelBudgetRwf.toStringAsFixed(0)}'),
            _DetailRow(icon: Icons.business, label: 'Client', value: trip.clientName),
            const SizedBox(height: 20),
            if (trip.status == TripStatus.planned || trip.status == TripStatus.inProgress)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Trip ${trip.id} status updated')),
                        );
                      },
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                      child: Text(
                          trip.status == TripStatus.planned ? 'Start Trip' : 'Mark Delivered'),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showNewTripDialog(BuildContext context) {
    final destCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Trip', style: TextStyle(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: driverCtrl,
                decoration: const InputDecoration(
                  labelText: 'Driver Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: destCtrl,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Trip planned: ${driverCtrl.text.trim()} → ${destCtrl.text.trim()}')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ── Mock Data ────────────────────────────────────────────────────────────────

class _TripData {
  final String id;
  final String vehiclePlate;
  final String driverName;
  final String origin;
  final String destination;
  final TripStatus status;
  final DateTime scheduledDate;
  final int estimatedKm;
  final double fuelBudgetRwf;
  final String clientName;

  const _TripData({
    required this.id,
    required this.vehiclePlate,
    required this.driverName,
    required this.origin,
    required this.destination,
    required this.status,
    required this.scheduledDate,
    required this.estimatedKm,
    required this.fuelBudgetRwf,
    required this.clientName,
  });
}

final _mockTrips = [
  _TripData(
    id: 'TRP-001',
    vehiclePlate: 'RAC 123A',
    driverName: 'Olivier N.',
    origin: 'Kigali — HQ',
    destination: 'Musanze',
    status: TripStatus.inProgress,
    scheduledDate: DateTime.now().subtract(const Duration(hours: 3)),
    estimatedKm: 115,
    fuelBudgetRwf: 28750,
    clientName: 'Rwanda Development Board',
  ),
  _TripData(
    id: 'TRP-002',
    vehiclePlate: 'RAD 456B',
    driverName: 'Alice M.',
    origin: 'Kigali — Airport',
    destination: 'Rubavu',
    status: TripStatus.planned,
    scheduledDate: DateTime.now().add(const Duration(hours: 5)),
    estimatedKm: 160,
    fuelBudgetRwf: 40000,
    clientName: 'MTN Rwanda',
  ),
  _TripData(
    id: 'TRP-003',
    vehiclePlate: 'RAE 789C',
    driverName: 'Jean B.',
    origin: 'Kigali',
    destination: 'Nyamata',
    status: TripStatus.planned,
    scheduledDate: DateTime.now().add(const Duration(days: 1)),
    estimatedKm: 55,
    fuelBudgetRwf: 13750,
    clientName: 'BK Insurance',
  ),
  _TripData(
    id: 'TRP-004',
    vehiclePlate: 'RAB 321D',
    driverName: 'Patrick K.',
    origin: 'Kigali',
    destination: 'Rwamagana',
    status: TripStatus.delivered,
    scheduledDate: DateTime.now().subtract(const Duration(days: 2)),
    estimatedKm: 50,
    fuelBudgetRwf: 12500,
    clientName: 'MININFRA',
  ),
  _TripData(
    id: 'TRP-005',
    vehiclePlate: 'RAF 654E',
    driverName: 'David U.',
    origin: 'Kigali',
    destination: 'Nyagatare',
    status: TripStatus.closed,
    scheduledDate: DateTime.now().subtract(const Duration(days: 4)),
    estimatedKm: 190,
    fuelBudgetRwf: 47500,
    clientName: 'World Food Programme',
  ),
];

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _Chip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _TripList extends StatelessWidget {
  final List<_TripData> trips;
  final Color Function(TripStatus) statusColor;
  final IconData Function(TripStatus) statusIcon;
  final void Function(_TripData) onTap;

  const _TripList({
    required this.trips,
    required this.statusColor,
    required this.statusIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined, size: 48, color: Colors.black),
            SizedBox(height: 12),
            Text('No trips', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final t = trips[i];
        final color = statusColor(t.status);
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onTap(t),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(statusIcon(t.status), color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              t.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '• ${t.vehiclePlate}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${t.origin} → ${t.destination}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${t.driverName} • ${t.estimatedKm} km • ${t.clientName}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
