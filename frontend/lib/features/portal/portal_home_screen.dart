// lib/features/portal/portal_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money_utils.dart';

class PortalHomeScreen extends ConsumerStatefulWidget {
  const PortalHomeScreen({super.key});

  @override
  ConsumerState<PortalHomeScreen> createState() => _PortalHomeScreenState();
}

class _PortalHomeScreenState extends ConsumerState<PortalHomeScreen> {
  String _selectedBranch = 'Kigali HQ';
  DateTime _pickupDate = DateTime.now().add(const Duration(days: 1, hours: 2));
  DateTime _returnDate = DateTime.now().add(const Duration(days: 4, hours: 2));

  final List<String> _branches = [
    'Kigali HQ',
    'Kigali International Airport',
    'Rubavu (Gisenyi) Branch',
    'Huye (Butare) Branch',
    'Musanze (Ruhengeri) Branch',
  ];

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'suv',
      'name': 'SUV & Crossover',
      'models': 'Toyota RAV4, Prado TX',
      'seats': 5,
      'luggage': 3,
      'transmission': 'Automatic',
      'dailyRate': 75000,
      'weeklyRate': 375000,
      'deposit': 200000,
      'image': 'assets/images/mock_suv.png',
      'badge': 'Most Popular',
    },
    {
      'id': 'sedan',
      'name': 'Economy Sedan',
      'models': 'Toyota Corolla, Yaris',
      'seats': 5,
      'luggage': 2,
      'transmission': 'Automatic',
      'dailyRate': 50000,
      'weeklyRate': 250000,
      'deposit': 150000,
      'image': 'assets/images/mock_sedan.png',
      'badge': 'Best Value',
    },
    {
      'id': 'van',
      'name': 'Passenger Van & Minibus',
      'models': 'Toyota HiAce (14 Seater)',
      'seats': 14,
      'luggage': 6,
      'transmission': 'Manual',
      'dailyRate': 90000,
      'weeklyRate': 450000,
      'deposit': 250000,
      'image': 'assets/images/mock_van.png',
      'badge': 'Group Travel',
    },
    {
      'id': 'truck',
      'name': 'Commercial Truck & 4x4',
      'models': 'Isuzu Forward, Hilux Double Cab',
      'seats': 3,
      'luggage': 10,
      'transmission': 'Manual',
      'dailyRate': 140000,
      'weeklyRate': 700000,
      'deposit': 350000,
      'image': 'assets/images/mock_truck.png',
      'badge': 'Heavy Duty',
    },
  ];

  int get _rentalDays {
    final diff = _returnDate.difference(_pickupDate);
    final days = (diff.inHours / 24).ceil();
    return days <= 0 ? 1 : days;
  }

  Future<void> _pickDate({required bool isPickup}) async {
    final initialDate = isPickup ? _pickupDate : _returnDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupDate = DateTime(picked.year, picked.month, picked.day, 9, 0);
          if (_returnDate.isBefore(_pickupDate.add(const Duration(days: 1)))) {
            _returnDate = _pickupDate.add(const Duration(days: 3));
          }
        } else {
          _returnDate = DateTime(picked.year, picked.month, picked.day, 18, 0);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMM yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'twende.',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Customer Portal',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/portal/documents'),
            icon: const Icon(Icons.folder_shared_outlined, color: Colors.black, size: 18),
            label: const Text('My Docs', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.black),
            tooltip: 'Sign In / Staff Portal',
            onPressed: () => context.push('/sign-in'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Hero Search Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Book Your Rental in Rwanda',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Transparent pricing · Instant MoMo checkout · Verified vehicles',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Search Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Branch Selector
                        DropdownButtonFormField<String>(
                          initialValue: _selectedBranch,
                          decoration: InputDecoration(
                            labelText: 'Pickup & Return Branch',
                            prefixIcon: const Icon(Icons.location_on, color: Colors.black),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: _branches.map((b) {
                            return DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedBranch = val);
                          },
                        ),

                        const SizedBox(height: 12),

                        // Dates Row
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickDate(isPickup: true),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Pickup Date',
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateFormat.format(_pickupDate),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickDate(isPickup: false),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Return Date',
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateFormat.format(_returnDate),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Rolling Quote Duration Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEEEE4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 16, color: Colors.black),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Rental Duration: $_rentalDays ${_rentalDays == 1 ? "day" : "days"}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              if (_rentalDays >= 6)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Weekly Cap Applied',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Value proposition pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildTrustPill(Icons.verified, 'Full Insurance'),
                  const SizedBox(width: 8),
                  _buildTrustPill(Icons.phone_android, 'Instant MoMo Push'),
                  const SizedBox(width: 8),
                  _buildTrustPill(Icons.history_toggle_off, 'Free Cancel 24h'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Category Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Vehicle Classes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._categories.map((cat) => _buildCategoryCard(cat)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Remote Quick Actions (Sign & Pay Token Links)
            _buildQuickLinksSection(),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustPill(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: Colors.black),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat) {
    final dailyRate = cat['dailyRate'] as int;
    final weeklyRate = cat['weeklyRate'] as int;
    final deposit = cat['deposit'] as int;

    // Apply weekly cap calculation logic from SRS 8.1
    int calculatedTotal;
    if (_rentalDays >= 7) {
      final weeks = _rentalDays ~/ 7;
      final extraDays = _rentalDays % 7;
      calculatedTotal = (weeks * weeklyRate) + (extraDays * dailyRate);
    } else if (_rentalDays >= 6) {
      // 6 days is capped at 1 week rate
      calculatedTotal = weeklyRate;
    } else {
      calculatedTotal = _rentalDays * dailyRate;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
          // Card Header with Badge
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat['name'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        cat['models'] as String,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    cat['badge'] as String,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle Specs Row
                Row(
                  children: [
                    _buildSpecChip(Icons.person, '${cat["seats"]} Seats'),
                    const SizedBox(width: 8),
                    _buildSpecChip(Icons.luggage, '${cat["luggage"]} Bags'),
                    const SizedBox(width: 8),
                    _buildSpecChip(Icons.settings, cat['transmission'] as String),
                  ],
                ),

                const Divider(height: 24),

                // Pricing Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${MoneyUtils.formatRwf(dailyRate)} / day',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Deposit: ${MoneyUtils.formatRwf(deposit)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            MoneyUtils.formatRwf(calculatedTotal),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Total for $_rentalDays ${_rentalDays == 1 ? "day" : "days"} (incl. VAT)',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: () {
                      context.push(
                        '/portal/book',
                        extra: {
                          'category': cat['name'],
                          'categoryId': cat['id'],
                          'branch': _selectedBranch,
                          'pickupDate': _pickupDate.toIso8601String(),
                          'returnDate': _returnDate.toIso8601String(),
                          'dailyRate': dailyRate,
                          'deposit': deposit,
                        },
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Book This Class',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildQuickLinksSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
              'Remote Customer Access Links',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Already received a SMS / WhatsApp booking token? Open directly:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/portal/sign/demo-token-123'),
                    icon: const Icon(Icons.draw, size: 16),
                    label: const Text('Sign Contract', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/portal/pay/demo-token-123'),
                    icon: const Icon(Icons.payment, size: 16),
                    label: const Text('Pay Online', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
