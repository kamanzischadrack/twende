// lib/models/location.dart

class LocationValue {
  final String language;
  final String value;

  const LocationValue({required this.language, required this.value});

  factory LocationValue.fromJson(Map<String, dynamic> json) => LocationValue(
        language: json['language'] as String,
        value: json['value'] as String,
      );

  Map<String, dynamic> toJson() => {
        'language': language,
        'value': value,
      };
}

class Location {
  final String id;
  final String? name;
  final List<LocationValue>? values;
  final String? image;
  final double? latitude;
  final double? longitude;

  const Location({
    required this.id,
    this.name,
    this.values,
    this.image,
    this.latitude,
    this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        id: json['_id'] as String,
        name: json['name'] as String?,
        values: (json['values'] as List<dynamic>?)
            ?.map((v) => LocationValue.fromJson(v as Map<String, dynamic>))
            .toList(),
        image: json['image'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        if (name != null) 'name': name,
        if (values != null) 'values': values!.map((v) => v.toJson()).toList(),
        if (image != null) 'image': image,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
}
