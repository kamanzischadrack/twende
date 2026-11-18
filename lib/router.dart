// lib/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/permissions.dart';
import 'core/auth/route_guard.dart';
import 'providers/auth_provider.dart';

// Customer Facing Screens
import 'screens/home/home_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/change_password_screen.dart';
import 'screens/cars/cars_screen.dart';
import 'screens/booking/booking_screen.dart';
import 'screens/bookings/bookings_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/about/about_screen.dart';
import 'screens/contact/contact_screen.dart';
import 'screens/tos/tos_screen.dart';

// Twende Fleet Management Screens
import 'features/dashboard/dashboard_screen.dart';
import 'features/access_control/role_access_screen.dart';
import 'features/fleet/availability_screen.dart';
import 'features/fleet/vehicle_list_screen.dart';
import 'features/fleet/vehicle_detail_screen.dart';
import 'features/customers/customer_list_screen.dart';
import 'features/customers/customer_detail_screen.dart';
import 'features/bookings/twende_booking_create_screen.dart';
import 'features/contracts/contract_detail_screen.dart';
import 'features/active_rentals/active_rentals_screen.dart';
import 'features/handover/handover_screen.dart';
import 'features/returns_inspection/return_screen.dart';
import 'features/returns_inspection/returns_due_screen.dart';
import 'features/billing_payments/billing_screen.dart';
import 'features/notifications_approvals/approvals_screen.dart';
import 'features/reports_ai/ask_fleet_screen.dart';
import 'features/maintenance/maintenance_screen.dart';
import 'features/trips/trips_screen.dart';
import 'features/reports_ai/reports_screen.dart';
import 'features/portal/portal_home_screen.dart';
import 'features/portal/portal_book_screen.dart';
import 'features/portal/portal_sign_screen.dart';
import 'features/portal/portal_pay_screen.dart';
import 'features/portal/portal_documents_screen.dart';
import 'features/driver_app/driver_home_screen.dart';
import 'features/driver_app/driver_job_detail_screen.dart';
import 'features/driver_app/driver_checklist_screen.dart';
import 'features/driver_app/driver_expense_screen.dart';
import 'features/driver_app/driver_incident_screen.dart';
import 'features/driver_app/driver_pod_screen.dart';
import 'features/rates/rates_screen.dart';
import 'features/damage/damage_incidents_screen.dart';
import 'features/settings/policies_screen.dart';

// Route name constants
class Routes {
  Routes._();
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String changePassword = '/change-password';
  static const String cars = '/cars';
  static const String booking = '/booking/:id';
  static const String bookings = '/bookings';
  static const String checkout = '/checkout';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String about = '/about';
  static const String contact = '/contact';
  static const String tos = '/tos';

  // Twende Fleet Routes
  static const String fleet = '/fleet';
  static const String availability = '/availability';
  static const String vehicleDetail = '/fleet/:id';
  static const String customers = '/customers';
  static const String customerDetail = '/customers/:id';
  static const String bookingNew = '/booking-new';
  static const String contractDetail = '/contract/:id';
  static const String activeRentals = '/active-rentals';
  static const String returnsDue = '/returns-due';
  static const String handover = '/handover/:id';
  static const String returnInspection = '/return/:id';
  static const String billing = '/billing';
  static const String approvals = '/approvals';
  static const String askFleet = '/ask-fleet';
  static const String maintenance = '/maintenance';
  static const String trips = '/trips';
  static const String reports = '/reports';
  static const String roleAccess = '/role-access';
  static const String rates = '/rates';
  static const String damage = '/damage';
  static const String policies = '/settings/policies';

  // Customer Portal Routes
  static const String portal = '/portal';
  static const String portalBook = '/portal/book';
  static const String portalSign = '/portal/sign/:token';
  static const String portalPay = '/portal/pay/:token';
  static const String portalDocuments = '/portal/documents';

  // Driver App Routes
  static const String driver = '/driver';
  static const String driverJob = '/driver/jobs/:id';
  static const String driverChecklist = '/driver/jobs/:id/checklist';
  static const String driverExpense = '/driver/jobs/:id/expense';
  static const String driverIncident = '/driver/jobs/:id/incident';
  static const String driverPod = '/driver/jobs/:id/pod';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: Routes.home,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;

      if (isLoading) return null;
      final routeAccess = AppRouteGuard.resolveRoute(state.matchedLocation);

      final protectedRoutes = [
        Routes.bookings,
        Routes.checkout,
        Routes.notifications,
        Routes.settings,
        Routes.changePassword,
      ];

      final isGoingToProtected = protectedRoutes.any(
              (r) => state.matchedLocation.startsWith(r.split(':').first)) ||
          routeAccess != null;

      if (!isAuthenticated && isGoingToProtected) {
        return '${Routes.signIn}?redirect=${state.matchedLocation}';
      }

      if (routeAccess != null &&
          !AppRouteGuard.canAccess(authState.user, state.matchedLocation)) {
        // Redirect to the user's correct home instead of '/' to avoid loops.
        final role = appRoleFromName(authState.user?.role);
        return switch (role) {
          AppRole.driverChauffeur => '${Routes.driver}?access=denied',
          AppRole.customer => '${Routes.portal}?access=denied',
          _ => '${Routes.dashboard}?access=denied',
        };
      }

      if (isAuthenticated && state.matchedLocation == Routes.home) {
        final role = appRoleFromName(authState.user?.role);
        if (role == AppRole.driverChauffeur) {
          return Routes.driver;
        }
        if (role == AppRole.customer) {
          return Routes.portal;
        }
        return Routes.dashboard;
      }

      // Prevent role bleed across shells.
      if (isAuthenticated) {
        final role = appRoleFromName(authState.user?.role);
        final loc = state.matchedLocation;
        if (role == AppRole.customer &&
            !loc.startsWith(Routes.portal) &&
            !_isPublicRoute(loc)) {
          return Routes.portal;
        }
        if (role == AppRole.driverChauffeur &&
            !loc.startsWith(Routes.driver) &&
            !_isPublicRoute(loc)) {
          return Routes.driver;
        }
        if (role != null &&
            role != AppRole.customer &&
            role != AppRole.driverChauffeur) {
          if (loc.startsWith(Routes.portal) || loc.startsWith(Routes.driver)) {
            return Routes.dashboard;
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: Routes.home, builder: (_, __) => const HomeScreen()),
      GoRoute(
          path: Routes.dashboard, builder: (_, __) => const DashboardScreen()),
      GoRoute(path: Routes.signIn, builder: (_, __) => const SignInScreen()),
      GoRoute(path: Routes.signUp, builder: (_, __) => const SignUpScreen()),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: Routes.changePassword,
        builder: (_, __) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: Routes.cars,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CarsScreen(params: extra);
        },
      ),
      GoRoute(
        path: Routes.booking,
        builder: (ctx, state) {
          final id = state.pathParameters['id']!;
          return BookingScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: Routes.bookings,
        builder: (_, __) => const BookingsScreen(),
      ),
      GoRoute(
        path: Routes.checkout,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PortalBookScreen(params: extra);
        },
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(path: Routes.about, builder: (_, __) => const AboutScreen()),
      GoRoute(path: Routes.contact, builder: (_, __) => const ContactScreen()),
      GoRoute(path: Routes.tos, builder: (_, __) => const TosScreen()),
      GoRoute(
        path: Routes.roleAccess,
        builder: (_, __) => const RoleAccessScreen(),
      ),

      // Twende Fleet Routes
      GoRoute(
          path: Routes.fleet, builder: (_, __) => const VehicleListScreen()),
      GoRoute(
          path: Routes.availability,
          builder: (_, __) => const AvailabilityScreen()),
      GoRoute(
        path: Routes.vehicleDetail,
        builder: (ctx, state) {
          final id = state.pathParameters['id']!;
          return VehicleDetailScreen(vehicleId: id);
        },
      ),
      GoRoute(
          path: Routes.customers,
          builder: (_, __) => const CustomerListScreen()),
      GoRoute(
        path: Routes.customerDetail,
        builder: (ctx, state) {
          final id = state.pathParameters['id']!;
          return CustomerDetailScreen(customerId: id);
        },
      ),
      GoRoute(
        path: Routes.bookingNew,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TwendeBookingCreateScreen(
            initialVehicleId: extra?['vehicleId'] as String?,
            initialCustomerId: extra?['customerId'] as String?,
          );
        },
      ),
      GoRoute(
        path: Routes.contractDetail,
        builder: (ctx, state) {
          final id = state.pathParameters['id']!;
          return ContractDetailScreen(contractId: id);
        },
      ),
      GoRoute(
          path: Routes.activeRentals,
          builder: (_, __) => const ActiveRentalsScreen()),
      GoRoute(
        path: Routes.returnsDue,
        builder: (_, __) => const ReturnsDueScreen(),
      ),
      GoRoute(
        path: Routes.handover,
        builder: (ctx, state) {
          final id = state.pathParameters['id']!;
          return HandoverScreen(contractId: id);
        },
      ),
      GoRoute(
        path: Routes.returnInspection,
        builder: (ctx, state) {
          final id = state.pathParameters['id']!;
          return ReturnScreen(contractId: id);
        },
      ),
      GoRoute(path: Routes.billing, builder: (_, __) => const BillingScreen()),
      GoRoute(
          path: Routes.approvals, builder: (_, __) => const ApprovalsScreen()),
      GoRoute(
          path: Routes.askFleet, builder: (_, __) => const AskFleetScreen()),
      GoRoute(
          path: Routes.maintenance,
          builder: (_, __) => const MaintenanceScreen()),
      GoRoute(path: Routes.trips, builder: (_, __) => const TripsScreen()),
      GoRoute(path: Routes.reports, builder: (_, __) => const ReportsScreen()),
      GoRoute(path: Routes.rates, builder: (_, __) => const RatesScreen()),
      GoRoute(path: Routes.damage, builder: (_, __) => const DamageIncidentsScreen()),
      GoRoute(path: Routes.policies, builder: (_, __) => const PoliciesScreen()),

      // Customer Portal Routes
      GoRoute(path: Routes.portal, builder: (_, __) => const PortalHomeScreen()),
      GoRoute(
        path: Routes.portalBook,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PortalBookScreen(params: extra);
        },
      ),
      GoRoute(
        path: Routes.portalSign,
        builder: (ctx, state) {
          final token = state.pathParameters['token']!;
          return PortalSignScreen(token: token);
        },
      ),
      GoRoute(
        path: Routes.portalPay,
        builder: (ctx, state) {
          final token = state.pathParameters['token']!;
          return PortalPayScreen(token: token);
        },
      ),
      GoRoute(
        path: Routes.portalDocuments,
        builder: (_, __) => const PortalDocumentsScreen(),
      ),

      // Driver App Routes
      GoRoute(path: Routes.driver, builder: (_, __) => const DriverHomeScreen()),
      GoRoute(
        path: Routes.driverJob,
        builder: (ctx, state) {
          final id = state.pathParameters['id']!;
          return DriverJobDetailScreen(tripId: id);
        },
      ),
      GoRoute(
        path: Routes.driverChecklist,
        builder: (ctx, state) {
          final id = state.pathParameters['id']!;
          return DriverChecklistScreen(tripId: id);
        },
      ),
      GoRoute(
        path: Routes.driverExpense,
        builder: (ctx, state) {
          final id = state.pathParameters['id']!;
          return DriverExpenseScreen(tripId: id);
        },
      ),
      GoRoute(
        path: Routes.driverIncident,
        builder: (ctx, state) {
          final id = state.pathParameters['id']!;
          return DriverIncidentScreen(tripId: id);
        },
      ),
      GoRoute(
        path: Routes.driverPod,
        builder: (ctx, state) {
          final id = state.pathParameters['id']!;
          return DriverPodScreen(tripId: id);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});

/// Routes accessible to any authenticated user regardless of role.
bool _isPublicRoute(String path) {
  const publicPrefixes = [
    Routes.signIn,
    Routes.signUp,
    Routes.forgotPassword,
    Routes.changePassword,
    Routes.about,
    Routes.contact,
    Routes.tos,
    Routes.settings,
    Routes.notifications,
  ];
  return publicPrefixes.any((p) => path == p || path.startsWith('$p/'));
}
