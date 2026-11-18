// lib/features/damage/damage_incidents_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money_utils.dart';
import '../../widgets/app_header.dart';
import '../../widgets/custom_drawer.dart';

class DamageIncidentsScreen extends ConsumerStatefulWidget {
  const DamageIncidentsScreen({super.key});

  @override
  ConsumerState<DamageIncidentsScreen> createState() => _DamageIncidentsScreenState();
}

class _DamageIncidentsScreenState extends ConsumerState<DamageIncidentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _damageRecords = [
    {
      'id': 'DMG-0104',
      'contractId': 'RC-0231',
      'vehiclePlate': 'RAF 789 T',
      'vehicleName': 'Scania R500 Tipper',
      'customerName': 'Cimerwa Cement Ltd',
      'type': 'Scratch & Dent',
      'component': 'Rear Left Bumper',
      'costEstimate': 145000,
      'status': 'Under Assessment',
      'date': 'Yesterday, 16:40',
      'liability': 'Customer Liability',
      'charged': false,
    },
    {
      'id': 'DMG-0098',
      'contractId': 'RC-0220',
      'vehiclePlate': 'RAC 123 B',
      'vehicleName': 'Toyota RAV4',
      'customerName': 'Robert Mugisha',
      'type': 'Windshield Crack',
      'component': 'Front Windshield',
      'costEstimate': 280000,
      'status': 'Under Repair',
      'date': '12 Nov 2026',
      'liability': 'Insurance Claim',
      'charged': false,
    },
    {
      'id': 'DMG-0087',
      'contractId': 'RC-0215',
      'vehiclePlate': 'RAD 456 C',
      'vehicleName': 'Toyota Hilux',
      'customerName': 'MTN Rwanda Logistics',
      'type': 'Side Mirror Broken',
      'component': 'Right Wing Mirror',
      'costEstimate': 65000,
      'status': 'Customer Charged',
      'date': '08 Nov 2026',
      'liability': 'Customer Liability',
      'charged': true,
    },
  ];

  final List<Map<String, dynamic>> _trafficFines = [
    {
      'id': 'FINE-8841',
      'plate': 'RAC 123 B',
      'vehicleName': 'Toyota RAV4',
      'offence': 'Speeding (78 km/h in 60 km/h zone)',
      'location': 'Kigali - RN3 Gatuna Highway (Speed Camera #04)',
      'timestamp': '14 Nov 2026 · 14:22',
      'amount': 50000,
      'matchedContract': 'RC-0225 (Aline Uwase)',
      'matchedDriver': 'Aline Uwase (0788556677)',
      'status': 'Ready to Recharge',
    },
    {
      'id': 'FINE-8839',
      'plate': 'RAD 456 C',
      'vehicleName': 'Toyota Hilux',
      'offence': 'Red Light Infraction',
      'location': 'Kigali City Center (KN 3 Rd Junction)',
      'timestamp': '11 Nov 2026 · 09:15',
      'amount': 25000,
      'matchedContract': 'RC-0220 (MTN Rwanda)',
      'matchedDriver': 'Jean Habimana',
      'status': 'Recharged & Invoiced',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Reported':
      case 'Under Assessment':
        return AppColors.secondary;
      case 'Under Repair':
        return AppColors.badgeBlue;
      case 'Insurance Claim':
        return const Color(0xFF673AB7);
      case 'Customer Charged':
      case 'Repaired':
      case 'Closed':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: const AppHeader(title: 'Damage & Incidents'),
      drawer: const CustomDrawer(currentRoute: '/damage'),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    const Text(
                      'Damage & Incident Claims (DMG-02)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening new damage claim wizard...')),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Report Damage'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  tabs: [
                    Tab(text: 'Damage Records (${_damageRecords.length})'),
                    Tab(text: 'Traffic Fine Re-Billing (${_trafficFines.length})'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDamageRecordsList(),
                _buildTrafficFinesList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Damage Records Tab
  // ---------------------------------------------------------------------------
  Widget _buildDamageRecordsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _damageRecords.length,
      itemBuilder: (context, index) {
        final dmg = _damageRecords[index];
        final statusColor = _statusColor(dmg['status'] as String);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          dmg['id'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '• ${dmg["vehiclePlate"]}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      dmg['status'] as String,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${dmg["type"]} on ${dmg["component"]}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
              ),
              Text(
                'Customer: ${dmg["customerName"]} · Contract: ${dmg["contractId"]}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Divider(height: 18),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estimated Cost:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text(
                        MoneyUtils.formatRwf(dmg['costEstimate'] as int),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.error),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (!(dmg['charged'] as bool))
                        OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Charge request submitted to approval inbox for ${dmg["id"]}.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text('Charge Customer', style: TextStyle(fontSize: 12)),
                        ),
                      FilledButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Opening inspection diagram for ${dmg["id"]}...')),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text('View Claim', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Traffic Fines Re-Billing Tab (DMG-04)
  // ---------------------------------------------------------------------------
  Widget _buildTrafficFinesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _trafficFines.length,
      itemBuilder: (context, index) {
        final fine = _trafficFines[index];
        final isReady = fine['status'] == 'Ready to Recharge';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isReady ? AppColors.error.withValues(alpha: 0.3) : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.videocam_outlined, color: Colors.black, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          fine['id'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '• ${fine["plate"]}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isReady
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      fine['status'] as String,
                      style: TextStyle(
                        color: isReady ? AppColors.error : AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                fine['offence'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
              ),
              Text(
                fine['location'] as String,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                'Recorded Time: ${fine["timestamp"]}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Auto-Matched Rental (DMG-04):', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      '${fine["matchedContract"]} · Driver: ${fine["matchedDriver"]}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const Divider(height: 18),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Statutory Fine Amount:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text(
                        MoneyUtils.formatRwf(fine['amount'] as int),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.error),
                      ),
                    ],
                  ),
                  if (isReady)
                    FilledButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Fine ${fine["id"]} recharged to customer invoice!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_outlined, size: 14),
                      label: const Text('Recharge Customer', style: TextStyle(fontSize: 12)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
