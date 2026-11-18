// lib/screens/cars/cars_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/car_filter.dart';
import '../../providers/car_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/car_card.dart';
import '../../widgets/car_filter_panel.dart';
import '../../widgets/custom_drawer.dart';

class CarsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? params;

  const CarsScreen({super.key, this.params});

  @override
  ConsumerState<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends ConsumerState<CarsScreen> {
  final _scrollController = ScrollController();
  bool _showFilters = false;
  String _pickupLocationName = '';

  String? _pickupLocation;
  String? _dropOffLocation;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSearch();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(carListProvider.notifier).loadMore();
    }
  }

  void _initSearch() {
    final state = GoRouterState.of(context);
    final queryParams = state.uri.queryParameters;
    final params = widget.params ?? queryParams;

    final pickup = params['pickupLocation'] as String?;
    final dropOff = params['dropOffLocation'] as String?;
    final fromMs = int.tryParse(params['from']?.toString() ?? '');
    final toMs = int.tryParse(params['to']?.toString() ?? '');

    if (pickup != null && dropOff != null && fromMs != null && toMs != null) {
      _pickupLocation = pickup;
      _dropOffLocation = dropOff;
      _fromDate = DateTime.fromMillisecondsSinceEpoch(fromMs);
      _toDate = DateTime.fromMillisecondsSinceEpoch(toMs);

      _loadLocationName(pickup);

      final searchParams = CarSearchParams(
        pickupLocationId: pickup,
        dropOffLocationId: dropOff,
        from: _fromDate!,
        to: _toDate!,
      );

      ref.read(carListProvider.notifier).search(searchParams);
    }
  }

  Future<void> _loadLocationName(String id) async {
    try {
      final loc = await LocationService.instance.getLocation(id);
      if (mounted) {
        setState(() {
          _pickupLocationName = loc.name ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _handleRefresh() async {
    final searchParams = ref.read(carListProvider).searchParams;
    if (searchParams != null) {
      await ref.read(carListProvider.notifier).search(searchParams);
    }
  }

  @override
  Widget build(BuildContext context) {
    final carState = ref.watch(carListProvider);
    final count = carState.cars.length;

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: const AppHeader(title: 'Cars'),
      drawer: const CustomDrawer(currentRoute: '/cars'),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Filter Toggle & Info Bar
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Toggle Filter Button
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showFilters = !_showFilters;
                            });
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.filter_list,
                                  color: Colors.black,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _showFilters ? 'HIDE FILTERS' : 'SHOW FILTERS',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Filter Panel
                        if (_showFilters) ...[
                          const SizedBox(height: 10),
                          CarFilterPanel(
                            initialFilter: carState.searchParams?.filter ?? const CarFilter(),
                            onApply: (filter) {
                              setState(() {
                                _showFilters = false;
                              });
                              ref.read(carListProvider.notifier).applyFilter(filter);
                            },
                            onReset: () {
                              setState(() {
                                _showFilters = false;
                              });
                              ref.read(carListProvider.notifier).applyFilter(const CarFilter());
                            },
                          ),
                        ],

                        // Cars Count Header
                        if (!carState.isLoading || count > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 4, left: 4),
                            child: Text(
                              '($count ${count == 1 ? 'car available' : 'cars available'})',
                              style: const TextStyle(
                                color: Color(0xFF717171),
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Car Cards or Empty/Loading State
            if (carState.isLoading && count == 0)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (count == 0)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.directions_car_outlined,
                          size: 64,
                          color: Colors.black,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No cars available for these dates and locations.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => context.go('/'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Modify Search',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == count) {
                      return carState.hasMore
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const SizedBox(height: 30);
                    }

                    final car = carState.cars[index];
                    return Center(
                      child: CarCard(
                        car: car,
                        from: _fromDate,
                        to: _toDate,
                        pickupLocation: _pickupLocation,
                        dropOffLocation: _dropOffLocation,
                        pickupLocationName: _pickupLocationName,
                      ),
                    );
                  },
                  childCount: count + (carState.hasMore ? 1 : 0),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
