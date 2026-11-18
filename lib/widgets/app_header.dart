// lib/widgets/app_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/env_config.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/user_service.dart';

class AppHeader extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final String? title;
  final bool hideTitle;

  const AppHeader({
    super.key,
    this.title,
    this.hideTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(52.0);

  @override
  ConsumerState<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends ConsumerState<AppHeader> {
  String _currency = AppConstants.defaultCurrency;

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final cur = await UserService.instance.getCurrency();
    if (mounted) {
      setState(() {
        _currency = cur;
      });
    }
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.supportedCurrencies.map((c) {
            final isSelected = c == _currency;
            return ListTile(
              title: Text(
                c,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : Colors.black87,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.black)
                  : null,
              onTap: () async {
                setState(() {
                  _currency = c;
                });
                await UserService.instance.setCurrency(c);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final loggedIn = authState.isAuthenticated;
    final user = authState.user;
    final notificationCount = ref.watch(notificationCountProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              // 1. Menu hamburger button
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.black, size: 26),
                onPressed: () {
                  Scaffold.maybeOf(context)?.openDrawer();
                },
                tooltip: 'Open Menu',
              ),

              // 2. Title
              if (!widget.hideTitle && widget.title != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title!,
                    style: const TextStyle(
                      color: Color(0xFF121212),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Spacer(),

              // 3. Actions: Currency Menu
              InkWell(
                onTap: _showCurrencyPicker,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currency,
                        style: const TextStyle(
                          color: Color(0xFF121212),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.black,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Logged in actions: Notifications & Avatar
              if (loggedIn) ...[
                // Notifications icon with badge
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.black, size: 24),
                      onPressed: () => context.push('/notifications'),
                    ),
                    if (notificationCount > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$notificationCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Avatar / Profile icon
                InkWell(
                  onTap: () => context.push('/settings'),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: user?.avatar != null && user!.avatar!.isNotEmpty
                        ? CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(
                              user.avatar!.startsWith('http')
                                  ? user.avatar!
                                  : '${EnvConfig.cdnUsers}/${user.avatar}',
                            ),
                            backgroundColor: Colors.grey.shade200,
                          )
                        : CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              user?.fullName?.isNotEmpty == true
                                  ? user!.fullName!.substring(0, 1).toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),
              ] else ...[
                TextButton.icon(
                  onPressed: () => context.push('/sign-in'),
                  icon: const Icon(Icons.login, size: 20, color: Colors.black),
                  label: const Text(
                    'Sign in',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
