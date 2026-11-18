// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../models/notification.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bc_button.dart';
import '../../widgets/custom_drawer.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final List<AppNotification> _notifications = [];
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  bool _hasMore = true;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load({bool refresh = false}) async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    if (refresh) {
      setState(() {
        _page = 1;
        _hasMore = true;
        _notifications.clear();
        _loading = true;
      });
    }

    try {
      final result = await NotificationService.instance.getNotifications(
        userId: authState.user!.id!,
        page: _page,
        size: _pageSize,
      );
      if (mounted) {
        setState(() {
          _notifications.addAll(result.data);
          _hasMore = result.data.length >= _pageSize;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    setState(() {
      _loadingMore = true;
      _page++;
    });

    try {
      final result = await NotificationService.instance.getNotifications(
        userId: authState.user!.id!,
        page: _page,
        size: _pageSize,
      );
      if (mounted) {
        setState(() {
          _notifications.addAll(result.data);
          _hasMore = result.data.length >= _pageSize;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _page--;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;
    try {
      await NotificationService.instance.markAllAsRead(authState.user!.id!);
      setState(() {
        for (int i = 0; i < _notifications.length; i++) {
          _notifications[i] = AppNotification(
            id: _notifications[i].id,
            user: _notifications[i].user,
            message: _notifications[i].message,
            isRead: true,
            booking: _notifications[i].booking,
            createdAt: _notifications[i].createdAt,
          );
        }
      });
    } catch (_) {}
  }

  Future<void> _delete(AppNotification notification) async {
    try {
      await NotificationService.instance
          .deleteNotification(notification.id);
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });
    } catch (_) {}
  }

  Future<void> _onTap(AppNotification notification) async {
    // Mark as read
    if (notification.isRead != true) {
      try {
        await NotificationService.instance.markAsRead(notification.id);
        setState(() {
          final idx = _notifications.indexWhere((n) => n.id == notification.id);
          if (idx >= 0) {
            _notifications[idx] = AppNotification(
              id: notification.id,
              user: notification.user,
              message: notification.message,
              isRead: true,
              booking: notification.booking,
              createdAt: notification.createdAt,
            );
          }
        });
      } catch (_) {}
    }
    // Navigate to booking if exists
    if (notification.booking != null && mounted) {
      context.push('/booking/${notification.booking}');
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            context.go('/sign-in?redirect=/notifications');
          } catch (_) {}
        }
      });
      return Scaffold(
        backgroundColor: AppColors.screenBackground,
        appBar: AppHeader(title: AppStrings.t('NOTIFICATIONS')),
        drawer: const CustomDrawer(currentRoute: '/notifications'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.t('SIGN_IN'),
                style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              BcButton(
                label: AppStrings.t('SIGN_IN'),
                onPress: () {
                  try {
                    context.go('/sign-in?redirect=/notifications');
                  } catch (_) {}
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppHeader(title: AppStrings.t('NOTIFICATIONS')),
      drawer: const CustomDrawer(currentRoute: '/notifications'),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _load(refresh: true),
        child: Column(
          children: [
            // Mark all as read action bar
            Container(
              color: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _markAllAsRead,
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.black, size: 18),
                    label: Text(
                      AppStrings.t('MARK_ALL_READ'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _notifications.isEmpty
                      ? Center(
                          child: Text(
                            AppStrings.t('NO_NOTIFICATIONS'),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount:
                              _notifications.length + (_loadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _notifications.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary),
                                ),
                              );
                            }
                            final notification = _notifications[index];
                            return _NotificationItem(
                              notification: notification,
                              dateLabel: _formatDate(notification.createdAt),
                              onTap: () => _onTap(notification),
                              onDelete: () => _delete(notification),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final String dateLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationItem({
    required this.notification,
    required this.dateLabel,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead == true;
    final bgColor = isRead ? const Color(0xFFF5F5F5) : Colors.white;
    final borderColor = isRead ? Colors.transparent : const Color(0xFF1976D2);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.black, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onDelete,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(color: borderColor, width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Circle indicator
                Container(
                  margin: const EdgeInsets.only(top: 2, right: 12),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRead
                        ? Colors.grey.shade400
                        : const Color(0xFF1976D2),
                  ),
                ),
                // Message & date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.message ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: isRead
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          fontWeight: isRead
                              ? FontWeight.normal
                              : FontWeight.w500,
                        ),
                      ),
                      if (dateLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Delete button
                GestureDetector(
                  onTap: onDelete,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
