import '../../models/user.dart';

enum AppRole {
  systemAdministrator,
  ownerManagement,
  rentalManager,
  rentalOfficer,
  fleetManager,
  financeOfficer,
  driverChauffeur,
  customer,
  legacyViewer,
}

enum AppModule {
  dashboard,
  fleet,
  availability,
  customers,
  bookings,
  contracts,
  handover,
  returns,
  maintenance,
  billing,
  refunds,
  driversTrips,
  damageIncidents,
  reports,
  settings,
  admin,
  approvals,
  profile,
}

enum AppAction {
  view,
  create,
  edit,
  approve,
  archive,
  export,
  read,
  write,
  manageUsers,
  manageTenant,
}

const srsAppRoles = [
  AppRole.systemAdministrator,
  AppRole.ownerManagement,
  AppRole.rentalManager,
  AppRole.rentalOfficer,
  AppRole.fleetManager,
  AppRole.financeOfficer,
  AppRole.driverChauffeur,
  AppRole.customer,
];

String appRoleKey(AppRole role) => switch (role) {
      AppRole.systemAdministrator => 'system_administrator',
      AppRole.ownerManagement => 'owner_management',
      AppRole.rentalManager => 'rental_manager',
      AppRole.rentalOfficer => 'rental_officer',
      AppRole.fleetManager => 'fleet_manager',
      AppRole.financeOfficer => 'finance_officer',
      AppRole.driverChauffeur => 'driver_chauffeur',
      AppRole.customer => 'customer',
      AppRole.legacyViewer => 'viewer',
    };

String appRoleLabel(AppRole role) => switch (role) {
      AppRole.systemAdministrator => 'System Administrator',
      AppRole.ownerManagement => 'Owner / Management',
      AppRole.rentalManager => 'Rental Manager',
      AppRole.rentalOfficer => 'Rental Officer',
      AppRole.fleetManager => 'Fleet Manager',
      AppRole.financeOfficer => 'Finance Officer / Accountant',
      AppRole.driverChauffeur => 'Driver / Chauffeur',
      AppRole.customer => 'Customer',
      AppRole.legacyViewer => 'Legacy Viewer',
    };

String appRoleDescription(AppRole role) => switch (role) {
      AppRole.systemAdministrator =>
        'Configure the company, branches, users, roles, rates, taxes, and policies.',
      AppRole.ownerManagement =>
        'Review revenue, profit, utilization, debts, and business risks.',
      AppRole.rentalManager =>
        'Run bookings, contracts, approvals, and branch operations.',
      AppRole.rentalOfficer =>
        'Register customers, make bookings, and hand over or receive vehicles.',
      AppRole.fleetManager =>
        'Keep vehicles available, compliant, maintained, and productive.',
      AppRole.financeOfficer =>
        'Manage invoices, payments, deposits, refunds, reconciliation, and exports.',
      AppRole.driverChauffeur =>
        'View assigned rentals and trips, complete checklists, and report incidents.',
      AppRole.customer =>
        'Book, sign, pay, and receive rental documents through the customer portal.',
      AppRole.legacyViewer => 'Read-only compatibility role.',
    };

const _roleOrder = [
  AppRole.systemAdministrator,
  AppRole.ownerManagement,
  AppRole.rentalManager,
  AppRole.rentalOfficer,
  AppRole.fleetManager,
  AppRole.financeOfficer,
  AppRole.driverChauffeur,
];

const _dashboardPermissions = ['VX', 'VX', 'VX', 'V', 'VX', 'VX', ''];

// SRS section 10.1 defaults, in role-column order.
const _permissionMatrix = <AppModule, List<String>>{
  AppModule.fleet: ['VCEADX', 'VX', 'V', 'V', 'VCEDX', 'V', 'V'],
  AppModule.availability: ['VCEADX', 'V', 'VCE', 'VC', 'VCE', 'V', ''],
  AppModule.customers: ['VCEADX', 'VX', 'VCEAX', 'VCE', '', 'VX', ''],
  AppModule.bookings: ['VCEADX', 'VX', 'VCEADX', 'VCE', 'V', 'V', ''],
  AppModule.contracts: ['VCEADX', 'VX', 'VCEAX', 'VC', 'V', 'VX', ''],
  AppModule.handover: ['VCEADX', 'V', 'VCEA', 'VCE', 'V', 'V', 'VC'],
  AppModule.returns: ['VCEADX', 'V', 'VCEA', 'VCE', 'V', 'V', 'VC'],
  AppModule.billing: ['VCEADX', 'VX', 'VC', 'VC', '', 'VCEAX', ''],
  AppModule.refunds: ['VCEADX', 'VA', 'VCA', 'C', '', 'VCA', ''],
  AppModule.maintenance: ['VCEADX', 'VX', 'V', 'V', 'VCEAX', 'V', 'C'],
  AppModule.driversTrips: ['VCEADX', 'VX', 'VCE', 'V', 'VCEA', 'V', 'VE'],
  AppModule.damageIncidents: ['VCEADX', 'VX', 'VCEA', 'VC', 'VCEA', 'VCA', 'C'],
  AppModule.dashboard: _dashboardPermissions,
  AppModule.reports: _dashboardPermissions,
  AppModule.settings: ['VCEADX', 'V', '', '', '', '', ''],
  AppModule.admin: ['VCEADX', 'V', '', '', '', '', ''],
};

AppRole? appRoleFromName(String? value) {
  final normalized =
      (value ?? '').trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  switch (normalized) {
    case 'admin':
    case 'administrator':
    case 'system_admin':
    case 'system_administrator':
      return AppRole.systemAdministrator;
    case 'owner':
    case 'management':
    case 'owner_management':
      return AppRole.ownerManagement;
    case 'manager':
    case 'rental_manager':
      return AppRole.rentalManager;
    case 'staff':
    case 'rental_officer':
      return AppRole.rentalOfficer;
    case 'fleet_manager':
      return AppRole.fleetManager;
    case 'finance':
    case 'accountant':
    case 'finance_officer':
    case 'finance_officer_accountant':
      return AppRole.financeOfficer;
    case 'driver':
    case 'chauffeur':
    case 'driver_chauffeur':
      return AppRole.driverChauffeur;
    case 'customer':
    case 'client':
    case 'user':
      return AppRole.customer;
    case 'viewer':
      return AppRole.legacyViewer;
    default:
      return null;
  }
}

Set<AppRole> _rolesFor(User user) {
  final names = user.roles.isNotEmpty ? user.roles : [user.role ?? ''];
  return names.map(appRoleFromName).whereType<AppRole>().toSet();
}

bool can(
  User? user,
  AppModule module,
  AppAction action, {
  String? branchId,
  String? targetBranchId,
  bool allowGlobalOverride = false,
}) {
  if (user == null) return false;

  if (branchId != null &&
      targetBranchId != null &&
      branchId != targetBranchId) {
    return false;
  }

  if (targetBranchId != null) {
    final assignedBranches = user.branchIds.isNotEmpty
        ? user.branchIds
        : [user.branchId].whereType<String>();
    if (!assignedBranches.contains(targetBranchId)) {
      return false;
    }
  }

  final roles = _rolesFor(user);
  if (roles.isEmpty) return false;
  if (allowGlobalOverride && roles.contains(AppRole.systemAdministrator)) {
    return true;
  }

  return roles.any((role) => _roleCan(role, module, action));
}

Set<AppAction> permissionsForRole(AppRole role, AppModule module) {
  const actions = [
    AppAction.view,
    AppAction.create,
    AppAction.edit,
    AppAction.approve,
    AppAction.archive,
    AppAction.export,
  ];
  return actions.where((action) => _roleCan(role, module, action)).toSet();
}

bool _roleCan(AppRole role, AppModule module, AppAction action) {
  if (module == AppModule.profile) {
    return action == AppAction.view ||
        action == AppAction.edit ||
        action == AppAction.read ||
        action == AppAction.write;
  }

  if (role == AppRole.customer) {
    return module == AppModule.bookings &&
        (action == AppAction.view ||
            action == AppAction.create ||
            action == AppAction.read ||
            action == AppAction.write);
  }

  if (role == AppRole.legacyViewer) {
    return action == AppAction.view || action == AppAction.read
        ? module == AppModule.dashboard ||
            module == AppModule.fleet ||
            module == AppModule.customers ||
            module == AppModule.bookings ||
            module == AppModule.reports
        : false;
  }

  if (module == AppModule.approvals) {
    final canApprove = [
      AppModule.customers,
      AppModule.bookings,
      AppModule.contracts,
      AppModule.handover,
      AppModule.maintenance,
      AppModule.billing,
      AppModule.refunds,
      AppModule.driversTrips,
      AppModule.damageIncidents,
    ].any((approvalModule) =>
        _permissionCodes(module: approvalModule, role: role).contains('A'));
    return canApprove &&
        (action == AppAction.view ||
            action == AppAction.read ||
            action == AppAction.approve);
  }

  final codes = _permissionCodes(module: module, role: role);
  return switch (action) {
    AppAction.view || AppAction.read => codes.contains('V'),
    AppAction.create => codes.contains('C'),
    AppAction.edit => codes.contains('E'),
    AppAction.approve => codes.contains('A'),
    AppAction.archive => codes.contains('D'),
    AppAction.export => codes.contains('X'),
    AppAction.write => codes.contains('C') || codes.contains('E'),
    AppAction.manageUsers || AppAction.manageTenant => codes.contains('E'),
  };
}

String _permissionCodes({required AppModule module, required AppRole role}) {
  final policyModule = switch (module) {
    AppModule.admin => AppModule.settings,
    _ => module,
  };
  final roleIndex = _roleOrder.indexOf(role);
  if (roleIndex < 0) return '';
  final codes = _permissionMatrix[policyModule];
  if (codes == null) return '';
  if (role == AppRole.legacyViewer) {
    return '';
  }
  return codes[roleIndex];
}
