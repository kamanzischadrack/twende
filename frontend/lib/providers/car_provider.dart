// lib/providers/car_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/car.dart';
import '../models/car_filter.dart';
import '../services/car_service.dart';

// ---------------------------------------------------------------------------
// Search params
// ---------------------------------------------------------------------------

class CarSearchParams {
  final String pickupLocationId;
  final String dropOffLocationId;
  final DateTime from;
  final DateTime to;
  final CarFilter filter;

  const CarSearchParams({
    required this.pickupLocationId,
    required this.dropOffLocationId,
    required this.from,
    required this.to,
    this.filter = const CarFilter(),
  });

  CarSearchParams copyWith({
    String? pickupLocationId,
    String? dropOffLocationId,
    DateTime? from,
    DateTime? to,
    CarFilter? filter,
  }) =>
      CarSearchParams(
        pickupLocationId: pickupLocationId ?? this.pickupLocationId,
        dropOffLocationId: dropOffLocationId ?? this.dropOffLocationId,
        from: from ?? this.from,
        to: to ?? this.to,
        filter: filter ?? this.filter,
      );
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class CarListState {
  final List<Car> cars;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final int totalCount;
  final String? error;
  final CarSearchParams? searchParams;

  const CarListState({
    this.cars = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.totalCount = 0,
    this.error,
    this.searchParams,
  });

  CarListState copyWith({
    List<Car>? cars,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    int? totalCount,
    String? error,
    CarSearchParams? searchParams,
    bool clearError = false,
  }) =>
      CarListState(
        cars: cars ?? this.cars,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        currentPage: currentPage ?? this.currentPage,
        totalCount: totalCount ?? this.totalCount,
        error: clearError ? null : (error ?? this.error),
        searchParams: searchParams ?? this.searchParams,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class CarListNotifier extends StateNotifier<CarListState> {
  CarListNotifier() : super(const CarListState());

  static const int _pageSize = 8;

  Future<void> search(CarSearchParams params) async {
    state = CarListState(searchParams: params, isLoading: true);
    try {
      final result = await CarService.instance.getCars(
        pickupLocation: params.pickupLocationId,
        dropOffLocation: params.dropOffLocationId,
        from: params.from,
        to: params.to,
        filter: params.filter,
        page: 1,
        size: _pageSize,
      );
      state = state.copyWith(
        cars: result.data,
        totalCount: result.resultData,
        hasMore: result.data.length >= _pageSize,
        currentPage: 1,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.searchParams == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final result = await CarService.instance.getCars(
        pickupLocation: state.searchParams!.pickupLocationId,
        dropOffLocation: state.searchParams!.dropOffLocationId,
        from: state.searchParams!.from,
        to: state.searchParams!.to,
        filter: state.searchParams!.filter,
        page: nextPage,
        size: _pageSize,
      );
      state = state.copyWith(
        cars: [...state.cars, ...result.data],
        hasMore: result.data.length >= _pageSize,
        currentPage: nextPage,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void applyFilter(CarFilter filter) {
    if (state.searchParams == null) return;
    search(state.searchParams!.copyWith(filter: filter));
  }

  void reset() {
    state = const CarListState();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final carListProvider =
    StateNotifierProvider<CarListNotifier, CarListState>(
  (ref) => CarListNotifier(),
);
