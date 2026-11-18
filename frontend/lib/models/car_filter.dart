// lib/models/car_filter.dart

class CarFilter {
  final List<String>? suppliers;
  final List<String>? carTypes;
  final List<String>? gearboxes;
  final List<String>? fuelPolicies;
  final List<String>? mileages;
  final double? deposit;
  final List<String>? ranges;
  final int? seats;
  final bool? multimedia;
  final double? rating;

  const CarFilter({
    this.suppliers,
    this.carTypes,
    this.gearboxes,
    this.fuelPolicies,
    this.mileages,
    this.deposit,
    this.ranges,
    this.seats,
    this.multimedia,
    this.rating,
  });

  List<String>? get carType => carTypes;
  List<String>? get gearbox => gearboxes;
  List<String>? get fuelPolicy => fuelPolicies;
  List<String>? get mileage => mileages;

  Map<String, dynamic> toJson() => {
        if (suppliers != null) 'suppliers': suppliers,
        if (carTypes != null) 'carType': carTypes,
        if (gearboxes != null) 'gearbox': gearboxes,
        if (fuelPolicies != null) 'fuelPolicy': fuelPolicies,
        if (mileages != null) 'mileage': mileages,
        if (deposit != null) 'deposit': deposit,
        if (ranges != null) 'ranges': ranges,
        if (seats != null) 'seats': seats,
        if (multimedia != null) 'multimedia': multimedia,
        if (rating != null) 'rating': rating,
      };

  CarFilter copyWith({
    List<String>? suppliers,
    List<String>? carTypes,
    List<String>? gearboxes,
    List<String>? fuelPolicies,
    List<String>? mileages,
    double? deposit,
    List<String>? ranges,
    int? seats,
    bool? multimedia,
    double? rating,
  }) =>
      CarFilter(
        suppliers: suppliers ?? this.suppliers,
        carTypes: carTypes ?? this.carTypes,
        gearboxes: gearboxes ?? this.gearboxes,
        fuelPolicies: fuelPolicies ?? this.fuelPolicies,
        mileages: mileages ?? this.mileages,
        deposit: deposit ?? this.deposit,
        ranges: ranges ?? this.ranges,
        seats: seats ?? this.seats,
        multimedia: multimedia ?? this.multimedia,
        rating: rating ?? this.rating,
      );
}
