/// Twende Application Route Path Definitions
class TwendeRoutes {
  TwendeRoutes._();

  // Root & Auth
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';

  // Operate Shell
  static const String fleet = '/fleet';
  static const String vehicleDetail = '/fleet/:id';
  static const String availability = '/availability';
  static const String activeRentals = '/active-rentals';
  static const String returnsDue = '/returns-due';
  static const String bookings = '/bookings';
  static const String bookingNew = '/booking-new';
  static const String contractDetail = '/contract/:id';
  static const String handover = '/handover/:id';
  static const String returnInspection = '/return/:id';

  // Manage Shell
  static const String customers = '/customers';
  static const String customerDetail = '/customers/:id';
  static const String trips = '/trips';
  static const String tripNew = '/trip-new';
  static const String maintenance = '/maintenance';

  // Money & Insight Shell
  static const String billing = '/billing';
  static const String invoiceDetail = '/billing/:id';
  static const String approvals = '/approvals';
  static const String reports = '/reports';
  static const String askFleet = '/ask-fleet';
  static const String roleAccess = '/role-access';
}
