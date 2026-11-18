// lib/models/notification.dart

class AppNotification {
  final String id;
  final String? user;
  final String? message;
  final bool? isRead;
  final String? booking;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    this.user,
    this.message,
    this.isRead,
    this.booking,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['_id'] as String,
        user: json['user'] as String?,
        message: json['message'] as String?,
        isRead: json['isRead'] as bool?,
        booking: json['booking'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}

class NotificationResult {
  final int resultData;
  final List<AppNotification> data;

  const NotificationResult({required this.resultData, required this.data});

  factory NotificationResult.fromJson(Map<String, dynamic> json) =>
      NotificationResult(
        resultData: json['resultData'] as int? ?? 0,
        data: (json['data'] as List<dynamic>?)
                ?.map((n) =>
                    AppNotification.fromJson(n as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
