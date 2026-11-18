// lib/models/user.dart

class User {
  final String? id;
  final String? email;
  final String? fullName;
  final String? phone;
  final String? avatar;
  final String? language;
  final String? role;
  final List<String> roles;
  final String? branchId;
  final List<String> branchIds;
  final bool? enableEmailNotifications;
  final String? accessToken;
  final bool? blacklisted;
  final DateTime? birthDate;
  final String? license;
  final String? bio;
  final String? location;

  const User({
    this.id,
    this.email,
    this.fullName,
    this.phone,
    this.avatar,
    this.language,
    this.role,
    this.roles = const [],
    this.branchId,
    this.branchIds = const [],
    this.enableEmailNotifications,
    this.accessToken,
    this.blacklisted,
    this.birthDate,
    this.license,
    this.bio,
    this.location,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['_id'] as String?,
        email: json['email'] as String?,
        fullName: json['fullName'] as String?,
        phone: json['phone'] as String?,
        avatar: json['avatar'] as String?,
        language: json['language'] as String?,
        role: json['role'] as String? ?? 'staff',
        roles: (json['roles'] as List<dynamic>?)
                ?.map((value) => value.toString())
                .toList() ??
            const [],
        branchId: json['branchId'] as String?,
        branchIds: (json['branchIds'] as List<dynamic>?)
                ?.map((value) => value.toString())
                .toList() ??
            const [],
        enableEmailNotifications: json['enableEmailNotifications'] as bool?,
        accessToken: json['accessToken'] as String?,
        blacklisted: json['blacklisted'] as bool?,
        birthDate: json['birthDate'] != null
            ? DateTime.tryParse(json['birthDate'] as String)
            : null,
        license: json['license'] as String?,
        bio: json['bio'] as String?,
        location: json['location'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        if (email != null) 'email': email,
        if (fullName != null) 'fullName': fullName,
        if (phone != null) 'phone': phone,
        if (avatar != null) 'avatar': avatar,
        if (language != null) 'language': language,
        if (role != null) 'role': role,
        if (roles.isNotEmpty) 'roles': roles,
        if (branchId != null) 'branchId': branchId,
        if (branchIds.isNotEmpty) 'branchIds': branchIds,
        if (enableEmailNotifications != null)
          'enableEmailNotifications': enableEmailNotifications,
        if (accessToken != null) 'accessToken': accessToken,
        if (blacklisted != null) 'blacklisted': blacklisted,
        if (birthDate != null) 'birthDate': birthDate!.toIso8601String(),
        if (license != null) 'license': license,
        if (bio != null) 'bio': bio,
        if (location != null) 'location': location,
      };

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatar,
    String? language,
    String? role,
    List<String>? roles,
    String? branchId,
    List<String>? branchIds,
    bool? enableEmailNotifications,
    String? accessToken,
    bool? blacklisted,
    DateTime? birthDate,
    String? license,
    String? bio,
    String? location,
  }) =>
      User(
        id: id ?? this.id,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        avatar: avatar ?? this.avatar,
        language: language ?? this.language,
        role: role ?? this.role,
        roles: roles ?? this.roles,
        branchId: branchId ?? this.branchId,
        branchIds: branchIds ?? this.branchIds,
        enableEmailNotifications:
            enableEmailNotifications ?? this.enableEmailNotifications,
        accessToken: accessToken ?? this.accessToken,
        blacklisted: blacklisted ?? this.blacklisted,
        birthDate: birthDate ?? this.birthDate,
        license: license ?? this.license,
        bio: bio ?? this.bio,
        location: location ?? this.location,
      );
}
