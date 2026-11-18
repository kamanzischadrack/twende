// lib/screens/bookings/bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/booking_status_badge.dart';
import '../../widgets/custom_drawer.dart';

const _allStatuses = [
  'Void',
  'Pending',
  'Deposit',
  'Paid',
  'PaidInFull',
  'Reserved',
  'Cancelled',
];

const _pageSize = 8;

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  final _scrollController = ScrollController();

  List<Booking> _bookings = [];
  int _page = 1;
  int _totalCount = 0;
  bool _loadingInitial = true;
  bool _loadingMore = false;
  String? _error;

  // Filter: null = All
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBookings(reset: true));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _bookings.length < _totalCount) {
      _loadMore();
    }
  }

  List<String> get _statusFilter =>
      _selectedStatus != null ? [_selectedStatus!] : _allStatuses;

  Future<void> _loadBookings({bool reset = false}) async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user?.id == null) {
      if (mounted) {
        try {
          context.go('/sign-in?redirect=/bookings');
        } catch (_) {}
        setState(() => _loadingInitial = false);
      }
      return;
    }
    final userId = authState.user!.id!;

    if (reset) {
      setState(() {
        _loadingInitial = true;
        _error = null;
        _page = 1;
        _bookings = [];
      });
    }

    try {
      final result = await BookingService.instance.getBookings(
        payload: {
          'user': userId,
          'statuses': _statusFilter,
        },
        page: 1,
        size: _pageSize,
      );

      if (mounted) {
        setState(() {
          _bookings = result.data;
          _totalCount = result.resultData;
          _page = 1;
          _loadingInitial = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppStrings.t('GENERIC_ERROR');
          _loadingInitial = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user?.id == null) return;
    final userId = authState.user!.id!;

    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final result = await BookingService.instance.getBookings(
        payload: {
          'user': userId,
          'statuses': _statusFilter,
        },
        page: nextPage,
        size: _pageSize,
      );

      if (mounted) {
        setState(() {
          _bookings.addAll(result.data);
          _totalCount = result.resultData;
          _page = nextPage;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '-';
    try {
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppHeader(title: AppStrings.t('MY_BOOKINGS')),
      drawer: const CustomDrawer(currentRoute: '/bookings'),
      body: Column(
        children: [
          // ── Status Filter Chips ───────────────────────────────────
          _buildFilterChips(),

          // ── Main content ──────────────────────────────────────────
          Expanded(
            child: _loadingInitial
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.error)))
                    : _bookings.isEmpty
                        ? Center(
                            child: Text(
                            AppStrings.t('NO_BOOKINGS'),
                            style: const TextStyle(
                                fontSize: 15, color: AppColors.textSecondary),
                          ))
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: () => _loadBookings(reset: true),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(12),
                              itemCount: _bookings.length + (_loadingMore ? 1 : 0),
                              itemBuilder: (ctx, i) {
                                if (i == _bookings.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                          color: AppColors.primary),
                                    ),
                                  );
                                }
                                return _buildBookingCard(_bookings[i]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final statuses = [null, ..._allStatuses];
    return Container(
      height: 48,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (ctx, i) {
          final status = statuses[i];
          final isSelected = _selectedStatus == status;
          final label = status == null
              ? AppStrings.t('ALL')
              : AppStrings.t('BOOKING_STATUS_${status.toUpperCase()}');

          return GestureDetector(
            onTap: () {
              setState(() => _selectedStatus = status);
              _loadBookings(reset: true);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final car = booking.car;
    final carName = car?.name ?? '-';
    final pickupName = booking.pickupLocation?.name ?? '-';
    final dropOffName = booking.dropOffLocation?.name ?? '-';
    final fromStr = _fmtDate(booking.from);
    final toStr = _fmtDate(booking.to);
    final price = booking.price != null
        ? '\$${booking.price!.toStringAsFixed(2)}'
        : '-';

    return GestureDetector(
      onTap: () => context.push('/booking/${booking.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: car name + status badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    carName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                BookingStatusBadge(status: booking.status),
              ],
            ),
            const SizedBox(height: 8),

            // Locations
            _buildCardRow(Icons.flight_takeoff, '$pickupName → $dropOffName'),
            const SizedBox(height: 4),

            // Dates
            _buildCardRow(Icons.date_range, '$fromStr → $toStr'),
            const SizedBox(height: 8),

            // Price aligned right
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                price,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.black),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
