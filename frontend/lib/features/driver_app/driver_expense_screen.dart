// lib/features/driver_app/driver_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money_utils.dart';
import '../../shared/repositories/repository_interfaces.dart';
import '../../shared/repositories/trip_repository.dart';

class DriverExpenseScreen extends ConsumerStatefulWidget {
  final String tripId;

  const DriverExpenseScreen({super.key, required this.tripId});

  @override
  ConsumerState<DriverExpenseScreen> createState() => _DriverExpenseScreenState();
}

class _DriverExpenseScreenState extends ConsumerState<DriverExpenseScreen> {
  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedType = 'Fuel';
  bool _hasReceiptPhoto = true;
  bool _isSubmitting = false;

  final List<String> _expenseTypes = [
    'Fuel',
    'Toll Road',
    'Border Clearance',
    'Parking',
    'Driver Daily Allowance',
    'Loading & Offloading',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitExpense() async {
    final amountText = _amountController.text.replaceAll(',', '').trim();
    final amount = int.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid expense amount in RWF.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final expense = TripExpense(
      id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
      tripId: widget.tripId,
      type: _selectedType,
      amountRwf: amount,
      receiptPhotoUrl: _hasReceiptPhoto ? 'assets/receipts/mock_receipt.png' : null,
      timestamp: DateTime.now(),
      locationGps: '-1.9441, 30.0619 (Kigali Road)',
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : _vendorController.text.trim(),
      isSynced: true,
    );

    final repo = ref.read(tripRepositoryProvider);
    await repo.logExpense(expense);

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged $_selectedType expense of ${MoneyUtils.formatRwf(amount)} successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Log Trip Expense (TRP-02)',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sync status badge
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_tethering, size: 16, color: Colors.black),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offline capture enabled · Auto-syncs when online',
                      style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Expense Category Selection
            const Text(
              'Expense Category *',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                  items: _expenseTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Amount field
            const Text(
              'Amount in RWF (no decimals) *',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              decoration: InputDecoration(
                prefixText: 'RWF  ',
                prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                hintText: 'e.g. 85000',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 18),

            // Vendor / Station name
            const Text(
              'Station / Merchant Name',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _vendorController,
              decoration: InputDecoration(
                hintText: 'e.g. SP Petrol Nyabugogo / RN1 Toll Plaza',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 18),

            // Receipt photo upload slot
            const Text(
              'Receipt Photo (Proof of Payment) *',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt, color: Colors.black, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasReceiptPhoto ? 'Receipt Document Attached' : 'No Receipt Attached',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const Text(
                          'Photo automatically compressed',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _hasReceiptPhoto = true);
                    },
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: const Text('Retake'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Notes
            const Text(
              'Additional Notes / Remarks',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. 50 Litres of diesel topped up for climb to Huye',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 30),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitExpense,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save & Log Expense',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
