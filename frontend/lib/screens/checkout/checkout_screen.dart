// lib/screens/checkout/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/env_config.dart';
import '../../core/theme/app_colors.dart';
import '../../models/car.dart';
import '../../models/location.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../services/car_service.dart';
import '../../services/location_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/bc_checkbox.dart';
import '../../widgets/bc_date_picker.dart';
import '../../widgets/bc_text_input.dart';
import '../../widgets/custom_drawer.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? params;

  const CheckoutScreen({super.key, this.params});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  // Loading / error state
  bool _loading = true;
  String? _error;

  // Loaded data
  Car? _car;
  Location? _pickupLocation;
  Location? _dropOffLocation;

  // Booking parameters
  late DateTime _from;
  late DateTime _to;
  late String _carId;
  late String _pickupLocationId;
  late String _dropOffLocationId;

  // Driver form (unauthenticated)
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  DateTime? _birthDate;

  // Form errors
  bool _fullNameError = false;
  bool _emailError = false;
  bool _phoneError = false;
  bool _birthDateError = false;
  bool _tosError = false;

  // Extras toggles
  bool _cancellation = false;
  bool _amendments = false;
  bool _theftProtection = false;
  bool _collisionDamageWaiver = false;
  bool _fullInsurance = false;
  bool _additionalDriver = false;

  // Additional driver form
  final _addDriverFullNameCtrl = TextEditingController();
  final _addDriverEmailCtrl = TextEditingController();
  final _addDriverPhoneCtrl = TextEditingController();
  DateTime? _addDriverBirthDate;

  // Misc
  bool _tosAccepted = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _parseParams();
    _loadData();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addDriverFullNameCtrl.dispose();
    _addDriverEmailCtrl.dispose();
    _addDriverPhoneCtrl.dispose();
    super.dispose();
  }

  void _parseParams() {
    final p = widget.params ?? {};
    _carId = p['carId'] as String? ?? '';
    _pickupLocationId = p['pickupLocationId'] as String? ?? '';
    _dropOffLocationId = p['dropOffLocationId'] as String? ?? '';
    final fromMs = p['from'] as int? ?? 0;
    final toMs = p['to'] as int? ?? 0;
    _from = DateTime.fromMillisecondsSinceEpoch(fromMs);
    _to = DateTime.fromMillisecondsSinceEpoch(toMs);
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        CarService.instance.getCar(_carId),
        LocationService.instance.getLocation(_pickupLocationId),
        if (_dropOffLocationId != _pickupLocationId)
          LocationService.instance.getLocation(_dropOffLocationId),
      ]);

      Location dropOff;
      if (_dropOffLocationId == _pickupLocationId) {
        dropOff = results[1] as Location;
      } else {
        dropOff = results[2] as Location;
      }

      if (mounted) {
        setState(() {
          _car = results[0] as Car;
          _pickupLocation = results[1] as Location;
          _dropOffLocation = dropOff;
          _loading = false;
        });

        // Pre-fill extras based on car policy
        _initExtras();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppStrings.t('GENERIC_ERROR');
          _loading = false;
        });
      }
    }
  }

  void _initExtras() {
    final car = _car;
    if (car == null) return;
    // 0 = included (checked+disabled), -1 = excluded (unchecked+disabled), >0 = purchasable
    setState(() {
      _cancellation = car.cancellation == 0;
      _amendments = car.amendments == 0;
      _theftProtection = car.theftProtection == 0;
      _collisionDamageWaiver = car.collisionDamageWaiver == 0;
      _fullInsurance = car.fullInsurance == 0;
      _additionalDriver = false;
    });
  }

  int get _days {
    final d = _to.difference(_from).inDays;
    return d < 1 ? 1 : d;
  }

  double get _totalPrice {
    final car = _car;
    if (car == null) return 0;
    double total = car.price * _days;
    if (_cancellation && car.cancellation > 0) total += car.cancellation * _days;
    if (_amendments && car.amendments > 0) total += car.amendments * _days;
    if (_theftProtection && car.theftProtection > 0) total += car.theftProtection * _days;
    if (_collisionDamageWaiver && car.collisionDamageWaiver > 0) total += car.collisionDamageWaiver * _days;
    if (_fullInsurance && car.fullInsurance > 0) total += car.fullInsurance * _days;
    if (_additionalDriver && car.additionalDriver > 0) total += car.additionalDriver * _days;
    return total;
  }

  String _fmtDate(DateTime dt) {
    try {
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  String _fmtPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }

  bool _validateForm(bool isAuthenticated) {
    bool valid = true;
    if (!isAuthenticated) {
      setState(() {
        _fullNameError = _fullNameCtrl.text.trim().isEmpty;
        _emailError = _emailCtrl.text.trim().isEmpty ||
            !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailCtrl.text.trim());
        _phoneError = _phoneCtrl.text.trim().isEmpty;
        final now = DateTime.now();
        _birthDateError = _birthDate == null ||
            now.difference(_birthDate!).inDays < 21 * 365;
        _tosError = !_tosAccepted;
      });
      if (_fullNameError || _emailError || _phoneError || _birthDateError || _tosError) {
        valid = false;
      }
    }
    return valid;
  }

  Future<void> _submit() async {
    final authState = ref.read(authProvider);
    final isAuth = authState.isAuthenticated;

    if (!_validateForm(isAuth)) return;

    setState(() => _submitting = true);

    try {
      final Map<String, dynamic> payload = {
        'booking': {
          'supplier': _car!.supplier.id,
          'car': _car!.id,
          'driver': isAuth ? authState.user!.id : null,
          'pickupLocation': _pickupLocationId,
          'dropOffLocation': _dropOffLocationId,
          'from': _from.toIso8601String(),
          'to': _to.toIso8601String(),
          'status': 'Pending',
          'cancellation': _cancellation,
          'amendments': _amendments,
          'theftProtection': _theftProtection,
          'collisionDamageWaiver': _collisionDamageWaiver,
          'fullInsurance': _fullInsurance,
          'additionalDriver': _additionalDriver,
          'price': _totalPrice,
        },
        'payLater': true,
      };

      if (!isAuth) {
        payload['driver'] = {
          'email': _emailCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'fullName': _fullNameCtrl.text.trim(),
          'birthDate': _birthDate!.toIso8601String(),
          'language': AppStrings.currentLanguage,
        };
      }

      if (_additionalDriver) {
        payload['additionalDriver'] = {
          'fullName': _addDriverFullNameCtrl.text.trim(),
          'email': _addDriverEmailCtrl.text.trim(),
          'phone': _addDriverPhoneCtrl.text.trim(),
          if (_addDriverBirthDate != null)
            'birthDate': _addDriverBirthDate!.toIso8601String(),
        };
      }

      final status = await BookingService.instance.checkout(payload);
      if (!mounted) return;

      if (status == 200) {
        context.go('/bookings');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('GENERIC_ERROR'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('GENERIC_ERROR'))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAuth = authState.isAuthenticated;
    final user = authState.user;

    // Pre-fill from user if logged in
    if (isAuth && user != null && _emailCtrl.text.isEmpty) {
      _emailCtrl.text = user.email ?? '';
      _fullNameCtrl.text = user.fullName ?? '';
      _phoneCtrl.text = user.phone ?? '';
      _birthDate = user.birthDate;
    }

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppHeader(title: AppStrings.t('CHECKOUT')),
      drawer: const CustomDrawer(currentRoute: '/checkout'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
              : _buildBody(isAuth, user),
    );
  }

  Widget _buildBody(bool isAuth, dynamic user) {
    final car = _car!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Car Summary Card ──────────────────────────────────────
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Car image
                    if (car.image != null && car.image!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: car.image!.startsWith('assets/')
                            ? Image.asset(
                                car.image!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 160,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.directions_car, size: 60, color: Colors.black),
                                ),
                              )
                            : Image.network(
                                car.image!.startsWith('http')
                                    ? car.image!
                                    : '${EnvConfig.cdnCars}/${car.image}',
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/images/midi.png',
                                  height: 160,
                                  fit: BoxFit.contain,
                                ),
                              ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      car.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      car.supplier.fullName ?? '',
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.location_on, AppStrings.t('PICKUP'),
                        _pickupLocation?.name ?? _pickupLocationId),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.location_on_outlined, AppStrings.t('DROP_OFF'),
                        _dropOffLocation?.name ?? _dropOffLocationId),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.calendar_today, AppStrings.t('FROM'), _fmtDate(_from)),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.calendar_today_outlined, AppStrings.t('TO'), _fmtDate(_to)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Driver Details (unauthenticated) ──────────────────────
              if (!isAuth) ...[
                _buildSectionTitle(AppStrings.t('DRIVER_DETAILS')),
                const SizedBox(height: 8),
                BcTextInput(
                  label: AppStrings.t('FULL_NAME'),
                  controller: _fullNameCtrl,
                  error: _fullNameError,
                  helperText: _fullNameError ? AppStrings.t('REQUIRED') : null,
                  onChangeText: (_) => setState(() => _fullNameError = false),
                ),
                BcTextInput(
                  label: AppStrings.t('EMAIL'),
                  controller: _emailCtrl,
                  error: _emailError,
                  helperText: _emailError ? AppStrings.t('EMAIL_NOT_VALID') : null,
                  keyboardType: TextInputType.emailAddress,
                  onChangeText: (_) => setState(() => _emailError = false),
                ),
                BcTextInput(
                  label: AppStrings.t('PHONE'),
                  controller: _phoneCtrl,
                  error: _phoneError,
                  helperText: _phoneError ? AppStrings.t('PHONE_NOT_VALID') : null,
                  keyboardType: TextInputType.phone,
                  onChangeText: (_) => setState(() => _phoneError = false),
                ),
                BcDatePicker(
                  label: AppStrings.t('BIRTH_DATE'),
                  value: _birthDate,
                  error: _birthDateError,
                  helperText: _birthDateError ? AppStrings.t('BIRTH_DATE_NOT_VALID') : null,
                  maxDate: DateTime.now().subtract(const Duration(days: 21 * 365)),
                  onChange: (d) => setState(() {
                    _birthDate = d;
                    _birthDateError = false;
                  }),
                ),
                const SizedBox(height: 16),
              ],

              // ── Extras ───────────────────────────────────────────────
              _buildSectionTitle(AppStrings.t('EXTRAS')),
              const SizedBox(height: 8),
              _buildCard(
                child: Column(
                  children: [
                    _buildExtraRow(
                      label: AppStrings.t('CANCELLATION'),
                      value: _cancellation,
                      policyValue: car.cancellation,
                      onChanged: (v) => setState(() => _cancellation = v),
                    ),
                    _buildExtraRow(
                      label: AppStrings.t('AMENDMENTS'),
                      value: _amendments,
                      policyValue: car.amendments,
                      onChanged: (v) => setState(() => _amendments = v),
                    ),
                    _buildExtraRow(
                      label: AppStrings.t('THEFT_PROTECTION'),
                      value: _theftProtection,
                      policyValue: car.theftProtection,
                      onChanged: (v) => setState(() => _theftProtection = v),
                    ),
                    _buildExtraRow(
                      label: AppStrings.t('COLLISION_DAMAGE_WAIVER'),
                      value: _collisionDamageWaiver,
                      policyValue: car.collisionDamageWaiver,
                      onChanged: (v) => setState(() => _collisionDamageWaiver = v),
                    ),
                    _buildExtraRow(
                      label: AppStrings.t('FULL_INSURANCE'),
                      value: _fullInsurance,
                      policyValue: car.fullInsurance,
                      onChanged: (v) => setState(() => _fullInsurance = v),
                    ),
                    _buildExtraRow(
                      label: AppStrings.t('ADDITIONAL_DRIVER'),
                      value: _additionalDriver,
                      policyValue: car.additionalDriver,
                      onChanged: (v) => setState(() => _additionalDriver = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Additional Driver Form ────────────────────────────────
              if (_additionalDriver && car.additionalDriver > 0) ...[
                _buildSectionTitle('${AppStrings.t('ADDITIONAL_DRIVER')} - ${AppStrings.t('DRIVER_DETAILS')}'),
                const SizedBox(height: 8),
                BcTextInput(
                  label: AppStrings.t('FULL_NAME'),
                  controller: _addDriverFullNameCtrl,
                ),
                BcTextInput(
                  label: AppStrings.t('EMAIL'),
                  controller: _addDriverEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                BcTextInput(
                  label: AppStrings.t('PHONE'),
                  controller: _addDriverPhoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
                BcDatePicker(
                  label: AppStrings.t('BIRTH_DATE'),
                  value: _addDriverBirthDate,
                  maxDate: DateTime.now().subtract(const Duration(days: 21 * 365)),
                  onChange: (d) => setState(() => _addDriverBirthDate = d),
                ),
                const SizedBox(height: 16),
              ],

              // ── Price Summary ─────────────────────────────────────────
              _buildSectionTitle(AppStrings.t('PRICE_SUMMARY')),
              const SizedBox(height: 8),
              _buildPriceSummary(car),
              const SizedBox(height: 16),

              // ── Pay Later info ────────────────────────────────────────
              _buildCard(
                child: Row(
                  children: [
                    const Icon(Icons.payment, color: Colors.black, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.t('PAY_LATER'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── ToS Checkbox (unauthenticated) ───────────────────────
              if (!isAuth) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BcCheckbox(
                      checked: _tosAccepted,
                      onChange: (v) => setState(() {
                        _tosAccepted = v;
                        _tosError = false;
                      }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _tosAccepted = !_tosAccepted;
                          _tosError = false;
                        }),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            AppStrings.t('ACCEPT_TOS'),
                            style: TextStyle(
                              fontSize: 13,
                              color: _tosError ? AppColors.error : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_tosError)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 2),
                    child: Text(
                      AppStrings.t('TOS_ERROR'),
                      style: const TextStyle(fontSize: 11, color: AppColors.error),
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              // ── BOOK Button ───────────────────────────────────────────
              BcButton(
                label: AppStrings.t('BOOK'),
                isLoading: _submitting,
                onPress: _submitting ? null : _submit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildExtraRow({
    required String label,
    required bool value,
    required int policyValue,
    required ValueChanged<bool> onChanged,
  }) {
    // policyValue: 0 = included, -1 = excluded, >0 = purchasable
    final isIncluded = policyValue == 0;
    final isExcluded = policyValue == -1;
    final isPurchasable = policyValue > 0;
    final isDisabled = !isPurchasable;

    String subLabel;
    if (isIncluded) {
      subLabel = AppStrings.t('INCLUDED');
    } else if (isExcluded) {
      subLabel = AppStrings.t('EXCLUDED');
    } else {
      subLabel = '+$policyValue${AppStrings.t('PER_DAY')}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          BcCheckbox(
            checked: value,
            onChange: isDisabled ? null : onChanged,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                Text(
                  subLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: isIncluded
                        ? AppColors.extraIncluded
                        : isExcluded
                            ? AppColors.extraExcluded
                            : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(Car car) {
    final rows = <_PriceRow>[
      _PriceRow(AppStrings.t('BASE_PRICE'), car.price * _days),
    ];

    if (_cancellation && car.cancellation > 0) {
      rows.add(_PriceRow(AppStrings.t('CANCELLATION'), car.cancellation.toDouble() * _days));
    }
    if (_amendments && car.amendments > 0) {
      rows.add(_PriceRow(AppStrings.t('AMENDMENTS'), car.amendments.toDouble() * _days));
    }
    if (_theftProtection && car.theftProtection > 0) {
      rows.add(_PriceRow(AppStrings.t('THEFT_PROTECTION'), car.theftProtection.toDouble() * _days));
    }
    if (_collisionDamageWaiver && car.collisionDamageWaiver > 0) {
      rows.add(_PriceRow(AppStrings.t('COLLISION_DAMAGE_WAIVER'), car.collisionDamageWaiver.toDouble() * _days));
    }
    if (_fullInsurance && car.fullInsurance > 0) {
      rows.add(_PriceRow(AppStrings.t('FULL_INSURANCE'), car.fullInsurance.toDouble() * _days));
    }
    if (_additionalDriver && car.additionalDriver > 0) {
      rows.add(_PriceRow(AppStrings.t('ADDITIONAL_DRIVER'), car.additionalDriver.toDouble() * _days));
    }

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$_days ${_days == 1 ? AppStrings.t('DAY') : AppStrings.t('DAYS')}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                _fmtPrice(car.price),
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              Text(
                AppStrings.t('PER_DAY'),
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(r.label,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    ),
                    Text(
                      _fmtPrice(r.amount),
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              )),
          const Divider(height: 20),
          Row(
            children: [
              Text(
                AppStrings.t('TOTAL'),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Text(
                _fmtPrice(_totalPrice),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow {
  final String label;
  final double amount;
  const _PriceRow(this.label, this.amount);
}
