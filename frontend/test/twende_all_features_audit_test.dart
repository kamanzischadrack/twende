// test/twende_all_features_audit_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:twende_flutter/features/dashboard/dashboard_screen.dart';
import 'package:twende_flutter/features/fleet/vehicle_list_screen.dart';
import 'package:twende_flutter/features/fleet/vehicle_detail_screen.dart';
import 'package:twende_flutter/features/customers/customer_list_screen.dart';
import 'package:twende_flutter/features/customers/customer_detail_screen.dart';
import 'package:twende_flutter/features/bookings/twende_booking_create_screen.dart';
import 'package:twende_flutter/features/contracts/contract_detail_screen.dart';
import 'package:twende_flutter/features/active_rentals/active_rentals_screen.dart';
import 'package:twende_flutter/features/handover/handover_screen.dart';
import 'package:twende_flutter/features/returns_inspection/return_screen.dart';
import 'package:twende_flutter/features/billing_payments/billing_screen.dart';
import 'package:twende_flutter/features/notifications_approvals/approvals_screen.dart';
import 'package:twende_flutter/features/reports_ai/ask_fleet_screen.dart';
import 'package:twende_flutter/features/reports_ai/reports_screen.dart';
import 'package:twende_flutter/features/maintenance/maintenance_screen.dart';
import 'package:twende_flutter/features/trips/trips_screen.dart';
import 'package:twende_flutter/core/store/json_document_store.dart';
import 'package:twende_flutter/core/store/store_provider.dart';
import 'package:twende_flutter/models/user.dart';
import 'package:twende_flutter/providers/auth_provider.dart';
import 'package:twende_flutter/shared/repositories/store_finance_repositories.dart';
import 'package:twende_flutter/widgets/custom_drawer.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Shared in-memory admin user used to populate the authenticated session
/// in tests that need a logged-in System Administrator (e.g. the drawer test).
const _kAdminUser = User(
  id: 'test-admin',
  fullName: 'Test Admin',
  email: 'admin@test.app',
  role: 'system_administrator',
  accessToken: 'fake-token',
);

/// Returns [ProviderScope] overrides that inject an authenticated
/// System Administrator.  Both [authProvider] and [currentUserProvider] are
/// overridden so the drawer reads an already-logged-in user without touching
/// [UserService] or any real storage.
List<Override> adminAuthOverrides() => [
      authProvider.overrideWith((ref) {
        final notifier = AuthNotifier();
        // updateUser() is synchronous and runs before _init() can clear state.
        notifier.updateUser(_kAdminUser);
        return notifier;
      }),
      currentUserProvider.overrideWith((ref) => _kAdminUser),
    ];

Widget createTestableWidget(Widget child,
    {List<Override> extraOverrides = const []}) {
  return ProviderScope(
    overrides: [
      jsonDocumentStoreProvider
          .overrideWithValue(JsonDocumentStore(useInMemory: true)),
      ...extraOverrides,
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

Future<void> pumpScreen(WidgetTester tester, Widget widget) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(createTestableWidget(widget));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Twende Full Feature Audit — All Screens Render & Display Correctly',
      () {
    testWidgets('1. DashboardScreen renders KPIs, alerts and quick actions',
        (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await pumpScreen(tester, const DashboardScreen());

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('Active Rentals'), findsWidgets);
      expect(find.text('Available Fleet'), findsWidgets);
      expect(find.text('Fleet & Vehicle Catalog'), findsOneWidget);
    });

    testWidgets(
        '2. VehicleListScreen renders search, categories, and vehicle cards',
        (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await pumpScreen(tester, const VehicleListScreen());

      expect(find.byType(VehicleListScreen), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Fleet'), findsWidgets);
    });

    testWidgets(
        '3. VehicleDetailScreen renders vehicle profile, specs, and override action',
        (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await pumpScreen(tester, const VehicleDetailScreen(vehicleId: 'veh_01'));

      expect(find.byType(VehicleDetailScreen), findsOneWidget);
      expect(find.text('Override Status'), findsOneWidget);
      expect(find.text('Toyota Land Cruiser Prado'), findsOneWidget);
    });

    testWidgets(
        '4. CustomerListScreen renders customer directory, search and risk badges',
        (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await pumpScreen(tester, const CustomerListScreen());

      expect(find.byType(CustomerListScreen), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Customers'), findsWidgets);
    });

    testWidgets(
        '5. CustomerDetailScreen renders customer verification and rental history',
        (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await pumpScreen(
          tester, const CustomerDetailScreen(customerId: 'cust_01'));

      expect(find.byType(CustomerDetailScreen), findsOneWidget);
      expect(find.text('Jean-Paul Mugisha'), findsOneWidget);
      expect(find.text('Rental Eligibility Check (BR-04)'), findsOneWidget);
    });

    testWidgets(
        '6. TwendeBookingCreateScreen renders booking form and live quotation',
        (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await pumpScreen(tester, const TwendeBookingCreateScreen());

      expect(find.byType(TwendeBookingCreateScreen), findsOneWidget);
      expect(find.text('New Booking & Live Quote'), findsOneWidget);
      expect(find.text('Quote Breakdown (Live Preview)'), findsOneWidget);
      expect(find.text('Confirm & Create Contract'), findsOneWidget);
    });

    testWidgets(
        '7. ContractDetailScreen renders contract timeline, terms and actions',
        (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await pumpScreen(
          tester, const ContractDetailScreen(contractId: 'cnt_01'));

      expect(find.byType(ContractDetailScreen), findsOneWidget);
      expect(find.text('CNT-2026-0042'), findsOneWidget);
      expect(find.text('Total Value'), findsOneWidget);
    });

    testWidgets(
        '8. ActiveRentalsScreen renders active rentals list and overdue flags',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(ProviderScope(
        overrides: [
          contractRepositoryProvider.overrideWithValue(
            StoreContractRepository(store: JsonDocumentStore(useInMemory: true)),
          ),
        ],
        child: const MaterialApp(home: ActiveRentalsScreen()),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ActiveRentalsScreen), findsOneWidget);
      expect(find.text('Active Rentals'), findsWidgets);
      expect(find.text('Show Overdue Only:'), findsOneWidget);
      expect(find.text('CNT-2026-0042'), findsOneWidget);
      expect(find.text('CNT-2026-0039'), findsOneWidget);
    });

    testWidgets(
        '9. HandoverScreen renders inspection wizard with damage diagram and signature',
        (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await pumpScreen(tester, const HandoverScreen(contractId: 'cnt_01'));

      expect(find.byType(HandoverScreen), findsOneWidget);
      expect(find.text('Pre-checks'), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);
    });

    testWidgets(
        '10. ReturnScreen renders return inspection and automated reconciliation',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(ProviderScope(
        overrides: [
          contractRepositoryProvider.overrideWithValue(
            StoreContractRepository(store: JsonDocumentStore(useInMemory: true)),
          ),
        ],
        child: const MaterialApp(
          home: ReturnScreen(contractId: 'cnt_01'),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ReturnScreen), findsOneWidget);
      expect(find.text('Readings'), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);
    });

    testWidgets(
        '11. BillingScreen renders invoices, receivables aging and payment recording',
        (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await pumpScreen(tester, const BillingScreen());

      expect(find.byType(BillingScreen), findsOneWidget);
      expect(find.text('Invoices'), findsOneWidget);
      expect(find.text('Current (0-30d)'), findsOneWidget);
    });

    testWidgets('12. ApprovalsScreen renders pending approval chains',
        (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await pumpScreen(tester, const ApprovalsScreen());

      expect(find.byType(ApprovalsScreen), findsOneWidget);
      expect(find.text('Approvals'), findsOneWidget);
    });

    testWidgets(
        '13. MaintenanceScreen renders work orders, schedule and history',
        (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await pumpScreen(tester, const MaintenanceScreen());

      expect(find.byType(MaintenanceScreen), findsOneWidget);
      expect(find.text('Maintenance'), findsWidgets);
      expect(find.text('Work Orders'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets(
        '14. TripsScreen renders truck trips, routes, margins and status tabs',
        (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await pumpScreen(tester, const TripsScreen());

      expect(find.byType(TripsScreen), findsOneWidget);
      expect(find.text('Trips & Logistics'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Planned'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets(
        '15. ReportsScreen renders fleet utilization, revenue and customer analytics',
        (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await pumpScreen(tester, const ReportsScreen());

      expect(find.byType(ReportsScreen), findsOneWidget);
      expect(find.text('Reports & Analytics'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Fleet Utilization'), findsWidgets);
      expect(find.text('Revenue'), findsWidgets);
      expect(find.text('Customers'), findsWidgets);
    });

    testWidgets(
        '16. AskFleetScreen renders AI operational assistant and suggested queries',
        (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      await pumpScreen(tester, const AskFleetScreen());

      expect(find.byType(AskFleetScreen), findsOneWidget);
      expect(find.text('Ask Your Fleet'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets(
        '17. CustomDrawer renders all Twende shells (Operate, Manage, Money & Insight)',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Inject a System Administrator so all drawer sections are visible.
      await tester.pumpWidget(createTestableWidget(
        const Scaffold(
          drawer: CustomDrawer(currentRoute: '/dashboard'),
          body: Center(child: Text('Home Content')),
        ),
        extraOverrides: adminAuthOverrides(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Open Drawer
      final ScaffoldState scaffoldState =
          tester.firstState(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CustomDrawer), findsOneWidget);
      expect(find.text('OPERATE'), findsOneWidget);
      expect(find.text('MANAGE'), findsOneWidget);
      expect(find.text('MONEY & INSIGHT'), findsOneWidget);
      expect(find.text('GENERAL'), findsOneWidget);
    });
  });
}
