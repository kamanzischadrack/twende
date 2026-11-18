// lib/screens/booking/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/env_config.dart';
import '../../core/theme/app_colors.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/booking_status_badge.dart';
import '../../widgets/custom_drawer.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  bool _loading = true;
  String? _error;
  Booking? _booking;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final booking = await BookingService.instance.getBooking(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = booking;
          _loading = false;
        });
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

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t('CANCEL_BOOKING')),
        content: Text(AppStrings.t('CANCEL_BOOKING_CONFIRM')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.t('CANCEL')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              AppStrings.t('CONFIRM'),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _cancelling = true);
    try {
      final status = await BookingService.instance.cancel(widget.bookingId);
      if (!mounted) return;
      if (status == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('BOOKING_CANCELLED'))),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('GENERIC_ERROR'))),
        );
        setState(() => _cancelling = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t('GENERIC_ERROR'))),
        );
        setState(() => _cancelling = false);
      }
    }
  }

  String _fmtDateTime(DateTime? dt) {
    if (dt == null) return '-';
    try {
      return DateFormat('dd MMM yyyy HH:mm').format(dt);
    } catch (_) {
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  bool get _isCancelable {
    final b = _booking;
    if (b == null) return false;
    return b.status == 'Pending' && b.cancelRequest == null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppHeader(title: AppStrings.t('BOOKING_DETAILS')),
      drawer: const CustomDrawer(currentRoute: '/bookings'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final booking = _booking!;
    final car = booking.car;
    final from = booking.from;
    final to = booking.to;
    final days = (from != null && to != null)
        ? to.difference(from).inDays.clamp(1, 999)
        : 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Status Badge ──────────────────────────────────────────
              Center(
                child: BookingStatusBadge(
                  status: booking.status,
                  margin: const EdgeInsets.only(bottom: 16),
                ),
              ),

              // ── Car Card ──────────────────────────────────────────────
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Car image
                    if (car?.image != null && car!.image!.isNotEmpty)
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
                                  child: const Icon(Icons.directions_car,
                                      size: 60, color: Colors.black),
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
                    if (car?.image != null) const SizedBox(height: 10),

                    // Car name
                    Text(
                      car?.name ?? '-',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Supplier
                    if (car != null) ...[
                      Row(
                        children: [
                          if (car.supplier.avatar != null &&
                              car.supplier.avatar!.isNotEmpty)
                            Container(
                              width: 36,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: car.supplier.avatar!.startsWith('assets/')
                                  ? Image.asset(
                                      car.supplier.avatar!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.business, size: 14),
                                    )
                                  : Image.network(
                                      car.supplier.avatar!.startsWith('http')
                                          ? car.supplier.avatar!
                                          : '${EnvConfig.cdnUsers}/${car.supplier.avatar}',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.business, size: 14),
                                    ),
                            )
                          else
                            const CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.business,
                                  size: 16, color: Colors.black),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            car.supplier.fullName ?? '',
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Booking Info Card ─────────────────────────────────────
              _buildCard(
                child: Column(
                  children: [
                    _buildDetailRow(
                        AppStrings.t('PICKUP'),
                        booking.pickupLocation?.name ?? '-'),
                    _buildDetailRow(
                        AppStrings.t('DROP_OFF'),
                        booking.dropOffLocation?.name ?? '-'),
                    _buildDetailRow(AppStrings.t('FROM'), _fmtDateTime(from)),
                    _buildDetailRow(AppStrings.t('TO'), _fmtDateTime(to)),
                    _buildDetailRow(
                      '$days ${days == 1 ? AppStrings.t('DAY') : AppStrings.t('DAYS')}',
                      '',
                      isHeader: true,
                    ),
                    _buildDetailRow(
                      AppStrings.t('TOTAL'),
                      booking.price != null
                          ? '\$${booking.price!.toStringAsFixed(2)}'
                          : '-',
                      isBold: true,
                      valueColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Extras Card ───────────────────────────────────────────
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t('EXTRAS'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildExtraDetailRow(
                        AppStrings.t('CANCELLATION'), booking.cancellation),
                    _buildExtraDetailRow(
                        AppStrings.t('AMENDMENTS'), booking.amendments),
                    _buildExtraDetailRow(
                        AppStrings.t('THEFT_PROTECTION'), booking.theftProtection),
                    _buildExtraDetailRow(
                        AppStrings.t('COLLISION_DAMAGE_WAIVER'),
                        booking.collisionDamageWaiver),
                    _buildExtraDetailRow(
                        AppStrings.t('FULL_INSURANCE'), booking.fullInsurance),
                    _buildExtraDetailRow(
                        AppStrings.t('ADDITIONAL_DRIVER'),
                        booking.additionalDriver),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Cancel Button ─────────────────────────────────────────
              if (_isCancelable)
                BcButton(
                  label: AppStrings.t('CANCEL_BOOKING'),
                  isSecondary: true,
                  isLoading: _cancelling,
                  onPress: _cancelling ? null : _cancelBooking,
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

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    bool isHeader = false,
    Color? valueColor,
  }) {
    if (isHeader) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraDetailRow(String label, bool? included) {
    final isTrue = included == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isTrue ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 18,
            color: Colors.black,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isTrue ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            isTrue ? AppStrings.t('INCLUDED') : AppStrings.t('EXCLUDED'),
            style: TextStyle(
              fontSize: 12,
              color:
                  isTrue ? AppColors.extraIncluded : AppColors.extraExcluded,
            ),
          ),
        ],
      ),
    );
  }
}
