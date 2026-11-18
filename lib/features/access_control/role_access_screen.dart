import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/permissions.dart';
import '../../core/routing/twende_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/custom_drawer.dart';

const _roleModules = <(AppModule, String)>[
  (AppModule.fleet, 'Fleet and documents'),
  (AppModule.availability, 'Availability board'),
  (AppModule.customers, 'Customers'),
  (AppModule.bookings, 'Bookings'),
  (AppModule.contracts, 'Contracts'),
  (AppModule.handover, 'Handover and return'),
  (AppModule.billing, 'Billing and payments'),
  (AppModule.refunds, 'Refunds and discounts'),
  (AppModule.maintenance, 'Maintenance'),
  (AppModule.driversTrips, 'Drivers and trips'),
  (AppModule.damageIncidents, 'Damage and incidents'),
  (AppModule.reports, 'Reports and dashboard'),
  (AppModule.settings, 'Settings and users'),
];

class RoleAccessScreen extends ConsumerWidget {
  const RoleAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final assignedRoles = user?.roles.isNotEmpty == true
        ? user!.roles
        : [if (user?.role != null) user!.role!];
    final activeRoles =
        assignedRoles.map(appRoleFromName).whereType<AppRole>().toSet();

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: const AppHeader(title: 'Role Access'),
      drawer: const CustomDrawer(currentRoute: TwendeRoutes.roleAccess),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeRoles.isEmpty
                      ? 'Compare the SRS demo roles'
                      : 'Your role${activeRoles.length == 1 ? '' : 's'}: '
                          '${activeRoles.map(appRoleLabel).join(', ')}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'These are the default permissions from the SRS. '
                  'They describe screen access; branch and assigned-job data '
                  'restrictions still require backend enforcement.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final role in srsAppRoles)
                  Card(
                    color: activeRoles.contains(role)
                        ? const Color(0xFFFFF8F3)
                        : Colors.white,
                    child: ExpansionTile(
                      initiallyExpanded: activeRoles.contains(role),
                      leading: Icon(
                        activeRoles.contains(role)
                            ? Icons.verified_user
                            : Icons.person_outline,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        appRoleLabel(role),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(appRoleDescription(role)),
                      children: [
                        for (final (module, label) in _roleModules)
                          _buildPermissionRow(role, module, label),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(AppRole role, AppModule module, String label) {
    final actions = permissionsForRole(role, module);
    if (actions.isEmpty) return const SizedBox.shrink();

    return ListTile(
      dense: true,
      title: Text(label),
      subtitle: Text(actions.map(_actionLabel).join(' · ')),
    );
  }

  String _actionLabel(AppAction action) => switch (action) {
        AppAction.view => 'View',
        AppAction.create => 'Create',
        AppAction.edit => 'Edit',
        AppAction.approve => 'Approve',
        AppAction.archive => 'Delete / archive',
        AppAction.export => 'Export',
        _ => '',
      };
}
