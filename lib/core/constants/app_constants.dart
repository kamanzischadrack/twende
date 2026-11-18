// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  static const String appName = 'Twende';
  static const String appType = 'frontend';

  // Pagination
  static const int pageSize = 20;
  static const int carsPageSize = 8;
  static const int bookingsPageSize = 8;
  static const int vehiclesPageSize = 10;
  static const int contractsPageSize = 10;
  static const int invoicesPageSize = 10;

  // Network
  static const int connectTimeout = 5000;
  static const int receiveTimeout = 10000;
  static const int maxRetries = 3;
  static const int retryInterval = 500;

  // Validation
  static const int minimumAge = 21;
  static const int minPasswordLength = 6;

  // Storage keys
  static const String userStorageKey = 'bc-user';
  static const String languageStorageKey = 'bc-language';
  static const String currencyStorageKey = 'bc-currency';
  static const String branchStorageKey = 'twende-branch';
  static const String tenantStorageKey = 'twende-tenant';

  // Currencies
  static const List<String> supportedCurrencies = ['RWF', 'USD', 'EUR', 'GBP'];

  // Supported languages
  static const List<Map<String, String>> languages = [
    {'code': 'en', 'label': 'English'},
    {'code': 'fr', 'label': 'Français'},
    {'code': 'es', 'label': 'Español'},
    {'code': 'de', 'label': 'Deutsch'},
    {'code': 'pt', 'label': 'Português'},
    {'code': 'it', 'label': 'Italiano'},
    {'code': 'zh', 'label': '中文'},
    {'code': 'ja', 'label': '日本語'},
  ];

  static const List<Map<String, String>> twendeLanguages = [
    {'code': 'en', 'label': 'English'},
    {'code': 'rw', 'label': 'Kinyarwanda'},
    {'code': 'fr', 'label': 'Français'},
  ];

  static const String defaultLanguage = 'en';
  static const String defaultCurrency = 'RWF';

  // Twende: Approval thresholds (defaults, overridden by tenant config)
  static const double discountApprovalThreshold = 0.20; // 20%
  static const double refundApprovalThresholdRwf = 50000.0;
  static const double defaultDepositAmount = 150000.0;
  static const int defaultDailyMileageAllowanceKm = 150;

  // Twende: Operational defaults (overridden by tenant config)
  static const int lateReturnGraceMinutes = 60;
  static const int turnaroundBufferHours = 2;
  static const int rentalDayHours = 24; // 24h rolling day definition
}

// Booking status values (matches API enum)
class BookingStatus {
  BookingStatus._();
  static const String void_ = 'void';
  static const String pending = 'pending';
  static const String deposit = 'deposit';
  static const String paid = 'paid';
  static const String paidInFull = 'paidInFull';
  static const String reserved = 'reserved';
  static const String cancelled = 'cancelled';
}

// Car type values
class CarType {
  CarType._();
  static const String diesel = 'diesel';
  static const String gasoline = 'gasoline';
  static const String electric = 'electric';
  static const String hybrid = 'hybrid';
  static const String mildhybrid = 'mildhybrid';
  static const String unknown = 'unknown';
}

// Gearbox type values
class GearboxType {
  GearboxType._();
  static const String manual = 'manual';
  static const String automatic = 'automatic';
}

// Fuel policy values
class FuelPolicy {
  FuelPolicy._();
  static const String likeForLike = 'likeForLike';
  static const String freeTank = 'freeTank';
  static const String fullToFull = 'fullToFull';
  static const String prepaid = 'prepaid';
  static const String fuelIncluded = 'fuelIncluded';
}

// Car range values
class CarRange {
  CarRange._();
  static const String mini = 'mini';
  static const String midi = 'midi';
  static const String maxi = 'maxi';
  static const String scooter = 'scooter';
}

// Mileage values
class Mileage {
  Mileage._();
  static const String limited = 'limited';
  static const String unlimited = 'unlimited';
}

// Twende vehicle status values
class VehicleStatusConst {
  VehicleStatusConst._();
  static const String available      = 'available';
  static const String reserved       = 'reserved';
  static const String rented         = 'rented';
  static const String returned       = 'returned';
  static const String underInspection = 'underInspection';
  static const String underMaintenance = 'underMaintenance';
  static const String accident       = 'accident';
  static const String outOfService   = 'outOfService';
  static const String sold           = 'sold';
  static const String archived       = 'archived';
}
