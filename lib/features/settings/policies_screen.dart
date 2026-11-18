// lib/features/settings/policies_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_header.dart';
import '../../widgets/custom_drawer.dart';

class PoliciesScreen extends StatefulWidget {
  const PoliciesScreen({super.key});

  @override
  State<PoliciesScreen> createState() => _PoliciesScreenState();
}

class _PoliciesScreenState extends State<PoliciesScreen> {
  double _gracePeriodMins = 59;
  double _turnaroundBufferHours = 2;
  double _officerDiscountLimit = 10;
  double _managerDiscountLimit = 25;
  bool _enforceDepositBeforeHandover = true;
  bool _autoReleaseUnpaidBookings = true;
  double _unpaidHoldHours = 24;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: const AppHeader(title: 'Policies & Business Rules'),
      drawer: const CustomDrawer(currentRoute: '/settings/policies'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Company Operational Policies (SRS 13)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const Text(
              'Config-driven sliders and thresholds for rentals, deposits, and role approval limits',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),

            const SizedBox(height: 20),

            // 1. Time & Buffer Policies Card
            _buildSectionCard(
              title: 'Turnaround Buffers & Grace Periods',
              icon: Icons.access_time_filled,
              children: [
                _buildSliderTile(
                  label: 'Late Return Grace Period',
                  value: _gracePeriodMins,
                  min: 15,
                  max: 120,
                  divisions: 7,
                  unit: 'mins',
                  subtitle: 'Returns within this grace window avoid automatic overdue charges.',
                  onChanged: (val) => setState(() => _gracePeriodMins = val),
                ),
                const Divider(),
                _buildSliderTile(
                  label: 'Turnaround Cleaning & Inspection Buffer',
                  value: _turnaroundBufferHours,
                  min: 1,
                  max: 6,
                  divisions: 5,
                  unit: 'hours',
                  subtitle: 'Automatic blocked slot drawn on availability board after vehicle return.',
                  onChanged: (val) => setState(() => _turnaroundBufferHours = val),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 2. Deposit & Release Rules Card
            _buildSectionCard(
              title: 'Deposit & Booking Hold Rules',
              icon: Icons.shield,
              children: [
                SwitchListTile(
                  value: _enforceDepositBeforeHandover,
                  activeThumbColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Enforce Deposit Before Handover (BR-16)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Handover wizard blocks vehicle release until security deposit is confirmed.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  onChanged: (val) => setState(() => _enforceDepositBeforeHandover = val),
                ),
                const Divider(),
                SwitchListTile(
                  value: _autoReleaseUnpaidBookings,
                  activeThumbColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Auto-Release Unpaid Pending Bookings (RES-09)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Unpaid bookings hold vehicle availability temporarily, then auto-cancel.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  onChanged: (val) => setState(() => _autoReleaseUnpaidBookings = val),
                ),
                if (_autoReleaseUnpaidBookings) ...[
                  const SizedBox(height: 8),
                  _buildSliderTile(
                    label: 'Unpaid Hold Timeout',
                    value: _unpaidHoldHours,
                    min: 2,
                    max: 48,
                    divisions: 23,
                    unit: 'hours',
                    subtitle: 'Hours given to customer to pay before reservation is released.',
                    onChanged: (val) => setState(() => _unpaidHoldHours = val),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // 3. Role Approval Limits (SRS 9.1)
            _buildSectionCard(
              title: 'Role Discount & Waiver Limits (SRS 9.1)',
              icon: Icons.verified_user,
              children: [
                _buildSliderTile(
                  label: 'Rental Officer Max Discount Limit',
                  value: _officerDiscountLimit,
                  min: 0,
                  max: 20,
                  divisions: 20,
                  unit: '%',
                  subtitle: 'Discounts above this threshold trigger an approval request to Rental Manager.',
                  onChanged: (val) => setState(() => _officerDiscountLimit = val),
                ),
                const Divider(),
                _buildSliderTile(
                  label: 'Rental Manager Max Discount Limit',
                  value: _managerDiscountLimit,
                  min: 15,
                  max: 50,
                  divisions: 7,
                  unit: '%',
                  subtitle: 'Discounts above this threshold trigger an approval request to Owner / Management.',
                  onChanged: (val) => setState(() => _managerDiscountLimit = val),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Save Policy Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Company policies updated and applied across all branches.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Save & Apply Policies', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
            children: [
              Icon(icon, color: Colors.black, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required String subtitle,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
            const SizedBox(width: 8),
            Text(
              '${value.toInt()} $unit',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
