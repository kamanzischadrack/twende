// lib/features/portal/portal_book_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money_utils.dart';
import '../../shared/domain/enums.dart';
import '../../shared/repositories/repository_interfaces.dart';
import '../../shared/repositories/store_finance_repositories.dart';
import '../../shared/repositories/store_repositories.dart';

class PortalBookScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? params;

  const PortalBookScreen({super.key, this.params});

  @override
  ConsumerState<PortalBookScreen> createState() => _PortalBookScreenState();
}

class _PortalBookScreenState extends ConsumerState<PortalBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _licenceController = TextEditingController();

  bool _includeDriver = false;
  bool _includeChildSeat = false;
  bool _includeGps = false;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  late String _categoryName;
  late String _branch;
  late DateTime _pickupDate;
  late DateTime _returnDate;
  late int _dailyRate;
  late int _deposit;

  final int _driverDailyRate = 20000;
  final int _childSeatDailyRate = 3000;
  final int _gpsDailyRate = 5000;

  @override
  void initState() {
    super.initState();
    final p = widget.params ?? {};
    _categoryName = p['category'] as String? ?? 'SUV & Crossover';
    _branch = p['branch'] as String? ?? 'Kigali HQ';
    _pickupDate = DateTime.tryParse(p['pickupDate'] as String? ?? '') ??
        DateTime.now().add(const Duration(days: 1));
    _returnDate = DateTime.tryParse(p['returnDate'] as String? ?? '') ??
        DateTime.now().add(const Duration(days: 4));
    _dailyRate = (p['dailyRate'] as num?)?.toInt() ?? 75000;
    _deposit = (p['deposit'] as num?)?.toInt() ?? 200000;

    _nameController.text = 'Aline Uwase';
    _phoneController.text = '+250 788 556 677';
    _emailController.text = 'aline.uwase@gmail.com';
    _nationalIdController.text = '1199480029381029';
    _licenceController.text = 'RW-DL-2022-8819';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nationalIdController.dispose();
    _licenceController.dispose();
    super.dispose();
  }

  int get _rentalDays {
    final diff = _returnDate.difference(_pickupDate);
    final days = (diff.inHours / 24).ceil();
    return days <= 0 ? 1 : days;
  }

  int get _baseRentalTotal {
    final weeklyRate = _dailyRate * 5; // 6 & 7 days capped at 5x daily
    if (_rentalDays >= 7) {
      final weeks = _rentalDays ~/ 7;
      final extraDays = _rentalDays % 7;
      return (weeks * weeklyRate) + (extraDays * _dailyRate);
    } else if (_rentalDays >= 6) {
      return weeklyRate;
    }
    return _rentalDays * _dailyRate;
  }

  int get _extrasTotal {
    int total = 0;
    if (_includeDriver) total += _driverDailyRate * _rentalDays;
    if (_includeChildSeat) total += _childSeatDailyRate * _rentalDays;
    if (_includeGps) total += _gpsDailyRate * _rentalDays;
    return total;
  }

  int get _vatAmount {
    return ((_baseRentalTotal + _extrasTotal) * 0.18).round();
  }

  int get _grandTotal {
    return _baseRentalTotal + _extrasTotal + _vatAmount;
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the rental terms and privacy policy to proceed.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final contractRepo = ref.read(contractRepositoryProvider);
      final customerRepo = ref.read(customerRepositoryProvider);

      final customerId = 'cust_${DateTime.now().millisecondsSinceEpoch}';
      await customerRepo.createCustomer(
        TwendeCustomer(
          id: customerId,
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          type: CustomerType.individual,
          nationalId: _nationalIdController.text.trim(),
          licenceNumber: _licenceController.text.trim(),
          licenceExpiry: DateTime.now().add(const Duration(days: 365 * 3)),
        ),
      );

      final contractId = 'RC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final newContract = TwendeContract(
        id: contractId,
        contractNumber: contractId,
        customerId: customerId,
        customerName: _nameController.text.trim(),
        vehicleId: 'veh_01',
        vehicleName: '$_categoryName (Confirmed)',
        vehiclePlate: 'RAC 123 B',
        pickupDateTime: _pickupDate,
        returnDateTime: _returnDate,
        status: ContractStatus.draft,
        totalAmount: _grandTotal.toDouble(),
        depositAmount: _deposit.toDouble(),
        balanceDue: _grandTotal.toDouble(),
        isSigned: false,
      );

      await contractRepo.createContract(newContract);

      if (mounted) {
        setState(() => _isSubmitting = false);
        // Seamlessly route to customer remote payment checkout
        final paymentToken = 'tok_${contractId.toLowerCase()}';
        context.push('/portal/pay/$paymentToken');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMM yyyy · HH:mm');

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
          'Complete Reservation',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Vehicle & Itinerary Summary Card
              Container(
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
                        Text(
                          _categoryName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$_rentalDays ${_rentalDays == 1 ? "Day" : "Days"}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.black, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Branch: $_branch',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.black, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pickup: ${dateFormat.format(_pickupDate)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event_repeat, color: Colors.black, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Return: ${dateFormat.format(_returnDate)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Customer Contact Form
              const Text(
                '1. Driver & Customer Information',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name (as on ID / Passport) *',
                        prefixIcon: const Icon(Icons.person, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Money Phone Number (+250) *',
                        prefixIcon: const Icon(Icons.phone, size: 20),
                        hintText: '+250 788 123 456',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address *',
                        prefixIcon: const Icon(Icons.email, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nationalIdController,
                            decoration: InputDecoration(
                              labelText: 'National ID / Passport *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _licenceController,
                            decoration: InputDecoration(
                              labelText: 'Driver Licence # *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Optional Extras
              const Text(
                '2. Add-on Options & Extras',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: _includeDriver,
                      activeColor: AppColors.primary,
                      title: const Text('Professional Chauffeur / Driver', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text('+${MoneyUtils.formatRwf(_driverDailyRate)} / day', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      onChanged: (val) => setState(() => _includeDriver = val ?? false),
                    ),
                    const Divider(height: 1),
                    CheckboxListTile(
                      value: _includeChildSeat,
                      activeColor: AppColors.primary,
                      title: const Text('Child Safety Booster Seat', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text('+${MoneyUtils.formatRwf(_childSeatDailyRate)} / day', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      onChanged: (val) => setState(() => _includeChildSeat = val ?? false),
                    ),
                    const Divider(height: 1),
                    CheckboxListTile(
                      value: _includeGps,
                      activeColor: AppColors.primary,
                      title: const Text('Dedicated GPS Navigation Unit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text('+${MoneyUtils.formatRwf(_gpsDailyRate)} / day', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      onChanged: (val) => setState(() => _includeGps = val ?? false),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. Live Quote Breakdown
              const Text(
                '3. Price Breakdown (SRS 8.1 Engine)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildQuoteRow(
                      'Base Rental ($_rentalDays days)',
                      MoneyUtils.formatRwf(_baseRentalTotal),
                    ),
                    if (_extrasTotal > 0)
                      _buildQuoteRow(
                        'Add-on Extras',
                        MoneyUtils.formatRwf(_extrasTotal),
                      ),
                    _buildQuoteRow(
                      'VAT (18% Statutory RRA)',
                      MoneyUtils.formatRwf(_vatAmount),
                    ),
                    const Divider(height: 20),
                    _buildQuoteRow(
                      'Total Rental Amount',
                      MoneyUtils.formatRwf(_grandTotal),
                      isBold: true,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Refundable Security Deposit:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            MoneyUtils.formatRwf(_deposit),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 5. Terms & Privacy Checkbox
              CheckboxListTile(
                value: _agreedToTerms,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'I agree to the Twende Rental Terms of Service, cancellation rules, and data privacy policy (CUS-08).',
                  style: TextStyle(fontSize: 12),
                ),
                onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Proceed to Payment Checkout',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.lock, size: 16),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    double fontSize = 13,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
