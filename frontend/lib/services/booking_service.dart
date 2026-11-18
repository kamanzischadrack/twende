// lib/services/booking_service.dart
import '../core/constants/env_config.dart';
import '../core/mock/mock_data.dart';
import '../core/network/dio_client.dart';
import '../models/booking.dart';
import '../models/notification.dart';
import 'user_service.dart';

class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  final _dio = DioClient.instance.dio;

  /// Complete the checkout process and create the booking.
  Future<int> checkout(Map<String, dynamic> data) async {
    if (EnvConfig.useMockData) {
      return _mockCheckout(data);
    }

    try {
      final res = await _dio.post('/api/checkout', data: data);
      return res.statusCode ?? 0;
    } catch (_) {
      return _mockCheckout(data);
    }
  }

  int _mockCheckout(Map<String, dynamic> data) {
    final carId = data['car'] as String?;
    final car = MockData.cars.firstWhere(
      (c) => c.id == carId,
      orElse: () => MockData.cars.first,
    );
    final pickupLocId = data['pickupLocation'] as String?;
    final dropOffLocId = data['dropOffLocation'] as String?;
    final pickup = MockData.locations.firstWhere(
      (l) => l.id == pickupLocId,
      orElse: () => MockData.locations.first,
    );
    final dropOff = MockData.locations.firstWhere(
      (l) => l.id == dropOffLocId,
      orElse: () => pickup,
    );

    final newBooking = Booking(
      id: 'book-${DateTime.now().millisecondsSinceEpoch}',
      driver: MockData.demoUser,
      car: car,
      pickupLocation: pickup,
      dropOffLocation: dropOff,
      from: data['from'] != null
          ? DateTime.tryParse(data['from'] as String)
          : DateTime.now().add(const Duration(days: 1)),
      to: data['to'] != null
          ? DateTime.tryParse(data['to'] as String)
          : DateTime.now().add(const Duration(days: 4)),
      status: 'Reserved',
      price: (data['price'] as num?)?.toDouble() ?? (car.price * 3),
      cancellation: data['cancellation'] as bool? ?? false,
      amendments: data['amendments'] as bool? ?? false,
      theftProtection: data['theftProtection'] as bool? ?? false,
      collisionDamageWaiver: data['collisionDamageWaiver'] as bool? ?? false,
      fullInsurance: data['fullInsurance'] as bool? ?? false,
      additionalDriver: data['additionalDriver'] as bool? ?? false,
    );
    MockData.addBooking(newBooking);

    // Also add a confirmation notification
    MockData.notifications.insert(
      0,
      AppNotification(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        user: MockData.demoUser.id,
        message: 'Booking confirmed for ${car.name} at ${pickup.name}.',
        isRead: false,
        booking: newBooking.id,
        createdAt: DateTime.now(),
      ),
    );

    return 200;
  }

  /// Get bookings (paginated).
  Future<BookingResult> getBookings({
    required Map<String, dynamic> payload,
    int page = 1,
    int size = 8,
  }) async {
    if (EnvConfig.useMockData) {
      return _getMockBookings(payload, page, size);
    }

    try {
      final language = await UserService.instance.getLanguage();
      final res = await _dio.post(
        '/api/bookings/$page/$size/$language',
        data: payload,
      );
      return BookingResult.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return _getMockBookings(payload, page, size);
    }
  }

  BookingResult _getMockBookings(Map<String, dynamic> payload, int page, int size) {
    var list = List<Booking>.from(MockData.bookings);
    final statuses = payload['statuses'] as List<dynamic>?;
    if (statuses != null && statuses.isNotEmpty) {
      list = list.where((b) => statuses.contains(b.status)).toList();
    }
    final total = list.length;
    final startIndex = (page - 1) * size;
    if (startIndex >= total) {
      return BookingResult(resultData: total, data: []);
    }
    final endIndex = (startIndex + size > total) ? total : (startIndex + size);
    return BookingResult(resultData: total, data: list.sublist(startIndex, endIndex));
  }

  /// Get a single booking by ID.
  Future<Booking> getBooking(String id) async {
    if (EnvConfig.useMockData) {
      return MockData.bookings.firstWhere(
        (b) => b.id == id,
        orElse: () => MockData.bookings.first,
      );
    }

    try {
      final language = await UserService.instance.getLanguage();
      final res = await _dio.get(
        '/api/booking/${Uri.encodeComponent(id)}/$language',
      );
      return Booking.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return MockData.bookings.firstWhere(
        (b) => b.id == id,
        orElse: () => MockData.bookings.first,
      );
    }
  }

  /// Check whether a customer has bookings or not.
  Future<int> hasBookings(String driverId) async {
    if (EnvConfig.useMockData) {
      return MockData.bookings.isNotEmpty ? 200 : 204;
    }

    try {
      final res = await _dio.get(
        '/api/has-bookings/${Uri.encodeComponent(driverId)}',
      );
      return res.statusCode ?? 0;
    } catch (_) {
      return MockData.bookings.isNotEmpty ? 200 : 204;
    }
  }

  /// Cancel a booking.
  Future<int> cancel(String bookingId) async {
    if (EnvConfig.useMockData) {
      MockData.cancelBooking(bookingId);
      return 200;
    }

    try {
      final res = await _dio.post(
        '/api/cancel-booking/${Uri.encodeComponent(bookingId)}',
      );
      return res.statusCode ?? 0;
    } catch (_) {
      MockData.cancelBooking(bookingId);
      return 200;
    }
  }
}
