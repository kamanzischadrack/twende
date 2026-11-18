// lib/widgets/custom_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/auth/permissions.dart';
import '../core/auth/route_guard.dart';
import '../core/constants/app_strings.dart';
import '../core/routing/twende_routes.dart';
import '../core/theme/app_colors.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';

// ---------------------------------------------------------------------------
// Private data class — represents a single nav item candidate.
// ---------------------------------------------------------------------------
class _NavItem {
  final IconData icon;
  final String label;
  final String route;

  const _NavItem(this.icon, this.label, this.route);
}

class CustomDrawer extends ConsumerStatefulWidget {
  final String currentRoute;

  const CustomDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  ConsumerState<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends ConsumerState<CustomDrawer> {
  bool _openLanguageMenu = false;
  String _currentLanguage = AppStrings.currentLanguage;

  final List<Map<String, String>> _languages = const [
    {'code': 'en', 'label': 'English'},
    {'code': 'rw', 'label': 'Kinyarwanda'},
    {'code': 'fr', 'label': 'Français'},
  ];

  // ---------------------------------------------------------------------------
  // Nav-item catalogs per section — Strictly per Twende SRS §13.1
  // ---------------------------------------------------------------------------

  List<_NavItem> _operateCandidates() => [
        _NavItem(Icons.dashboard, AppStrings.t('DASHBOARD'), '/dashboard'),
        _NavItem(Icons.event_available, AppStrings.t('AVAILABILITY'), '/availability'),
        _NavItem(Icons.event_seat, AppStrings.t('BOOKINGS'), '/bookings'),
        _NavItem(Icons.car_rental, AppStrings.t('ACTIVE_RENTALS'), '/active-rentals'),
        const _NavItem(Icons.assignment_return, 'Returns Due', '/returns-due'),
        _NavItem(Icons.local_shipping, AppStrings.t('TRIPS'), '/trips'),
      ];

  List<_NavItem> _manageCandidates() => [
        _NavItem(Icons.directions_car, AppStrings.t('FLEET'), '/fleet'),
        _NavItem(Icons.people, AppStrings.t('CUSTOMERS'), '/customers'),
        _NavItem(Icons.badge, AppStrings.t('DRIVERS'), '/trips'),
        _NavItem(Icons.build, AppStrings.t('MAINTENANCE'), '/maintenance'),
        const _NavItem(Icons.car_crash, 'Damage & Incidents', '/damage'),
        const _NavItem(Icons.price_change, 'Rates & Tariffs', '/rates'),
      ];

  List<_NavItem> _moneyCandidates() => [
        _NavItem(Icons.receipt_long, AppStrings.t('INVOICES'), '/billing'),
        _NavItem(Icons.payments, AppStrings.t('PAYMENTS'), '/billing'),
        _NavItem(Icons.account_balance_wallet, AppStrings.t('DEPOSITS'), '/billing'),
        _NavItem(Icons.verified_user, AppStrings.t('APPROVALS'), '/approvals'),
        _NavItem(Icons.bar_chart, AppStrings.t('REPORTS'), '/reports'),
        _NavItem(Icons.smart_toy, AppStrings.t('ASK_FLEET'), '/ask-fleet'),
        const _NavItem(Icons.policy, 'Policies & Rules', '/settings/policies'),
      ];

  List<_NavItem> _generalCandidates(bool loggedIn) => [
        if (loggedIn)
          const _NavItem(Icons.admin_panel_settings_outlined, 'Role Access', TwendeRoutes.roleAccess),
        if (!loggedIn) _NavItem(Icons.login, AppStrings.t('SIGN_IN_TITLE'), '/sign-in'),
      ];

  // ---------------------------------------------------------------------------
  // Filtering
  // ---------------------------------------------------------------------------

  /// Returns only the items [user] is allowed to access.
  List<_NavItem> _sectionItems(User? user, List<_NavItem> candidates) =>
      candidates.where((item) => AppRouteGuard.canAccess(user, item.route)).toList();

  // ---------------------------------------------------------------------------
  // Widget builders
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6, left: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: Color.fromRGBO(0, 0, 0, 0.4),
        ),
      ),
    );
  }

  /// Renders [item] as a tappable menu row. The caller already knows access is
  /// granted, so no guard check is needed here.
  Widget _buildNavItem(_NavItem item) {
    final isActive = widget.currentRoute == item.route;
    final color = isActive ? AppColors.primary : const Color.fromRGBO(0, 0, 0, 0.54);

    return InkWell(
      onTap: () => _navigateTo(item.route),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        margin: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFEEEE4) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(item.icon, size: 24, color: color),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders a section header + its items, or nothing if [items] is empty.
  Widget _buildSection(String title, List<_NavItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title),
        ...items.map(_buildNavItem),
      ],
    );
  }

  /// Role badge colour for the profile header.
  Color _roleColor(AppRole? role) => switch (role) {
        AppRole.systemAdministrator => const Color(0xFF6B21A8),
        AppRole.ownerManagement => const Color(0xFF1D4ED8),
        AppRole.rentalManager => const Color(0xFF0F766E),
        AppRole.rentalOfficer => const Color(0xFF0369A1),
        AppRole.fleetManager => const Color(0xFF15803D),
        AppRole.financeOfficer => const Color(0xFFB45309),
        AppRole.driverChauffeur => const Color(0xFF7C3AED),
        AppRole.customer => AppColors.primary,
        _ => const Color.fromRGBO(0, 0, 0, 0.4),
      };

  /// Profile card at the top of the drawer.
  Widget _buildUserProfile(User user, AppRole? role) {
    final roleLabel = role != null ? appRoleLabel(role) : 'User';
    final badgeColor = _roleColor(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: badgeColor.withValues(alpha: 0.15),
            child: Text(
              (user.fullName?.isNotEmpty == true
                      ? user.fullName![0]
                      : user.email?.isNotEmpty == true
                          ? user.email![0]
                          : '?')
                  .toUpperCase(),
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.fullName?.isNotEmpty == true)
                  Text(
                    user.fullName!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color.fromRGBO(0, 0, 0, 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (user.email?.isNotEmpty == true)
                  Text(
                    user.email!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color.fromRGBO(0, 0, 0, 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation & auth helpers
  // ---------------------------------------------------------------------------

  Future<void> _updateLanguage(String code) async {
    setState(() {
      _currentLanguage = code;
      AppStrings.setLocale(code);
      _openLanguageMenu = false;
    });

    final user = ref.read(currentUserProvider);
    if (user != null && user.id != null) {
      await UserService.instance.updateLanguage(user.id!, code);
    } else {
      await UserService.instance.setLanguage(code);
    }

    if (mounted) {
      Navigator.of(context).pop(); // Close drawer
      // Trigger refresh
      context.go(widget.currentRoute);
    }
  }

  void _navigateTo(String route) {
    Navigator.of(context).pop(); // Close drawer
    if (widget.currentRoute != route) {
      context.go(route);
    }
  }

  Future<void> _handleSignOut() async {
    Navigator.of(context).pop();
    await ref.read(authProvider.notifier).signOut();
    if (mounted) {
      context.go('/sign-in');
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = ref.watch(currentUserProvider);
    final loggedIn = authState.isAuthenticated;
    final insets = MediaQuery.of(context).padding;

    // Resolve the current user's role (uses the primary `role` field).
    final role = appRoleFromName(user?.role);

    // Driver and Customer roles use their own navigation shells — the drawer
    // only shows the account profile + language switcher + sign-out.
    final isMinimalRole =
        role == AppRole.driverChauffeur || role == AppRole.customer;

    return Drawer(
      width: 280,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(top: insets.top, bottom: insets.bottom),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                    top: 40, left: 15, right: 15, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── User profile header (shown when logged in) ──────────
                    if (loggedIn && user != null) _buildUserProfile(user, role),
                    if (loggedIn && user != null) const Divider(height: 1),
                    if (loggedIn && user != null) const SizedBox(height: 8),

                    // ── Navigation items (staff only) ───────────────────────
                    if (!isMinimalRole) ...[
                      // Home — visible for visitors only
                      if (!loggedIn && AppRouteGuard.canAccess(user, '/'))
                        _buildNavItem(_NavItem(
                          Icons.home,
                          AppStrings.t('HOME'),
                          '/',
                        )),

                      _buildSection(
                          'Operate', _sectionItems(user, _operateCandidates())),
                      _buildSection(
                          'Manage', _sectionItems(user, _manageCandidates())),
                      _buildSection(
                          'Money & Insight',
                          _sectionItems(user, _moneyCandidates())),
                      _buildSection(
                          'General',
                          _sectionItems(user, _generalCandidates(loggedIn))),
                    ],

                    // ── Minimal role: sign-in/sign-out only ─────────────────
                    if (isMinimalRole) ...[
                      if (!loggedIn)
                        _buildNavItem(_NavItem(
                          Icons.login,
                          AppStrings.t('SIGN_IN_TITLE'),
                          '/sign-in',
                        )),
                    ],

                    // ── Sign-out (all logged-in users) ──────────────────────
                    if (loggedIn)
                      InkWell(
                        onTap: _handleSignOut,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 10),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.logout,
                                size: 24,
                                color: Color.fromRGBO(0, 0, 0, 0.54),
                              ),
                              const SizedBox(width: 20),
                              Text(
                                AppStrings.t('SIGN_OUT'),
                                style: const TextStyle(
                                  color: Color.fromRGBO(0, 0, 0, 0.54),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Language section at bottom ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Column(
                children: [
                  if (_openLanguageMenu)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        children: _languages.map((lang) {
                          final isSelected = lang['code'] == _currentLanguage;
                          return InkWell(
                            onTap: () => _updateLanguage(lang['code']!),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 20),
                              color: isSelected
                                  ? const Color(0xFFFEEEE4)
                                  : Colors.transparent,
                              child: Text(
                                lang['label']!,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color.fromRGBO(0, 0, 0, 0.54),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _openLanguageMenu = !_openLanguageMenu;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.language,
                            size: 24,
                            color: Color.fromRGBO(0, 0, 0, 0.54),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            AppStrings.t('LANGUAGE'),
                            style: const TextStyle(
                              color: Color.fromRGBO(0, 0, 0, 0.54),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
