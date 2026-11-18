// lib/models/booking.dart
import 'car.dart';
import 'location.dart';
import 'user.dart';

class Booking {
  final String id;
  final User? driver;
  final Car? car;
  final Location? pickupLocation;
  final Location? dropOffLocation;
  final DateTime? from;
  final DateTime? to;
  final String status; // BookingStatus enum value
  final bool? cancellation;
  final bool? amendments;
  final bool? theftProtection;
  final bool? collisionDamageWaiver;
  final bool? fullInsurance;
  final bool? additionalDriver;
  final double? price;
  final String? sessionId;
  final String? paymentIntentId;
  final String? customerId;
  final DateTime? cancelRequest;

  const Booking({
    required this.id,
    this.driver,
    this.car,
    this.pickupLocation,
    this.dropOffLocation,
    this.from,
    this.to,
    required this.status,
    this.cancellation,
    this.amendments,
    this.theftProtection,
    this.collisionDamageWaiver,
    this.fullInsurance,
    this.additionalDriver,
    this.price,
    this.sessionId,
    this.paymentIntentId,
    this.customerId,
    this.cancelRequest,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['_id'] as String,
        driver: json['driver'] != null
            ? User.fromJson(json['driver'] as Map<String, dynamic>)
            : null,
        car: json['car'] != null
            ? Car.fromJson(json['car'] as Map<String, dynamic>)
            : null,
        pickupLocation: json['pickupLocation'] != null
            ? Location.fromJson(json['pickupLocation'] as Map<String, dynamic>)
            : null,
        dropOffLocation: json['dropOffLocation'] != null
            ? Location.fromJson(json['dropOffLocation'] as Map<String, dynamic>)
            : null,
        from: json['from'] != null
            ? DateTime.tryParse(json['from'] as String)
            : null,
        to: json['to'] != null
            ? DateTime.tryParse(json['to'] as String)
            : null,
        status: json['status'] as String,
        cancellation: json['cancellation'] as bool?,
        amendments: json['amendments'] as bool?,
        theftProtection: json['theftProtection'] as bool?,
        collisionDamageWaiver: json['collisionDamageWaiver'] as bool?,
        fullInsurance: json['fullInsurance'] as bool?,
        additionalDriver: json['additionalDriver'] as bool?,
        price: (json['price'] as num?)?.toDouble(),
        sessionId: json['sessionId'] as String?,
        paymentIntentId: json['paymentIntentId'] as String?,
        customerId: json['customerId'] as String?,
        cancelRequest: json['cancelRequest'] != null
            ? DateTime.tryParse(json['cancelRequest'] as String)
            : null,
      );
}

class BookingResult {
  final int resultData;
  final List<Booking> data;

  const BookingResult({required this.resultData, required this.data});

  factory BookingResult.fromJson(Map<String, dynamic> json) => BookingResult(
        resultData: json['resultData'] as int? ?? 0,
        data: (json['data'] as List<dynamic>?)
                ?.map((b) => Booking.fromJson(b as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
