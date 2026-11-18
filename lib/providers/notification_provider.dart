// lib/providers/notification_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final int unreadCount;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.unreadCount = 0,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    int? unreadCount,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) =>
      NotificationState(
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
        unreadCount: unreadCount ?? this.unreadCount,
        hasMore: hasMore ?? this.hasMore,
        currentPage: currentPage ?? this.currentPage,
        error: error ?? this.error,
      );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier(this._userId) : super(const NotificationState()) {
    if (_userId != null) {
      loadUnreadCount();
    }
  }

  final String? _userId;
  static const int _pageSize = 20;

  Future<void> loadUnreadCount() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final count =
          await NotificationService.instance.getNotificationCounter(userId);
      state = state.copyWith(unreadCount: count);
    } catch (_) {}
  }

  Future<void> loadNotifications() async {
    final userId = _userId;
    if (userId == null) return;
    state = const NotificationState(isLoading: true);
    try {
      final result = await NotificationService.instance.getNotifications(
        userId: userId,
        page: 1,
        size: _pageSize,
      );
      state = state.copyWith(
        notifications: result.data,
        hasMore: result.data.length >= _pageSize,
        currentPage: 1,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _userId;
    if (userId == null) return;
    await NotificationService.instance.markAllAsRead(userId);
    state = state.copyWith(
      unreadCount: 0,
      notifications: state.notifications
          .map((n) => AppNotification(
                id: n.id,
                user: n.user,
                message: n.message,
                isRead: true,
                booking: n.booking,
                createdAt: n.createdAt,
              ))
          .toList(),
    );
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  return NotificationNotifier(userId);
});

final unreadCountProvider = Provider<int>(
  (ref) => ref.watch(notificationProvider).unreadCount,
);

final notificationCountProvider = unreadCountProvider;
