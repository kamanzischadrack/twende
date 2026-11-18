import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/auth/session_provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money_utils.dart';
import '../../core/widgets/approval_banner.dart';
import '../../shared/domain/enums.dart';
import '../../shared/domain/pricing_engine.dart';
import '../../shared/domain/validation_rules.dart';
import '../../shared/repositories/store_repositories.dart';
import '../../shared/repositories/repository_interfaces.dart';
import '../../widgets/app_header.dart';

class TwendeBookingCreateScreen extends ConsumerStatefulWidget {
  final String? initialVehicleId;
  final String? initialCustomerId;

  const TwendeBookingCreateScreen({
    super.key,
    this.initialVehicleId,
    this.initialCustomerId,
  });

  @override
  ConsumerState<TwendeBookingCreateScreen> createState() => _TwendeBookingCreateScreenState();
}

class _TwendeBookingCreateScreenState extends ConsumerState<TwendeBookingCreateScreen> {
  TwendeVehicle? _selectedVehicle;
  TwendeCustomer? _selectedCustomer;
  late DateTime _pickupDate;
  late DateTime _returnDate;
  final TimeOfDay _pickupTime = const TimeOfDay(hour: 9, minute: 0);
  final TimeOfDay _returnTime = const TimeOfDay(hour: 9, minute: 0);

  bool _isUnlimitedMileage = false;
  final Set<String> _selectedExtras = {};
  double _discountPercent = 0.0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _pickupDate = DateTime(now.year, now.month, now.day + 1);
    _returnDate = DateTime(now.year, now.month, now.day + 4); // 3 days default
  }

  DateTime get _fullPickup => DateTime(
        _pickupDate.year,
        _pickupDate.month,
        _pickupDate.day,
        _pickupTime.hour,
        _pickupTime.minute,
      );

  DateTime get _fullReturn => DateTime(
        _returnDate.year,
        _returnDate.month,
        _returnDate.day,
        _returnTime.hour,
        _returnTime.minute,
      );

  QuoteResult _computeQuote() {
    final tenant = ref.watch(tenantConfigProvider);
    final vehicle = _selectedVehicle;
    if (vehicle == null) {
      return const QuoteResult(
        billableDays: 0,
        rateDecompositionDescription: '',
        baseRentalAmount: 0,
        extrasAmount: 0,
        mileagePackageAmount: 0,
        subtotal: 0,
        discountAmount: 0,
        taxableAmount: 0,
        taxAmount: 0,
        totalAmount: 0,
        depositAmount: 0,
        totalPayableWithDeposit: 0,
        currency: 'RWF',
        lines: [],
      );
    }

    final extrasList = <ExtraInput>[];
    if (_selectedExtras.contains('gps')) {
      extrasList.add(const ExtraInput(id: 'gps', name: 'GPS Navigation Unit', unitPrice: 5000.0, perDay: true));
    }
    if (_selectedExtras.contains('driver')) {
      extrasList.add(const ExtraInput(id: 'driver', name: 'Professional Chauffeur', unitPrice: 25000.0, perDay: true));
    }
    if (_selectedExtras.contains('seat')) {
      extrasList.add(const ExtraInput(id: 'seat', name: 'Child Safety Seat', unitPrice: 3000.0, perDay: true));
    }

    DiscountInput? discount;
    if (_discountPercent > 0) {
      discount = DiscountInput(
        id: 'commercial',
        name: 'Commercial Discount (${_discountPercent.toStringAsFixed(0)}%)',
        percent: _discountPercent,
      );
    }

    return PricingEngine.compute(
      pickupDateTime: _fullPickup,
      returnDateTime: _fullReturn,
      ratePlan: RatePlanInput(
        dailyRate: vehicle.dailyRate,
        weeklyRate: vehicle.dailyRate * 6, // 1 free day per week cap
        currency: tenant.currency,
      ),
      mileagePlan: MileagePlanInput(
        isUnlimited: _isUnlimitedMileage,
        dailyAllowanceKm: tenant.defaultDailyMileageAllowanceKm,
        dailyPackageFee: _isUnlimitedMileage ? 15000.0 : 0.0,
      ),
      extras: extrasList,
      discount: discount,
      taxConfig: TaxConfig(
        mode: tenant.taxMode == 'inclusive' ? TaxMode.inclusive : TaxMode.exclusive,
        rate: tenant.taxRate,
      ),
      depositAmount: tenant.defaultDepositAmount,
      discountApprovalThresholdPercent: tenant.discountApprovalThreshold * 100,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fleetRepo = ref.watch(fleetRepositoryProvider);
    final customerRepo = ref.watch(customerRepositoryProvider);
    final dateFormat = DateFormat('EEE, MMM dd, yyyy');

    final dateValidation = ValidationRules.checkDateRange(
      pickup: _fullPickup,
      returnTime: _fullReturn,
      allowPastPickup: false,
    );

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: const AppHeader(
        title: 'New Booking & Live Quote',
      ),
      body: FutureBuilder(
        future: Future.wait([
          fleetRepo.getVehicles(),
          customerRepo.getCustomers(),
        ]),
        builder: (ctx, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final vehicles = (snapshot.data?[0] as PaginatedResult<TwendeVehicle>?)?.items ?? [];
          final customers = (snapshot.data?[1] as PaginatedResult<TwendeCustomer>?)?.items ?? [];

          if (_selectedVehicle == null && vehicles.isNotEmpty) {
            _selectedVehicle = widget.initialVehicleId != null
                ? vehicles.firstWhere((v) => v.id == widget.initialVehicleId, orElse: () => vehicles.first)
                : vehicles.first;
          }
          if (_selectedCustomer == null && customers.isNotEmpty) {
            _selectedCustomer = widget.initialCustomerId != null
                ? customers.firstWhere((c) => c.id == widget.initialCustomerId, orElse: () => customers.first)
                : customers.first;
          }

          final quote = _computeQuote();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle Picker Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('1. Select Vehicle', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<TwendeVehicle>(
                        initialValue: _selectedVehicle,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: vehicles.map((v) {
                          return DropdownMenuItem(
                            value: v,
                            child: Text('${v.name} (${v.plateNumber}) - ${MoneyUtils.format(v.dailyRate)}/day'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedVehicle = val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Customer Picker Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('2. Select Customer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<TwendeCustomer>(
                        initialValue: _selectedCustomer,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: customers.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text('${c.fullName} (${c.type.label})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCustomer = val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Rental Window (Dates & Times)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: dateValidation.isValid ? AppColors.cardBorder : AppColors.error,
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('3. Rental Period (24h Rolling)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pickup Date', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _pickupDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) setState(() => _pickupDate = picked);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.cardBorder),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(dateFormat.format(_pickupDate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Return Date', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _returnDate,
                                      firstDate: _pickupDate,
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) setState(() => _returnDate = picked);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.cardBorder),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(dateFormat.format(_returnDate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!dateValidation.isValid) ...[
                        const SizedBox(height: 8),
                        Text(
                          dateValidation.errorMessage ?? '',
                          style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Mileage & Extras Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('4. Mileage Plan & Options', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 6),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Unlimited Mileage Package', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Extra +15,000 RWF / day (waives 150 km daily limit)', style: TextStyle(fontSize: 11)),
                        value: _isUnlimitedMileage,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => setState(() => _isUnlimitedMileage = val),
                      ),
                      const Divider(height: 1),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('GPS Navigation Unit (+5,000 RWF/day)', style: TextStyle(fontSize: 13)),
                        value: _selectedExtras.contains('gps'),
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedExtras.add('gps');
                            } else {
                              _selectedExtras.remove('gps');
                            }
                          });
                        },
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Professional Chauffeur (+25,000 RWF/day)', style: TextStyle(fontSize: 13)),
                        value: _selectedExtras.contains('driver'),
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedExtras.add('driver');
                            } else {
                              _selectedExtras.remove('driver');
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('Commercial Discount:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Slider(
                              value: _discountPercent,
                              min: 0,
                              max: 30,
                              divisions: 6,
                              label: '${_discountPercent.toStringAsFixed(0)}%',
                              activeColor: AppColors.primary,
                              onChanged: (val) => setState(() => _discountPercent = val),
                            ),
                          ),
                          Text('${_discountPercent.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Approval Alert if discount > 20%
                if (quote.requiresApproval) ...[
                  ApprovalBanner(
                    count: 1,
                    message: quote.approvalReason ?? 'Discount requires supervisor approval.',
                  ),
                  const SizedBox(height: 12),
                ],

                // Live Quote Breakdown Card (Deterministic Cap & Compose)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Quote Breakdown (Live Preview)',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              AppStrings.t('ESTIMATE_LABEL'),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Duration: ${quote.billableDays} billable days (${quote.rateDecompositionDescription})',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      ...quote.lines.map((line) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  line.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: line.isDiscount ? Colors.green.shade800 : AppColors.textPrimary,
                                    fontWeight: line.isDiscount ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              Text(
                                MoneyUtils.format(line.amount, quote.currency),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: line.isDiscount ? Colors.green.shade800 : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Rental Subtotal (excl. VAT)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          Text(MoneyUtils.format(quote.taxableAmount, quote.currency), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('VAT (18% Exclusive)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          Text(MoneyUtils.format(quote.taxAmount, quote.currency), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Security Deposit (Refundable)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          Text(MoneyUtils.format(quote.depositAmount, quote.currency), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 2),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Payable at Checkout',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            MoneyUtils.format(quote.totalPayableWithDeposit, quote.currency),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booking generated! Contract CNT-2026-0046 created in Draft state.')),
                      );
                      context.push('/contract/cnt_01');
                    },
                    child: const Text('Confirm & Create Contract', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
