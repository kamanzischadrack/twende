// lib/features/maintenance/maintenance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_header.dart';
import '../../widgets/custom_drawer.dart';
import '../../shared/domain/enums.dart';
import '../../shared/repositories/store_repositories.dart';
import '../../shared/repositories/repository_interfaces.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen>
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

  Color _statusColor(WorkOrderStatus s) {
    switch (s) {
      case WorkOrderStatus.inProgress:
        return AppColors.warning;
      case WorkOrderStatus.completed:
        return AppColors.success;
      case WorkOrderStatus.cancelled:
        return AppColors.textSecondary;
      case WorkOrderStatus.planned:
        return AppColors.badgeBlue;
    }
  }

  IconData _statusIcon(WorkOrderStatus s) {
    switch (s) {
      case WorkOrderStatus.inProgress:
        return Icons.build_circle;
      case WorkOrderStatus.completed:
        return Icons.check_circle;
      case WorkOrderStatus.cancelled:
        return Icons.cancel;
      case WorkOrderStatus.planned:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(fleetRepositoryProvider);

    return Scaffold(
      appBar: const AppHeader(),
      drawer: const CustomDrawer(currentRoute: '/maintenance'),
      body: FutureBuilder<PaginatedResult<TwendeVehicle>>(
        future: repo.getVehicles(),
        builder: (context, snapshot) {
          final vehicles = snapshot.data?.items ?? [];
          final underMaintenance =
              vehicles.where((v) => v.status == VehicleStatus.underMaintenance).toList();

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
                        const Icon(Icons.build, color: Colors.black, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'Maintenance',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () => _showNewWorkOrderDialog(context, vehicles),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New WO'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Summary chips
                    Row(
                      children: [
                        _SummaryChip(
                          label: 'Under Maint.',
                          count: underMaintenance.length,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        _SummaryChip(
                          label: 'Open WO',
                          count: _mockWorkOrders
                              .where((w) =>
                                  w.status == WorkOrderStatus.planned ||
                                  w.status == WorkOrderStatus.inProgress)
                              .length,
                          color: AppColors.badgeBlue,
                        ),
                        const SizedBox(width: 8),
                        _SummaryChip(
                          label: 'Completed',
                          count: _mockWorkOrders
                              .where((w) => w.status == WorkOrderStatus.completed)
                              .length,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TabBar(
                      controller: _tab,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      tabs: const [
                        Tab(text: 'Work Orders'),
                        Tab(text: 'Schedule'),
                        Tab(text: 'History'),
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
                    hintText: 'Search vehicle, type, mechanic…',
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
              // Content
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _WorkOrderList(
                      orders: _mockWorkOrders
                          .where((w) =>
                              _search.isEmpty ||
                              w.vehiclePlate.toLowerCase().contains(_search) ||
                              w.type.toLowerCase().contains(_search) ||
                              w.assignedTo.toLowerCase().contains(_search))
                          .where((w) =>
                              w.status == WorkOrderStatus.planned ||
                              w.status == WorkOrderStatus.inProgress)
                          .toList(),
                      statusColor: _statusColor,
                      statusIcon: _statusIcon,
                    ),
                    _ScheduleTab(vehicles: underMaintenance),
                    _WorkOrderList(
                      orders: _mockWorkOrders
                          .where((w) =>
                              _search.isEmpty ||
                              w.vehiclePlate.toLowerCase().contains(_search) ||
                              w.type.toLowerCase().contains(_search) ||
                              w.assignedTo.toLowerCase().contains(_search))
                          .where((w) =>
                              w.status == WorkOrderStatus.completed ||
                              w.status == WorkOrderStatus.cancelled)
                          .toList(),
                      statusColor: _statusColor,
                      statusIcon: _statusIcon,
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

  void _showNewWorkOrderDialog(BuildContext context, List<TwendeVehicle> vehicles) {
    String? selectedPlate;
    final typeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final mechCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Work Order',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: StatefulBuilder(
          builder: (context, setS) => SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedPlate,
                  hint: const Text('Select vehicle'),
                  decoration: const InputDecoration(
                    labelText: 'Vehicle',
                    border: OutlineInputBorder(),
                  ),
                  items: vehicles
                      .map((v) => DropdownMenuItem(value: v.plateNumber, child: Text(v.plateNumber)))
                      .toList(),
                  onChanged: (v) => setS(() => selectedPlate = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: typeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Maintenance Type',
                    hintText: 'e.g. Oil Change, Tyre Rotation',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mechCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Mechanic',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (selectedPlate == null || typeCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a vehicle and enter a type.')),
                );
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Work order created for $selectedPlate — ${typeCtrl.text.trim()}')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// ── Mock Work Order Data ────────────────────────────────────────────────────

class _WorkOrderData {
  final String id;
  final String vehiclePlate;
  final String type;
  final String description;
  final String assignedTo;
  final WorkOrderStatus status;
  final DateTime scheduledDate;
  final int estimatedHours;
  final int estimatedCostRwf;

  const _WorkOrderData({
    required this.id,
    required this.vehiclePlate,
    required this.type,
    required this.description,
    required this.assignedTo,
    required this.status,
    required this.scheduledDate,
    required this.estimatedHours,
    required this.estimatedCostRwf,
  });
}

final _mockWorkOrders = [
  _WorkOrderData(
    id: 'WO-001',
    vehiclePlate: 'RAC 123A',
    type: 'Oil Change & Filter',
    description: '40,000 km scheduled service. Replace engine oil (5W-30), oil filter, air filter.',
    assignedTo: 'Jean-Pierre M.',
    status: WorkOrderStatus.inProgress,
    scheduledDate: DateTime.now().subtract(const Duration(days: 1)),
    estimatedHours: 2,
    estimatedCostRwf: 45000,
  ),
  _WorkOrderData(
    id: 'WO-002',
    vehiclePlate: 'RAD 456B',
    type: 'Brake Inspection & Pad Replacement',
    description: 'Front brake pads worn below 3mm. Replace front pads and inspect rotors.',
    assignedTo: 'David K.',
    status: WorkOrderStatus.planned,
    scheduledDate: DateTime.now().add(const Duration(days: 2)),
    estimatedHours: 3,
    estimatedCostRwf: 85000,
  ),
  _WorkOrderData(
    id: 'WO-003',
    vehiclePlate: 'RAE 789C',
    type: 'Tyre Rotation & Alignment',
    description: 'Rotate all 4 tyres, check alignment and balance.',
    assignedTo: 'Jean-Pierre M.',
    status: WorkOrderStatus.planned,
    scheduledDate: DateTime.now().add(const Duration(days: 4)),
    estimatedHours: 2,
    estimatedCostRwf: 30000,
  ),
  _WorkOrderData(
    id: 'WO-004',
    vehiclePlate: 'RAB 321D',
    type: 'AC Compressor Replacement',
    description: 'AC not cooling. Diagnosed faulty compressor. Replace and re-gas.',
    assignedTo: 'Patrick N.',
    status: WorkOrderStatus.completed,
    scheduledDate: DateTime.now().subtract(const Duration(days: 5)),
    estimatedHours: 6,
    estimatedCostRwf: 320000,
  ),
  _WorkOrderData(
    id: 'WO-005',
    vehiclePlate: 'RAF 654E',
    type: '60,000 km Major Service',
    description: 'Spark plugs, timing belt, coolant flush, transmission fluid change.',
    assignedTo: 'David K.',
    status: WorkOrderStatus.completed,
    scheduledDate: DateTime.now().subtract(const Duration(days: 10)),
    estimatedHours: 8,
    estimatedCostRwf: 480000,
  ),
];

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class _WorkOrderList extends StatelessWidget {
  final List<_WorkOrderData> orders;
  final Color Function(WorkOrderStatus) statusColor;
  final IconData Function(WorkOrderStatus) statusIcon;

  const _WorkOrderList({
    required this.orders,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_outlined, size: 48, color: Colors.black),
            SizedBox(height: 12),
            Text('No work orders', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final wo = orders[i];
        final color = statusColor(wo.status);
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        wo.id,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon(wo.status), size: 12, color: color),
                          const SizedBox(width: 4),
                          Text(
                            wo.status.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(wo.scheduledDate),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  wo.type,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  wo.description,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 14, color: Colors.black),
                    const SizedBox(width: 4),
                    Text(
                      wo.vehiclePlate,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.person_outline, size: 14, color: Colors.black),
                    const SizedBox(width: 4),
                    Text(
                      wo.assignedTo,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    const Icon(Icons.schedule, size: 14, color: Colors.black),
                    const SizedBox(width: 4),
                    Text(
                      '${wo.estimatedHours}h',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'RWF ${_fmt(wo.estimatedCostRwf)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
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
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmt(int v) {
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(0)}k';
    }
    return '$v';
  }
}

class _ScheduleTab extends StatelessWidget {
  final List<TwendeVehicle> vehicles;

  const _ScheduleTab({required this.vehicles});

  @override
  Widget build(BuildContext context) {
    if (vehicles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 48, color: Colors.black),
            SizedBox(height: 12),
            Text('All vehicles operational', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: vehicles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final v = vehicles[i];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          color: AppColors.warning.withValues(alpha: 0.04),
          child: ListTile(
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.build, color: Colors.black, size: 22),
            ),
            title: Text(
              v.plateNumber,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: Text(
              '${v.make} ${v.model} • Under Maintenance',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.black),
          ),
        );
      },
    );
  }
}
