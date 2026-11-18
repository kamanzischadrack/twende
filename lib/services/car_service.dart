// lib/services/car_service.dart
import '../core/constants/app_constants.dart';
import '../core/constants/env_config.dart';
import '../core/mock/mock_data.dart';
import '../core/network/dio_client.dart';
import '../models/car.dart';
import '../models/car_filter.dart';
import 'user_service.dart';

class CarService {
  CarService._();
  static final CarService instance = CarService._();

  final _dio = DioClient.instance.dio;

  /// Get paginated cars list.
  Future<CarResult> getCars({
    required String pickupLocation,
    required String dropOffLocation,
    required DateTime from,
    required DateTime to,
    CarFilter? filter,
    int page = 1,
    int size = 8,
  }) async {
    if (EnvConfig.useMockData) {
      return _filterMockCars(filter, page, size);
    }

    try {
      final lang = await UserService.instance.getLanguage();

      final data = {
        'pickupLocation': pickupLocation,
        'dropOffLocation': dropOffLocation,
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
        'language': lang,
        if (filter != null) ...filter.toJson(),
      };

      final res = await _dio.post('/api/frontend-cars/$page/$size', data: data);
      return CarResult.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return _filterMockCars(filter, page, size);
    }
  }

  CarResult _filterMockCars(CarFilter? filter, int page, int size) {
    var filtered = List<Car>.from(MockData.cars);

    if (filter != null) {
      if (filter.carTypes != null && filter.carTypes!.isNotEmpty) {
        filtered = filtered.where((c) => filter.carTypes!.contains(c.type)).toList();
      }
      if (filter.gearboxes != null && filter.gearboxes!.isNotEmpty) {
        filtered = filtered.where((c) => filter.gearboxes!.contains(c.gearbox)).toList();
      }
      if (filter.fuelPolicies != null && filter.fuelPolicies!.isNotEmpty) {
        filtered = filtered.where((c) => filter.fuelPolicies!.contains(c.fuelPolicy)).toList();
      }
      if (filter.mileages != null && filter.mileages!.isNotEmpty) {
        filtered = filtered.where((c) {
          final isUnlimited = c.mileage < 0;
          final mileageStr = isUnlimited ? Mileage.unlimited : Mileage.limited;
          return filter.mileages!.contains(mileageStr);
        }).toList();
      }
      if (filter.deposit != null) {
        filtered = filtered.where((c) => c.deposit <= filter.deposit!).toList();
      }
      if (filter.suppliers != null && filter.suppliers!.isNotEmpty) {
        filtered = filtered.where((c) => filter.suppliers!.contains(c.supplier.id)).toList();
      }
      if (filter.seats != null) {
        filtered = filtered.where((c) => c.seats >= filter.seats!).toList();
      }
      if (filter.multimedia == true) {
        filtered = filtered.where((c) => c.multimedia).toList();
      }
      if (filter.rating != null) {
        filtered = filtered.where((c) => (c.rating ?? 0) >= filter.rating!).toList();
      }
    }

    final total = filtered.length;
    final startIndex = (page - 1) * size;
    if (startIndex >= total) {
      return CarResult(resultData: total, data: []);
    }
    final endIndex = (startIndex + size > total) ? total : (startIndex + size);
    final paged = filtered.sublist(startIndex, endIndex);

    return CarResult(resultData: total, data: paged);
  }

  /// Get a car by ID.
  Future<Car> getCar(String id) async {
    if (EnvConfig.useMockData) {
      return MockData.cars.firstWhere(
        (c) => c.id == id,
        orElse: () => MockData.cars.first,
      );
    }

    try {
      final lang = await UserService.instance.getLanguage();
      final res = await _dio.get(
        '/api/car/${Uri.encodeComponent(id)}/$lang',
      );
      return Car.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return MockData.cars.firstWhere(
        (c) => c.id == id,
        orElse: () => MockData.cars.first,
      );
    }
  }
}
