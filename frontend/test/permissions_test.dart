import 'package:flutter_test/flutter_test.dart';
import 'package:twende_flutter/core/auth/permissions.dart';
import 'package:twende_flutter/core/auth/route_guard.dart';
import 'package:twende_flutter/core/mock/mock_data.dart';
import 'package:twende_flutter/models/user.dart';

void main() {
  group('Twende RBAC', () {
    test('recognizes all SRS roles and legacy server role names', () {
      expect(
          appRoleFromName('System Administrator'), AppRole.systemAdministrator);
      expect(appRoleFromName('Owner / Management'), AppRole.ownerManagement);
      expect(appRoleFromName('rental_manager'), AppRole.rentalManager);
      expect(appRoleFromName('staff'), AppRole.rentalOfficer);
      expect(appRoleFromName('Fleet Manager'), AppRole.fleetManager);
      expect(appRoleFromName('Finance Officer / Accountant'),
          AppRole.financeOfficer);
      expect(appRoleFromName('Driver / Chauffeur'), AppRole.driverChauffeur);
      expect(appRoleFromName('customer'), AppRole.customer);
      expect(appRoleFromName('unrecognized-role'), isNull);
    });

    test('demo accounts give every SRS role a distinct identity and policy',
        () {
      const accounts = MockData.demoAccounts;
      final accountRoles =
          accounts.map((account) => appRoleFromName(account.user.role)).toSet();

      expect(accounts, hasLength(srsAppRoles.length));
      expect(accountRoles, containsAll(srsAppRoles));
      expect(accounts.map((account) => account.email).toSet(),
          hasLength(srsAppRoles.length));
      expect(accounts.map((account) => account.password).toSet(),
          hasLength(srsAppRoles.length));
      for (final account in accounts) {
        expect(
          MockData.demoAccountForCredentials(
            account.email.toUpperCase(),
            account.password,
          ),
          same(account),
        );
        expect(
          MockData.demoAccountForCredentials(account.email, 'wrong-password'),
          isNull,
        );
      }
      expect(
        can(accounts[3].user, AppModule.bookings, AppAction.create),
        isTrue,
      );
      expect(
        can(accounts[6].user, AppModule.bookings, AppAction.create),
        isFalse,
      );
    });

    test('system administrator receives the configurable default permissions',
        () {
      const user = User(id: 'u1', role: 'system_administrator');

      expect(can(user, AppModule.fleet, AppAction.archive), isTrue);
      expect(can(user, AppModule.settings, AppAction.manageTenant), isTrue);
      expect(can(user, AppModule.refunds, AppAction.approve), isTrue);
    });

    test('management has dashboard export and settings view but not edit', () {
      const user = User(id: 'u2', role: 'owner_management');

      expect(can(user, AppModule.dashboard, AppAction.export), isTrue);
      expect(can(user, AppModule.settings, AppAction.view), isTrue);
      expect(can(user, AppModule.settings, AppAction.edit), isFalse);
    });

    test('rental manager and officer have distinct booking permissions', () {
      const manager = User(id: 'u3', role: 'rental_manager');
      const officer = User(id: 'u4', role: 'rental_officer');

      expect(can(manager, AppModule.bookings, AppAction.archive), isTrue);
      expect(can(manager, AppModule.approvals, AppAction.view), isTrue);
      expect(can(officer, AppModule.bookings, AppAction.create), isTrue);
      expect(can(officer, AppModule.bookings, AppAction.approve), isFalse);
      expect(can(officer, AppModule.bookings, AppAction.archive), isFalse);
    });

    test('fleet, finance, and driver roles follow their SRS module grants', () {
      const fleetManager = User(id: 'u5', role: 'fleet_manager');
      const financeOfficer = User(id: 'u6', role: 'finance_officer');
      const driver = User(id: 'u7', role: 'driver_chauffeur');

      expect(can(fleetManager, AppModule.fleet, AppAction.archive), isTrue);
      expect(can(fleetManager, AppModule.billing, AppAction.view), isFalse);
      expect(can(financeOfficer, AppModule.billing, AppAction.approve), isTrue);
      expect(can(financeOfficer, AppModule.fleet, AppAction.edit), isFalse);
      expect(can(driver, AppModule.driversTrips, AppAction.edit), isTrue);
      expect(can(driver, AppModule.bookings, AppAction.view), isFalse);
      expect(can(driver, AppModule.settings, AppAction.view), isFalse);
    });

    test('customers can create and view bookings but not access fleet tools',
        () {
      const customer = User(id: 'u8', role: 'customer');

      expect(can(customer, AppModule.bookings, AppAction.view), isTrue);
      expect(can(customer, AppModule.bookings, AppAction.create), isTrue);
      expect(can(customer, AppModule.fleet, AppAction.view), isFalse);
      expect(AppRouteGuard.canAccess(customer, '/checkout'), isTrue);
    });

    test('multiple assigned roles combine permissions', () {
      const user = User(
        id: 'u9',
        role: 'customer',
        roles: ['rental_officer', 'finance_officer'],
      );

      expect(can(user, AppModule.bookings, AppAction.create), isTrue);
      expect(can(user, AppModule.billing, AppAction.approve), isTrue);
      expect(can(user, AppModule.settings, AppAction.edit), isFalse);
    });

    test('user role and branch assignments survive JSON serialization', () {
      final user = User.fromJson({
        '_id': 'u19',
        'role': 'rental_officer',
        'roles': ['rental_officer', 'finance_officer'],
        'branchIds': ['branch-1', 'branch-2'],
      });

      expect(user.roles, ['rental_officer', 'finance_officer']);
      expect(user.branchIds, ['branch-1', 'branch-2']);
      expect(User.fromJson(user.toJson()).roles, user.roles);
      expect(User.fromJson(user.toJson()).branchIds, user.branchIds);
    });

    test('branch-scoped records require an assigned branch', () {
      const user = User(
        id: 'u10',
        role: 'rental_manager',
        branchIds: ['branch-1', 'branch-2'],
      );

      expect(
        can(
          user,
          AppModule.bookings,
          AppAction.view,
          targetBranchId: 'branch-2',
        ),
        isTrue,
      );
      expect(
        can(
          user,
          AppModule.bookings,
          AppAction.view,
          targetBranchId: 'branch-3',
        ),
        isFalse,
      );
      expect(
        can(
          const User(id: 'u11', role: 'system_administrator'),
          AppModule.bookings,
          AppAction.view,
          targetBranchId: 'branch-1',
        ),
        isFalse,
      );
    });

    test('route guard covers protected operational routes and their actions',
        () {
      expect(
        AppRouteGuard.canAccess(MockData.demoUser, '/active-rentals'),
        isTrue,
      );
      expect(
        AppRouteGuard.canAccess(MockData.demoUser, '/returns-due'),
        isTrue,
      );
      expect(
        AppRouteGuard.canAccess(
          const User(id: 'u22', role: 'customer'),
          '/returns-due',
        ),
        isFalse,
      );
      expect(
        AppRouteGuard.canAccess(
          const User(id: 'u12', role: 'rental_officer'),
          '/booking-new',
        ),
        isTrue,
      );
      expect(
        AppRouteGuard.canAccess(
          const User(id: 'u13', role: 'fleet_manager'),
          '/booking-new',
        ),
        isFalse,
      );
      expect(
        AppRouteGuard.canAccess(
          const User(id: 'u14', role: 'driver'),
          '/trips',
        ),
        isTrue,
      );
      expect(
        AppRouteGuard.canAccess(
          const User(id: 'u15', role: 'rental_officer'),
          '/availability',
        ),
        isTrue,
      );
      expect(
        AppRouteGuard.canAccess(
          const User(id: 'u20', role: 'rental_officer'),
          '/settings',
        ),
        isTrue,
      );
      expect(
        can(
          const User(id: 'u21', role: 'rental_officer'),
          AppModule.settings,
          AppAction.view,
        ),
        isFalse,
      );
    });

    test('unknown and guest roles are denied', () {
      const guest = User(id: 'u16', role: 'guest');
      const unknown = User(id: 'u17', role: 'some_new_role');

      expect(can(guest, AppModule.fleet, AppAction.view), isFalse);
      expect(can(unknown, AppModule.dashboard, AppAction.view), isFalse);
    });

    test('legacy viewer remains read-only and demo uses rental manager', () {
      const viewer = User(id: 'u18', role: 'viewer');

      expect(can(viewer, AppModule.dashboard, AppAction.view), isTrue);
      expect(can(viewer, AppModule.dashboard, AppAction.edit), isFalse);
      expect(MockData.demoUser.role, 'rental_manager');
      expect(AppRouteGuard.canAccess(MockData.demoUser, '/fleet'), isTrue);
      expect(AppRouteGuard.canAccess(MockData.demoUser, '/bookings'), isTrue);
    });
  });
}
