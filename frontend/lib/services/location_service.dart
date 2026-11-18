// lib/services/location_service.dart
import '../core/constants/env_config.dart';
import '../core/mock/mock_data.dart';
import '../core/network/dio_client.dart';
import '../models/location.dart';
import 'user_service.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  final _dio = DioClient.instance.dio;

  /// Search locations by keyword.
  Future<List<Location>> searchLocations(String keyword) async {
    if (EnvConfig.useMockData) {
      final lower = keyword.toLowerCase();
      return MockData.locations.where((l) {
        final nameMatches = (l.name ?? '').toLowerCase().contains(lower);
        final valMatches = l.values?.any((v) => v.value.toLowerCase().contains(lower)) ?? false;
        return nameMatches || valMatches;
      }).toList();
    }

    try {
      final lang = await UserService.instance.getLanguage();
      final res = await _dio.get(
        '/api/check-location/${Uri.encodeComponent(keyword)}/$lang',
      );
      return (res.data as List<dynamic>)
          .map((l) => Location.fromJson(l as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final lower = keyword.toLowerCase();
      return MockData.locations.where((l) {
        final nameMatches = (l.name ?? '').toLowerCase().contains(lower);
        final valMatches = l.values?.any((v) => v.value.toLowerCase().contains(lower)) ?? false;
        return nameMatches || valMatches;
      }).toList();
    }
  }

  /// Get a location by ID.
  Future<Location> getLocation(String id) async {
    if (EnvConfig.useMockData) {
      return MockData.locations.firstWhere(
        (l) => l.id == id,
        orElse: () => MockData.locations.first,
      );
    }

    try {
      final lang = await UserService.instance.getLanguage();
      final res = await _dio.get(
        '/api/location/${Uri.encodeComponent(id)}/$lang',
      );
      return Location.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return MockData.locations.firstWhere(
        (l) => l.id == id,
        orElse: () => MockData.locations.first,
      );
    }
  }

  /// Get all locations.
  Future<List<Location>> getLocations() async {
    if (EnvConfig.useMockData) {
      return List.unmodifiable(MockData.locations);
    }

    try {
      final lang = await UserService.instance.getLanguage();
      final res = await _dio.get('/api/locations/$lang');
      return (res.data as List<dynamic>)
          .map((l) => Location.fromJson(l as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return List.unmodifiable(MockData.locations);
    }
  }
}
