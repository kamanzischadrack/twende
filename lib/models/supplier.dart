// lib/models/supplier.dart

class Supplier {
  final String id;
  final String? fullName;
  final String? avatar;
  final String? email;
  final String? phone;
  final String? location;
  final String? bio;
  final String? payLater;

  const Supplier({
    required this.id,
    this.fullName,
    this.avatar,
    this.email,
    this.phone,
    this.location,
    this.bio,
    this.payLater,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
        id: (json['_id'] ?? json['id']) as String,
        fullName: json['fullName'] as String?,
        avatar: json['avatar'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        location: json['location'] as String?,
        bio: json['bio'] as String?,
        payLater: json['payLater']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        if (fullName != null) 'fullName': fullName,
        if (avatar != null) 'avatar': avatar,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (location != null) 'location': location,
        if (bio != null) 'bio': bio,
      };
}
