// lib/models/car.dart
import 'supplier.dart';

class Car {
  final String id;
  final String name;
  final Supplier supplier;
  final String? image;
  final double price;
  final String? pickupLocation;
  final String? dropOffLocation;
  final String type;         // CarType enum value
  final String gearbox;      // GearboxType enum value
  final bool aircon;
  final int seats;
  final int doors;
  final String fuelPolicy;   // FuelPolicy enum value
  final double mileage;
  final double deposit;
  final bool available;
  final String? description;
  final double? rating;
  final int trips;
  final bool multimedia;
  final bool? heavyBag;
  final bool? suitcases;
  final String? range;        // CarRange enum value
  final int cancellation;     // -1: excluded, 0: free, >0: paid
  final int amendments;
  final int theftProtection;
  final int collisionDamageWaiver;
  final int fullInsurance;
  final int additionalDriver;
  final int? co2;
  final bool comingSoon;
  final bool fullyBooked;

  const Car({
    required this.id,
    this.name = '',
    this.supplier = const Supplier(id: '', fullName: ''),
    this.image,
    this.price = 0.0,
    this.pickupLocation,
    this.dropOffLocation,
    this.type = 'gasoline',
    this.gearbox = 'manual',
    this.aircon = false,
    this.seats = 5,
    this.doors = 4,
    this.fuelPolicy = 'likeForLike',
    this.mileage = -1,
    this.deposit = 0.0,
    this.available = true,
    this.description,
    this.rating,
    this.trips = 0,
    this.multimedia = false,
    this.heavyBag,
    this.suitcases,
    this.range,
    this.cancellation = -1,
    this.amendments = -1,
    this.theftProtection = -1,
    this.collisionDamageWaiver = -1,
    this.fullInsurance = -1,
    this.additionalDriver = -1,
    this.co2,
    this.comingSoon = false,
    this.fullyBooked = false,
  });

  factory Car.fromJson(Map<String, dynamic> json) => Car(
        id: json['_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        supplier: json['supplier'] is Map<String, dynamic>
            ? Supplier.fromJson(json['supplier'] as Map<String, dynamic>)
            : const Supplier(id: '', fullName: ''),
        image: json['image'] as String?,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        pickupLocation: json['pickupLocation'] as String?,
        dropOffLocation: json['dropOffLocation'] as String?,
        type: json['type'] as String? ?? 'gasoline',
        gearbox: json['gearbox'] as String? ?? 'manual',
        aircon: json['aircon'] == true || json['aircon'] == 'true',
        seats: json['seats'] as int? ?? 5,
        doors: json['doors'] as int? ?? 4,
        fuelPolicy: json['fuelPolicy'] as String? ?? 'likeForLike',
        mileage: (json['mileage'] as num?)?.toDouble() ?? -1,
        deposit: (json['deposit'] as num?)?.toDouble() ?? 0.0,
        available: json['available'] as bool? ?? true,
        description: json['description'] as String?,
        rating: (json['rating'] as num?)?.toDouble(),
        trips: json['trips'] as int? ?? 0,
        multimedia: json['multimedia'] as bool? ?? false,
        heavyBag: json['heavyBag'] as bool?,
        suitcases: json['suitcases'] as bool?,
        range: json['range'] as String?,
        cancellation: json['cancellation'] as int? ?? -1,
        amendments: json['amendments'] as int? ?? -1,
        theftProtection: json['theftProtection'] as int? ?? -1,
        collisionDamageWaiver: json['collisionDamageWaiver'] as int? ?? -1,
        fullInsurance: json['fullInsurance'] as int? ?? -1,
        additionalDriver: json['additionalDriver'] as int? ?? -1,
        co2: json['co2'] as int?,
        comingSoon: json['comingSoon'] as bool? ?? false,
        fullyBooked: json['fullyBooked'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'supplier': supplier.toJson(),
        if (image != null) 'image': image,
        'price': price,
        'type': type,
        'gearbox': gearbox,
        'aircon': aircon,
        'seats': seats,
        'doors': doors,
        'fuelPolicy': fuelPolicy,
        'mileage': mileage,
        'deposit': deposit,
        'available': available,
        if (rating != null) 'rating': rating,
        'trips': trips,
        'multimedia': multimedia,
        if (range != null) 'range': range,
        'cancellation': cancellation,
        'amendments': amendments,
        'theftProtection': theftProtection,
        'collisionDamageWaiver': collisionDamageWaiver,
        'fullInsurance': fullInsurance,
        'additionalDriver': additionalDriver,
        if (co2 != null) 'co2': co2,
        'comingSoon': comingSoon,
        'fullyBooked': fullyBooked,
      };
}

class CarResult {
  final int resultData;
  final List<Car> data;

  const CarResult({required this.resultData, required this.data});

  factory CarResult.fromJson(Map<String, dynamic> json) => CarResult(
        resultData: json['resultData'] as int? ?? 0,
        data: (json['data'] as List<dynamic>?)
                ?.map((c) => Car.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
