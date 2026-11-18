// lib/features/rates/rates_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money_utils.dart';
import '../../widgets/app_header.dart';
import '../../widgets/custom_drawer.dart';

class RatesScreen extends StatefulWidget {
  const RatesScreen({super.key});

  @override
  State<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends State<RatesScreen> {
  // Calculator state
  String _calcCategory = 'SUV';
  int _calcDays = 6;
  int _calcKm = 1400; // 200km/day * 6 = 1200, so 200 excess km
  bool _includeDriver = false;

  final Map<String, Map<String, dynamic>> _ratePlans = {
    'SUV': {
      'daily': 75000,
      'weekly': 375000,
      'monthly': 1500000,
      'kmAllowance': 200,
      'excessKmRate': 150,
      'models': 'Toyota RAV4, Land Cruiser Prado',
      'deposit': 200000,
    },
    'Sedan': {
      'daily': 50000,
      'weekly': 250000,
      'monthly': 1000000,
      'kmAllowance': 200,
      'excessKmRate': 120,
      'models': 'Toyota Corolla, Yaris, Mercedes C200',
      'deposit': 150000,
    },
    'Van': {
      'daily': 90000,
      'weekly': 450000,
      'monthly': 1800000,
      'kmAllowance': 200,
      'excessKmRate': 180,
      'models': 'Toyota HiAce (14-seater minibus)',
      'deposit': 250000,
    },
    'Truck': {
      'daily': 140000,
      'weekly': 700000,
      'monthly': 2800000,
      'kmAllowance': 250,
      'excessKmRate': 250,
      'models': 'Isuzu Forward 10T, Scania Tipper',
      'deposit': 350000,
    },
  };

  final List<Map<String, dynamic>> _aiSuggestions = [
    {
      'title': 'High Weekend Tourism Demand',
      'route': 'Musanze / Volcanoes National Park',
      'recommendation': '+15% dynamic surge on SUV & 4x4 classes',
      'reason': 'Historical occupancy 94% on Fri–Sun. Competitor fleet rates up by 18%.',
      'active': true,
    },
    {
      'title': 'Low Commercial Van Midweek Utilization',
      'route': 'Kigali City Local Logistics',
      'recommendation': '-10% midweek discount for 3+ day van rentals',
      'reason': 'Fleet idle rate at 40% between Tuesday and Thursday.',
      'active': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final plan = _ratePlans[_calcCategory]!;
    final dailyRate = plan['daily'] as int;
    final weeklyRate = plan['weekly'] as int;
    final kmAllowancePerDay = plan['kmAllowance'] as int;
    final excessKmRate = plan['excessKmRate'] as int;

    // SRS 8.1 Cap Logic
    int baseRentalCost;
    if (_calcDays >= 7) {
      final weeks = _calcDays ~/ 7;
      final remDays = _calcDays % 7;
      baseRentalCost = (weeks * weeklyRate) + (remDays * dailyRate);
    } else if (_calcDays >= 6) {
      baseRentalCost = weeklyRate; // 6 days capped at weekly rate
    } else {
      baseRentalCost = _calcDays * dailyRate;
    }

    final totalKmAllowance = kmAllowancePerDay * _calcDays;
    final excessKm = (_calcKm - totalKmAllowance).clamp(0, 999999);
    final excessKmCost = excessKm * excessKmRate;
    final driverCost = _includeDriver ? 20000 * _calcDays : 0;
    final subtotal = baseRentalCost + excessKmCost + driverCost;
    final vat = (subtotal * 0.18).round();
    final grandTotal = subtotal + vat;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: const AppHeader(title: 'Rates & Pricing Tariffs'),
      drawer: const CustomDrawer(currentRoute: '/rates'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate Plans & Tariffs (SRS 8.1)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Active category tariffs, weekly cap rules, and dynamic price preview',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rate card export generated in PDF & Excel.')),
                    );
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Export Rates'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 1. Interactive Pricing Engine Preview Calculator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.secondary, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.calculate, color: Colors.black, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Flexible(
                            child: Text(
                              'Live Tariff Preview Calculator',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SRS 8.1 Engine Verified',
                          style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Category Selector Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _ratePlans.keys.map((cat) {
                      final isSelected = _calcCategory == cat;
                      return ChoiceChip(
                        label: Text(cat, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.primary)),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.grey.shade100,
                        onSelected: (val) {
                          if (val) setState(() => _calcCategory = cat);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  // Sliders: Days and KM
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 450;
                      if (isNarrow) {
                        return Column(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Duration: $_calcDays Days',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                Slider(
                                  value: _calcDays.toDouble(),
                                  min: 1,
                                  max: 35,
                                  divisions: 34,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) => setState(() => _calcDays = val.toInt()),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimated Travel: $_calcKm km',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                Slider(
                                  value: _calcKm.toDouble(),
                                  min: 100,
                                  max: 4000,
                                  divisions: 39,
                                  activeColor: AppColors.secondary,
                                  onChanged: (val) => setState(() => _calcKm = val.toInt()),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Duration: $_calcDays Days',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                Slider(
                                  value: _calcDays.toDouble(),
                                  min: 1,
                                  max: 35,
                                  divisions: 34,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) => setState(() => _calcDays = val.toInt()),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimated Travel: $_calcKm km',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                Slider(
                                  value: _calcKm.toDouble(),
                                  min: 100,
                                  max: 4000,
                                  divisions: 39,
                                  activeColor: AppColors.secondary,
                                  onChanged: (val) => setState(() => _calcKm = val.toInt()),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // Optional Driver
                  SwitchListTile(
                    value: _includeDriver,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.primary,
                    title: const Text('Include Dedicated Driver (+RWF 20,000/day)', style: TextStyle(fontSize: 13)),
                    onChanged: (val) => setState(() => _includeDriver = val),
                  ),

                  const Divider(height: 20),

                  // Calculated Output Grid
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('Base Rate for $_calcDays days:', style: const TextStyle(fontSize: 13))),
                            Text(
                              MoneyUtils.formatRwf(baseRentalCost),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        if (_calcDays == 6)
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text('↳ 6-day cap rule applied (equal to 1 week price)', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                                ),
                                SizedBox(width: 8),
                                Text('Capped', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('Mileage (${totalKmAllowance}km included, ${excessKm}km excess):', style: const TextStyle(fontSize: 13))),
                            Text(
                              MoneyUtils.formatRwf(excessKmCost),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        if (_includeDriver) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text('Chauffeur fee ($_calcDays days):', style: const TextStyle(fontSize: 13))),
                              Text(MoneyUtils.formatRwf(driverCost), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(child: Text('VAT (18%):', style: TextStyle(fontSize: 13))),
                            Text(MoneyUtils.formatRwf(vat), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(child: Text('Total Estimated Quote:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary))),
                            Text(
                              MoneyUtils.formatRwf(grandTotal),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Active Rate Plans Table
            const Text(
              'Active Category Rate Cards',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),

            ..._ratePlans.keys.map((cat) {
              final item = _ratePlans[cat]!;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '$cat Class (${item["models"]})',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${MoneyUtils.formatRwf(item["daily"] as int)} / day',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text('Weekly Cap: ${MoneyUtils.formatRwf(item["weekly"] as int)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('Monthly: ${MoneyUtils.formatRwf(item["monthly"] as int)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('Deposit: ${MoneyUtils.formatRwf(item["deposit"] as int)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Allowance: ${item["kmAllowance"]} km/day included • Excess: ${MoneyUtils.formatRwf(item["excessKmRate"] as int)}/km',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // 3. AI Dynamic Pricing Suggestions (AI-05)
            const Text(
              'AI Smart Pricing Insights (AI-05)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),

            ..._aiSuggestions.map((s) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEEEE4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
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
                              const Icon(Icons.auto_awesome, color: Colors.black, size: 18),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  s['title'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('AI Recommendation', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s['recommendation'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s['reason'] as String,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
