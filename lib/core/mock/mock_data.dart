// lib/core/mock/mock_data.dart
import '../constants/app_constants.dart';
import '../auth/permissions.dart';
import '../../models/booking.dart';
import '../../models/car.dart';
import '../../models/location.dart';
import '../../models/notification.dart';
import '../../models/supplier.dart';
import '../../models/user.dart';

class DemoAccount {
  const DemoAccount({
    required this.role,
    required this.email,
    required this.password,
    required this.name,
  });

  final AppRole role;
  final String email;
  final String password;
  final String name;

  String get roleLabel => appRoleLabel(role);
  String get description => appRoleDescription(role);

  User get user => MockData.demoUser.copyWith(
        id: 'demo-${appRoleKey(role)}',
        email: email,
        fullName: name,
        role: appRoleKey(role),
        roles: [appRoleKey(role)],
      );
}

class MockData {
  MockData._();

  static const List<DemoAccount> demoAccounts = [
    DemoAccount(
      role: AppRole.systemAdministrator,
      email: 'system-admin@demo.twende.app',
      password: 'DemoAdmin123!',
      name: 'Demo System Administrator',
    ),
    DemoAccount(
      role: AppRole.ownerManagement,
      email: 'management@demo.twende.app',
      password: 'DemoOwner123!',
      name: 'Demo Owner',
    ),
    DemoAccount(
      role: AppRole.rentalManager,
      email: 'rental-manager@demo.twende.app',
      password: 'DemoManager123!',
      name: 'Demo Rental Manager',
    ),
    DemoAccount(
      role: AppRole.rentalOfficer,
      email: 'rental-officer@demo.twende.app',
      password: 'DemoOfficer123!',
      name: 'Demo Rental Officer',
    ),
    DemoAccount(
      role: AppRole.fleetManager,
      email: 'fleet-manager@demo.twende.app',
      password: 'DemoFleet123!',
      name: 'Demo Fleet Manager',
    ),
    DemoAccount(
      role: AppRole.financeOfficer,
      email: 'finance@demo.twende.app',
      password: 'DemoFinance123!',
      name: 'Demo Finance Officer',
    ),
    DemoAccount(
      role: AppRole.driverChauffeur,
      email: 'driver@demo.twende.app',
      password: 'DemoDriver123!',
      name: 'Demo Driver',
    ),
    DemoAccount(
      role: AppRole.customer,
      email: 'customer@demo.twende.app',
      password: 'DemoCustomer123!',
      name: 'Demo Customer',
    ),
  ];

  static final User demoUser = User(
    id: 'user-mock-1',
    email: 'demo@twende.app',
    fullName: 'Jean-Paul Mugisha',
    phone: '+250 788 123 456',
    birthDate: DateTime(1992, 5, 14),
    language: 'en',
    location: 'Kigali, Rwanda',
    bio: 'Twende fleet operations and rental manager.',
    role: 'rental_manager',
    accessToken: 'mock-jwt-token-demo-user',
    blacklisted: false,
    enableEmailNotifications: true,
  );

  static User demoUserForEmail(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    for (final account in demoAccounts) {
      if (account.email == normalizedEmail) return account.user;
    }
    return demoUser.copyWith(email: email);
  }

  static DemoAccount? demoAccountForCredentials(String email, String password) {
    final normalizedEmail = email.trim().toLowerCase();
    for (final account in demoAccounts) {
      if (account.email == normalizedEmail && account.password == password) {
        return account;
      }
    }
    return null;
  }

  static final List<Supplier> suppliers = [
    const Supplier(
      id: 'supp-1',
      fullName: 'Twende Fleet Kigali Central',
      email: 'kigali@twende.app',
      phone: '+250 788 001 001',
      location: 'Kigali, Rwanda',
      avatar: 'assets/images/logo.png',
    ),
    const Supplier(
      id: 'supp-2',
      fullName: 'Twende Airport Hub',
      email: 'airport@twende.app',
      phone: '+250 788 002 002',
      location: 'Kigali International Airport',
      avatar: 'assets/images/logo.png',
    ),
    const Supplier(
      id: 'supp-3',
      fullName: 'Twende Northern Province',
      email: 'musanze@twende.app',
      phone: '+250 788 003 003',
      location: 'Musanze, Rwanda',
      avatar: 'assets/images/logo.png',
    ),
    const Supplier(
      id: 'supp-4',
      fullName: 'Twende Western Hub',
      email: 'rubavu@twende.app',
      phone: '+250 788 004 004',
      location: 'Rubavu, Rwanda',
      avatar: 'assets/images/logo.png',
    ),
    const Supplier(
      id: 'supp-5',
      fullName: 'Twende Logistics & Heavy Fleet',
      email: 'logistics@twende.app',
      phone: '+250 788 005 005',
      location: 'Gikondo Terminal, Kigali',
      avatar: 'assets/images/logo.png',
    ),
  ];

  static final List<Location> locations = [
    const Location(
      id: 'loc-1',
      name: 'Kigali HQ (Downtown City Center)',
      values: [
        LocationValue(language: 'en', value: 'Kigali HQ (Downtown City Center)'),
        LocationValue(language: 'fr', value: 'Siège Kigali (Centre-ville)'),
      ],
      latitude: -1.9441,
      longitude: 30.0619,
    ),
    const Location(
      id: 'loc-2',
      name: 'Kigali International Airport (KGL)',
      values: [
        LocationValue(language: 'en', value: 'Kigali International Airport (KGL)'),
        LocationValue(language: 'fr', value: 'Aéroport International de Kigali (KGL)'),
      ],
      latitude: -1.9686,
      longitude: 30.1395,
    ),
    const Location(
      id: 'loc-3',
      name: 'Rubavu (Gisenyi) Lake Kivu Hub',
      values: [
        LocationValue(language: 'en', value: 'Rubavu (Gisenyi) Lake Kivu Hub'),
        LocationValue(language: 'fr', value: 'Agence Rubavu (Gisenyi)'),
      ],
      latitude: -1.6766,
      longitude: 29.2608,
    ),
    const Location(
      id: 'loc-4',
      name: 'Musanze (Ruhengeri) Northern Hub',
      values: [
        LocationValue(language: 'en', value: 'Musanze (Ruhengeri) Northern Hub'),
        LocationValue(language: 'fr', value: 'Agence Musanze (Ruhengeri)'),
      ],
      latitude: -1.4989,
      longitude: 29.6338,
    ),
    const Location(
      id: 'loc-5',
      name: 'Gikondo Logistics & Truck Terminal',
      values: [
        LocationValue(language: 'en', value: 'Gikondo Logistics & Truck Terminal'),
        LocationValue(language: 'fr', value: 'Terminal Logistique Gikondo'),
      ],
      latitude: -1.9700,
      longitude: 30.0750,
    ),
  ];

  static final List<Car> cars = [
    Car(
      id: 'car-1',
      name: 'Volkswagen Golf 8',
      supplier: suppliers[0],
      price: 45.0,
      image: 'assets/images/mini.png',
      type: CarType.gasoline,
      gearbox: GearboxType.manual,
      seats: 5,
      doors: 5,
      aircon: true,
      fuelPolicy: FuelPolicy.likeForLike,
      mileage: -1,
      deposit: 500,
      available: true,
      rating: 4.8,
      trips: 35,
      multimedia: true,
      cancellation: 0,
      amendments: 0,
      theftProtection: 0,
      collisionDamageWaiver: 12,
      fullInsurance: 20,
      additionalDriver: 0,
    ),
    Car(
      id: 'car-2',
      name: 'Audi A4 2.0 TDI',
      supplier: suppliers[1],
      price: 75.0,
      image: 'assets/images/midi.png',
      type: CarType.diesel,
      gearbox: GearboxType.automatic,
      seats: 5,
      doors: 4,
      aircon: true,
      fuelPolicy: FuelPolicy.likeForLike,
      mileage: -1,
      deposit: 1000,
      available: true,
      rating: 4.9,
      trips: 52,
      multimedia: true,
      cancellation: 0,
      amendments: 0,
      theftProtection: 0,
      collisionDamageWaiver: 15,
      fullInsurance: 25,
      additionalDriver: 8,
    ),
    Car(
      id: 'car-3',
      name: 'BMW 3 Series Sedan',
      supplier: suppliers[3],
      price: 85.0,
      image: 'assets/images/midi.png',
      type: CarType.gasoline,
      gearbox: GearboxType.automatic,
      seats: 5,
      doors: 4,
      aircon: true,
      fuelPolicy: FuelPolicy.likeForLike,
      mileage: -1,
      deposit: 1200,
      available: true,
      rating: 4.9,
      trips: 68,
      multimedia: true,
      cancellation: 0,
      amendments: 0,
      theftProtection: 0,
      collisionDamageWaiver: 18,
      fullInsurance: 28,
      additionalDriver: 10,
    ),
    Car(
      id: 'car-4',
      name: 'Tesla Model 3 Long Range',
      supplier: suppliers[4],
      price: 90.0,
      image: 'assets/images/maxi.png',
      type: CarType.electric,
      gearbox: GearboxType.automatic,
      seats: 5,
      doors: 4,
      aircon: true,
      fuelPolicy: FuelPolicy.likeForLike,
      mileage: -1,
      deposit: 1500,
      available: true,
      rating: 4.85,
      trips: 44,
      multimedia: true,
      cancellation: 0,
      amendments: 0,
      theftProtection: 0,
      collisionDamageWaiver: 20,
      fullInsurance: 30,
      additionalDriver: 0,
    ),
    Car(
      id: 'car-5',
      name: 'Mercedes-Benz C-Class',
      supplier: suppliers[2],
      price: 95.0,
      image: 'assets/images/midi.png',
      type: CarType.hybrid,
      gearbox: GearboxType.automatic,
      seats: 5,
      doors: 4,
      aircon: true,
      fuelPolicy: FuelPolicy.likeForLike,
      mileage: -1,
      deposit: 1500,
      available: true,
      rating: 4.95,
      trips: 80,
      multimedia: true,
      cancellation: 0,
      amendments: 0,
      theftProtection: 0,
      collisionDamageWaiver: 20,
      fullInsurance: 30,
      additionalDriver: 12,
    ),
    Car(
      id: 'car-6',
      name: 'Ford Mustang GT V8',
      supplier: suppliers[1],
      price: 110.0,
      image: 'assets/images/midi.png',
      type: CarType.gasoline,
      gearbox: GearboxType.automatic,
      seats: 4,
      doors: 2,
      aircon: true,
      fuelPolicy: FuelPolicy.likeForLike,
      mileage: 300,
      deposit: 2000,
      available: true,
      rating: 4.9,
      trips: 29,
      multimedia: true,
      cancellation: 15,
      amendments: 0,
      theftProtection: 10,
      collisionDamageWaiver: 25,
      fullInsurance: 35,
      additionalDriver: 15,
    ),
    Car(
      id: 'car-7',
      name: 'Range Rover Evoque',
      supplier: suppliers[0],
      price: 120.0,
      image: 'assets/images/maxi.png',
      type: CarType.diesel,
      gearbox: GearboxType.automatic,
      seats: 5,
      doors: 5,
      aircon: true,
      fuelPolicy: FuelPolicy.likeForLike,
      mileage: -1,
      deposit: 2000,
      available: true,
      rating: 4.8,
      trips: 41,
      multimedia: true,
      cancellation: 0,
      amendments: 0,
      theftProtection: 0,
      collisionDamageWaiver: 25,
      fullInsurance: 35,
      additionalDriver: 10,
    ),
    Car(
      id: 'car-8',
      name: 'Toyota Yaris Hybrid',
      supplier: suppliers[4],
      price: 35.0,
      image: 'assets/images/mini.png',
      type: CarType.hybrid,
      gearbox: GearboxType.automatic,
      seats: 5,
      doors: 4,
      aircon: true,
      fuelPolicy: FuelPolicy.freeTank,
      mileage: -1,
      deposit: 400,
      available: true,
      rating: 4.7,
      trips: 95,
      multimedia: true,
      cancellation: 0,
      amendments: 0,
      theftProtection: 0,
      collisionDamageWaiver: 10,
      fullInsurance: 15,
      additionalDriver: 5,
    ),
    Car(
      id: 'car-9',
      name: 'Hyundai Tucson 4WD',
      supplier: suppliers[3],
      price: 65.0,
      image: 'assets/images/maxi.png',
      type: CarType.gasoline,
      gearbox: GearboxType.automatic,
      seats: 5,
      doors: 5,
      aircon: true,
      fuelPolicy: FuelPolicy.likeForLike,
      mileage: -1,
      deposit: 800,
      available: true,
      rating: 4.75,
      trips: 60,
      multimedia: true,
      cancellation: 0,
      amendments: 0,
      theftProtection: 0,
      collisionDamageWaiver: 14,
      fullInsurance: 22,
      additionalDriver: 8,
    ),
    Car(
      id: 'car-10',
      name: 'Renault Clio 1.0 TCe',
      supplier: suppliers[0],
      price: 30.0,
      image: 'assets/images/mini.png',
      type: CarType.gasoline,
      gearbox: GearboxType.manual,
      seats: 5,
      doors: 4,
      aircon: true,
      fuelPolicy: FuelPolicy.likeForLike,
      mileage: -1,
      deposit: 350,
      available: true,
      rating: 4.6,
      trips: 110,
      multimedia: false,
      cancellation: 0,
      amendments: 0,
      theftProtection: 0,
      collisionDamageWaiver: 8,
      fullInsurance: 14,
      additionalDriver: 0,
    ),
  ];

  static final List<Booking> _bookings = [
    Booking(
      id: 'book-1',
      driver: demoUser,
      car: cars[1], // Audi A4
      pickupLocation: locations[0], // JFK
      dropOffLocation: locations[0], // JFK
      from: DateTime.now().add(const Duration(days: 3, hours: 10)),
      to: DateTime.now().add(const Duration(days: 7, hours: 10)),
      status: 'Reserved',
      price: 300.0,
      cancellation: true,
      fullInsurance: true,
    ),
    Booking(
      id: 'book-2',
      driver: demoUser,
      car: cars[0], // Golf
      pickupLocation: locations[2], // CDG
      dropOffLocation: locations[3], // Paris Center
      from: DateTime.now().subtract(const Duration(days: 14)),
      to: DateTime.now().subtract(const Duration(days: 10)),
      status: 'Paid',
      price: 180.0,
      cancellation: true,
    ),
    Booking(
      id: 'book-3',
      driver: demoUser,
      car: cars[3], // Tesla
      pickupLocation: locations[4], // LHR
      dropOffLocation: locations[4], // LHR
      from: DateTime.now().subtract(const Duration(days: 30)),
      to: DateTime.now().subtract(const Duration(days: 28)),
      status: 'Cancelled',
      price: 180.0,
    ),
  ];

  static List<Booking> get bookings => _bookings;

  static void addBooking(Booking booking) {
    _bookings.insert(0, booking);
  }

  static void cancelBooking(String bookingId) {
    final idx = _bookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final old = _bookings[idx];
      _bookings[idx] = Booking(
        id: old.id,
        driver: old.driver,
        car: old.car,
        pickupLocation: old.pickupLocation,
        dropOffLocation: old.dropOffLocation,
        from: old.from,
        to: old.to,
        status: 'Cancelled',
        price: old.price,
        cancellation: old.cancellation,
        amendments: old.amendments,
        theftProtection: old.theftProtection,
        collisionDamageWaiver: old.collisionDamageWaiver,
        fullInsurance: old.fullInsurance,
        additionalDriver: old.additionalDriver,
        cancelRequest: DateTime.now(),
      );
    }
  }

  static final List<AppNotification> _notifications = [
    AppNotification(
      id: 'notif-1',
      user: 'user-mock-1',
      message: 'Your booking for Audi A4 2.0 TDI has been confirmed.',
      isRead: false,
      booking: 'book-1',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'notif-2',
      user: 'user-mock-1',
      message: 'Reminder: Pickup scheduled at JFK Airport in 3 days.',
      isRead: false,
      booking: 'book-1',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AppNotification(
      id: 'notif-3',
      user: 'user-mock-1',
      message:
          'Welcome to Twende! 🚗 Find and rent your ideal vehicle worldwide.',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static List<AppNotification> get notifications => _notifications;

  static void markNotificationRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      final old = _notifications[idx];
      _notifications[idx] = AppNotification(
        id: old.id,
        user: old.user,
        message: old.message,
        isRead: true,
        booking: old.booking,
        createdAt: old.createdAt,
      );
    }
  }

  static void markAllNotificationsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      final old = _notifications[i];
      _notifications[i] = AppNotification(
        id: old.id,
        user: old.user,
        message: old.message,
        isRead: true,
        booking: old.booking,
        createdAt: old.createdAt,
      );
    }
  }

  static void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
  }
}
