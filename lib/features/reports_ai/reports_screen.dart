// lib/features/reports_ai/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_header.dart';
import '../../core/widgets/kpi_card.dart';
import '../../widgets/custom_drawer.dart';
import '../../shared/repositories/mock_repositories.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _period = 'This Month';
  final List<String> _periods = ['Today', 'This Week', 'This Month', 'This Quarter', 'This Year'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashRepo = ref.watch(dashboardRepositoryProvider);

    return Scaffold(
      appBar: const AppHeader(),
      drawer: const CustomDrawer(currentRoute: '/reports'),
      body: FutureBuilder(
        future: dashRepo.getKpis(),
        builder: (context, snap) {
          final kpis = snap.data;

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
                        const Icon(Icons.bar_chart, color: Colors.black, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'Reports & Analytics',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        // Period selector
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _period,
                              isDense: true,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              items: _periods
                                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _period = v);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Exporting report as PDF…')),
                            );
                          },
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Export', style: TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TabBar(
                      controller: _tab,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Fleet Utilization'),
                        Tab(text: 'Revenue'),
                        Tab(text: 'Customers'),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _OverviewTab(kpis: kpis, period: _period),
                    _FleetUtilizationTab(period: _period),
                    _RevenueTab(period: _period),
                    _CustomersTab(period: _period),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final dynamic kpis;
  final String period;

  const _OverviewTab({required this.kpis, required this.period});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Metrics — $period',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              KpiCard(
                label: 'Total Revenue',
                value: kpis != null ? 'RWF ${_fmt(kpis.totalRevenueRwf)}' : '—',
                icon: Icons.payments,
                accent: AppColors.success,
                subLabel: '+12% vs prev',
              ),
              KpiCard(
                label: 'Active Rentals',
                value: kpis != null ? '${kpis.activeRentals}' : '—',
                icon: Icons.directions_car,
                accent: AppColors.primary,
              ),
              KpiCard(
                label: 'Fleet Utilization',
                value: kpis != null ? '${(kpis.fleetUtilizationPct).toStringAsFixed(0)}%' : '—',
                icon: Icons.pie_chart,
                accent: AppColors.warning,
              ),
              const KpiCard(
                label: 'Avg Booking Value',
                value: 'RWF 185k',
                icon: Icons.trending_up,
                accent: AppColors.badgeBlue,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionHeader('Revenue Breakdown'),
          const SizedBox(height: 10),
          const _RevenueBreakdown(),
          const SizedBox(height: 20),
          const _SectionHeader('Recent Performance'),
          const SizedBox(height: 10),
          const _PerformanceTable(),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}

// ── Fleet Utilization Tab ────────────────────────────────────────────────────

class _FleetUtilizationTab extends StatelessWidget {
  final String period;
  const _FleetUtilizationTab({required this.period});

  @override
  Widget build(BuildContext context) {
    final data = [
      _UtilData('RAC 123A', 'Toyota Land Cruiser', 85, 18),
      _UtilData('RAD 456B', 'Toyota Hilux', 72, 15),
      _UtilData('RAE 789C', 'Nissan Patrol', 68, 14),
      _UtilData('RAB 321D', 'Mitsubishi Pajero', 55, 12),
      _UtilData('RAF 654E', 'Toyota Prado', 90, 19),
      _UtilData('RAG 987F', 'Ford Ranger', 40, 9),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fleet Utilization — $period',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(
            '${data.where((d) => d.utilPct >= 70).length} of ${data.length} vehicles above 70% utilization',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          ...data.map((d) => _UtilCard(data: d)),
          const SizedBox(height: 16),
          const _SectionHeader('Idle Fleet Analysis'),
          const SizedBox(height: 10),
          _IdleAnalysisCard(vehicles: data.where((d) => d.utilPct < 60).toList()),
        ],
      ),
    );
  }
}

class _UtilData {
  final String plate;
  final String name;
  final int utilPct;
  final int daysRented;
  _UtilData(this.plate, this.name, this.utilPct, this.daysRented);
}

class _UtilCard extends StatelessWidget {
  final _UtilData data;
  const _UtilCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final color = data.utilPct >= 70
        ? AppColors.success
        : data.utilPct >= 50
            ? AppColors.warning
            : AppColors.error;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
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
                Text(data.plate,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(width: 8),
                Text(data.name,
                    style:
                        const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const Spacer(),
                Text(
                  '${data.daysRented} days',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 10),
                Text(
                  '${data.utilPct}%',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: data.utilPct / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdleAnalysisCard extends StatelessWidget {
  final List<_UtilData> vehicles;
  const _IdleAnalysisCard({required this.vehicles});

  @override
  Widget build(BuildContext context) {
    if (vehicles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.black, size: 20),
            SizedBox(width: 10),
            Text('All vehicles are well-utilized',
                style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${vehicles.length} vehicle(s) below 60% utilization',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.warning),
          ),
          const SizedBox(height: 8),
          ...vehicles.map((v) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.black),
                    const SizedBox(width: 8),
                    Text('${v.plate} — ${v.utilPct}% (${v.daysRented} days)',
                        style:
                            const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          const Text(
            '💡 Consider promotional rates or corporate partnerships to improve utilization.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Revenue Tab ───────────────────────────────────────────────────────────────

class _RevenueTab extends StatelessWidget {
  final String period;
  const _RevenueTab({required this.period});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenue Breakdown — $period',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          const _RevenueBreakdown(),
          const SizedBox(height: 20),
          const _SectionHeader('Payment Methods'),
          const SizedBox(height: 10),
          const _PaymentMixCard(),
          const SizedBox(height: 20),
          const _SectionHeader('Top Revenue Vehicles'),
          const SizedBox(height: 10),
          const _TopVehiclesTable(),
        ],
      ),
    );
  }
}

// ── Customers Tab ─────────────────────────────────────────────────────────────

class _CustomersTab extends StatelessWidget {
  final String period;
  const _CustomersTab({required this.period});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Analytics — $period',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'New Customers',
                  value: '24',
                  change: '+6 vs prev',
                  positive: true,
                  icon: Icons.person_add,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Returning',
                  value: '67%',
                  change: '+3% vs prev',
                  positive: true,
                  icon: Icons.replay,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Avg Bookings/Customer',
                  value: '2.3',
                  change: '+0.2 vs prev',
                  positive: true,
                  icon: Icons.bar_chart,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Blacklisted',
                  value: '2',
                  change: 'No change',
                  positive: null,
                  icon: Icons.block,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionHeader('Customer Type Mix'),
          const SizedBox(height: 10),
          const _CustomerTypeMix(),
          const SizedBox(height: 20),
          const _SectionHeader('Top Customers by Revenue'),
          const SizedBox(height: 10),
          const _TopCustomersTable(),
        ],
      ),
    );
  }
}

// ── Shared Components ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _RevenueBreakdown extends StatelessWidget {
  const _RevenueBreakdown();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Base Rental Fees', 68.0, AppColors.primary),
      ('Mileage Charges', 12.0, AppColors.warning),
      ('Late Return Fees', 8.0, AppColors.error),
      ('Fuel Charges', 7.0, AppColors.badgeBlue),
      ('Other / Add-ons', 5.0, AppColors.textSecondary),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.$3,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item.$1,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  ),
                  SizedBox(
                    width: 180,
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: item.$2 / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(item.$3),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 36,
                          child: Text(
                            '${item.$2.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: item.$3,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PerformanceTable extends StatelessWidget {
  const _PerformanceTable();

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Nov 2026', 'RWF 4.2M', '89%', '34', '+12%'),
      ('Oct 2026', 'RWF 3.7M', '78%', '29', '+8%'),
      ('Sep 2026', 'RWF 3.1M', '72%', '25', '+3%'),
      ('Aug 2026', 'RWF 3.0M', '70%', '24', '—'),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(1.5),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1.5),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade50),
            children: ['Period', 'Revenue', 'Util.', 'Rentals', 'Growth']
                .map((h) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(h,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary)),
                    ))
                .toList(),
          ),
          ...rows.map((r) => TableRow(
                children: [r.$1, r.$2, r.$3, r.$4, r.$5]
                    .map((v) => Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Text(v,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textPrimary)),
                        ))
                    .toList(),
              )),
        ],
      ),
    );
  }
}

class _PaymentMixCard extends StatelessWidget {
  const _PaymentMixCard();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('MoMo MTN', 42.0, AppColors.warning),
      ('Bank Transfer', 31.0, AppColors.badgeBlue),
      ('Cash', 18.0, AppColors.success),
      ('Card', 6.0, AppColors.primary),
      ('Airtel Money', 3.0, AppColors.error),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: item.$3.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: item.$3.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: item.$3, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('${item.$1} ${item.$2.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: item.$3)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TopVehiclesTable extends StatelessWidget {
  const _TopVehiclesTable();

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('RAF 654E', 'Toyota Prado', 'RWF 920k', '19 days', '90%'),
      ('RAC 123A', 'Toyota Land Cruiser', 'RWF 850k', '18 days', '85%'),
      ('RAD 456B', 'Toyota Hilux', 'RWF 650k', '15 days', '72%'),
      ('RAE 789C', 'Nissan Patrol', 'RWF 610k', '14 days', '68%'),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.5),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(1.5),
          4: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade50),
            children: ['Plate', 'Model', 'Revenue', 'Days Out', 'Util.']
                .map((h) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(h,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    ))
                .toList(),
          ),
          ...rows.map((r) => TableRow(
                children: [r.$1, r.$2, r.$3, r.$4, r.$5]
                    .map((v) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Text(v, style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
              )),
        ],
      ),
    );
  }
}

class _CustomerTypeMix extends StatelessWidget {
  const _CustomerTypeMix();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Corporate', 48, AppColors.primary),
      ('Individual', 28, AppColors.badgeBlue),
      ('Government', 15, AppColors.success),
      ('NGO / Embassy', 9, AppColors.warning),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: item.$3, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  SizedBox(width: 100, child: Text(item.$1, style: const TextStyle(fontSize: 13))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: item.$2 / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(item.$3),
                        minHeight: 7,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${item.$2}%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: item.$3)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TopCustomersTable extends StatelessWidget {
  const _TopCustomersTable();

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Rwanda Dev. Board', 'Government', 'RWF 1.2M', '6'),
      ('MTN Rwanda', 'Corporate', 'RWF 980k', '5'),
      ('WFP Rwanda', 'NGO', 'RWF 870k', '4'),
      ('Jean-Baptiste M.', 'Individual', 'RWF 420k', '3'),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.5),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade50),
            children: ['Customer', 'Type', 'Revenue', 'Bookings']
                .map((h) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(h,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    ))
                .toList(),
          ),
          ...rows.map((r) => TableRow(
                children: [r.$1, r.$2, r.$3, r.$4]
                    .map((v) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Text(v, style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
              )),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  final bool? positive;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.change,
    required this.positive,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final changeColor = positive == null
        ? AppColors.textSecondary
        : positive!
            ? AppColors.success
            : AppColors.error;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.black),
                const Spacer(),
                Text(change, style: TextStyle(fontSize: 11, color: changeColor)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
