import '../../models/user.dart';
import 'permissions.dart';

class RouteAccess {
  final AppModule module;
  final AppAction action;

  const RouteAccess({
    required this.module,
    required this.action,
  });
}

class AppRouteGuard {
  const AppRouteGuard._();

  /// Routes where module-level access alone is insufficient.
  /// Only the listed roles may visit these paths (after the module check passes).
  static const _explicitRoleRoutes = <String, Set<AppRole>>{
    '/rates': {
      AppRole.systemAdministrator,
      AppRole.ownerManagement,
      AppRole.rentalManager,
      AppRole.fleetManager,
      AppRole.financeOfficer,
    },
    '/settings/policies': {
      AppRole.systemAdministrator,
    },
    '/damage': {
      AppRole.systemAdministrator,
      AppRole.ownerManagement,
      AppRole.rentalManager,
      AppRole.rentalOfficer,
      AppRole.fleetManager,
      AppRole.financeOfficer,
    },
    '/portal': {
      AppRole.customer,
    },
    '/driver': {
      AppRole.driverChauffeur,
    },
    '/role-access': {
      AppRole.systemAdministrator,
    },
  };

  static RouteAccess? resolveRoute(String location) {
    final path = location.split('?').first;
    if (path == '/' || path.isEmpty) return null;

    if (_matches(path, '/dashboard')) {
      return const RouteAccess(
          module: AppModule.dashboard, action: AppAction.view);
    }
    if (_matches(path, '/fleet')) {
      return const RouteAccess(module: AppModule.fleet, action: AppAction.view);
    }
    if (_matches(path, '/availability')) {
      return const RouteAccess(
          module: AppModule.availability, action: AppAction.view);
    }
    if (_matches(path, '/customers')) {
      return const RouteAccess(
          module: AppModule.customers, action: AppAction.view);
    }
    if (_matches(path, '/booking-new') || _matches(path, '/checkout')) {
      return const RouteAccess(
          module: AppModule.bookings, action: AppAction.create);
    }
    if (_matches(path, '/bookings') || _matches(path, '/booking')) {
      return const RouteAccess(
          module: AppModule.bookings, action: AppAction.view);
    }
    if (_matches(path, '/contract') ||
        _matches(path, '/active-rentals') ||
        _matches(path, '/returns-due')) {
      return const RouteAccess(
          module: AppModule.contracts, action: AppAction.view);
    }
    if (_matches(path, '/handover')) {
      return const RouteAccess(
          module: AppModule.handover, action: AppAction.create);
    }
    if (_matches(path, '/return')) {
      return const RouteAccess(
          module: AppModule.returns, action: AppAction.create);
    }
    if (_matches(path, '/maintenance')) {
      return const RouteAccess(
          module: AppModule.maintenance, action: AppAction.view);
    }
    if (_matches(path, '/billing')) {
      return const RouteAccess(
          module: AppModule.billing, action: AppAction.view);
    }
    if (_matches(path, '/approvals')) {
      return const RouteAccess(
          module: AppModule.approvals, action: AppAction.view);
    }
    if (_matches(path, '/reports') || _matches(path, '/ask-fleet')) {
      return const RouteAccess(
          module: AppModule.reports, action: AppAction.view);
    }
    if (_matches(path, '/trips') || _matches(path, '/driver')) {
      return const RouteAccess(
          module: AppModule.driversTrips, action: AppAction.view);
    }
    if (_matches(path, '/damage')) {
      return const RouteAccess(
          module: AppModule.damageIncidents, action: AppAction.view);
    }
    if (_matches(path, '/rates')) {
      return const RouteAccess(
          module: AppModule.billing, action: AppAction.view);
    }
    // /settings/policies must be checked before /settings
    if (_matches(path, '/settings/policies')) {
      return const RouteAccess(
          module: AppModule.settings, action: AppAction.view);
    }
    if (_matches(path, '/settings')) {
      return const RouteAccess(
          module: AppModule.profile, action: AppAction.view);
    }
    if (_matches(path, '/role-access')) {
      return const RouteAccess(
          module: AppModule.admin, action: AppAction.view);
    }
    // Customer portal — customers have bookings.view permission.
    if (_matches(path, '/portal')) {
      return const RouteAccess(
          module: AppModule.bookings, action: AppAction.view);
    }

    return null;
  }

  static bool canAccess(
    User? user,
    String location, {
    String? branchId,
    String? targetBranchId,
  }) {
    final path = location.split('?').first;

    // Module-level check.
    final access = resolveRoute(location);
    if (access == null) return true;
    final moduleOk = can(
      user,
      access.module,
      access.action,
      branchId: branchId,
      targetBranchId: targetBranchId,
    );
    if (!moduleOk) return false;

    // Fine-grained role check for routes in _explicitRoleRoutes.
    for (final entry in _explicitRoleRoutes.entries) {
      if (_matches(path, entry.key)) {
        if (user == null) return false;
        final role = appRoleFromName(user.role);
        return role != null && entry.value.contains(role);
      }
    }

    return true;
  }

  static bool _matches(String path, String route) =>
      path == route || path.startsWith('$route/');
}
