// lib/services/notification_service.dart
import '../core/constants/env_config.dart';
import '../core/mock/mock_data.dart';
import '../core/network/dio_client.dart';
import '../models/notification.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _dio = DioClient.instance.dio;

  /// Get user notifications (paginated).
  Future<NotificationResult> getNotifications({
    required String userId,
    int page = 1,
    int size = 20,
  }) async {
    if (EnvConfig.useMockData) {
      final notifs = MockData.notifications;
      return NotificationResult(resultData: notifs.length, data: notifs);
    }

    try {
      final res = await _dio.get(
        '/api/notifications/${Uri.encodeComponent(userId)}/$page/$size',
      );
      return NotificationResult.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      final notifs = MockData.notifications;
      return NotificationResult(resultData: notifs.length, data: notifs);
    }
  }

  /// Get unread notification count.
  Future<int> getNotificationCounter(String userId) async {
    if (EnvConfig.useMockData) {
      return MockData.notifications.where((n) => n.isRead != true).length;
    }

    try {
      final res = await _dio.get(
        '/api/notification-counter/${Uri.encodeComponent(userId)}',
      );
      return res.data as int? ?? 0;
    } catch (_) {
      return MockData.notifications.where((n) => n.isRead != true).length;
    }
  }

  /// Mark a notification as read.
  Future<int> markAsRead(String notificationId) async {
    if (EnvConfig.useMockData) {
      MockData.markNotificationRead(notificationId);
      return 200;
    }

    try {
      final res = await _dio.post(
        '/api/mark-notifications-as-read',
        data: {'ids': [notificationId]},
      );
      return res.statusCode ?? 0;
    } catch (_) {
      MockData.markNotificationRead(notificationId);
      return 200;
    }
  }

  /// Mark all notifications as read.
  Future<int> markAllAsRead(String userId) async {
    if (EnvConfig.useMockData) {
      MockData.markAllNotificationsRead();
      return 200;
    }

    try {
      final res = await _dio.post(
        '/api/mark-all-notifications-as-read/${Uri.encodeComponent(userId)}',
      );
      return res.statusCode ?? 0;
    } catch (_) {
      MockData.markAllNotificationsRead();
      return 200;
    }
  }

  /// Delete a notification.
  Future<int> deleteNotification(String notificationId) async {
    if (EnvConfig.useMockData) {
      MockData.deleteNotification(notificationId);
      return 200;
    }

    try {
      final res = await _dio.delete(
        '/api/delete-notification/${Uri.encodeComponent(notificationId)}',
      );
      return res.statusCode ?? 0;
    } catch (_) {
      MockData.deleteNotification(notificationId);
      return 200;
    }
  }
}
