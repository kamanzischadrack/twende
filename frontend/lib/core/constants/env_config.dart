// lib/core/constants/env_config.dart
import 'app_constants.dart';

class EnvConfig {
  EnvConfig._();

  /// When true, mock data will be served by all services for demo/testing without a backend.
  static const bool useMockData =
      bool.fromEnvironment('USE_MOCK_DATA', defaultValue: true);

  /// The Twende backend API base URL.
  static const String apiHost =
      String.fromEnvironment('API_HOST', defaultValue: 'http://10.0.2.2:4002');

  /// CDN URLs for user/car/license images
  static const String cdnUsers =
      String.fromEnvironment('CDN_USERS', defaultValue: '');
  static const String cdnCars =
      String.fromEnvironment('CDN_CARS', defaultValue: '');
  static const String cdnLicenses =
      String.fromEnvironment('CDN_LICENSES', defaultValue: '');
  static const String cdnTempLicenses =
      String.fromEnvironment('CDN_TEMP_LICENSES', defaultValue: '');

  /// Stripe publishable key
  static const String stripePublishableKey =
      String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', defaultValue: '');

  /// Stripe merchant identifier (Apple Pay)
  static const String stripeMerchantIdentifier =
      String.fromEnvironment('STRIPE_MERCHANT_IDENTIFIER', defaultValue: '');

  /// ISO 3166 country code for Stripe, e.g. "US"
  static const String stripeCountryCode =
      String.fromEnvironment('STRIPE_COUNTRY_CODE', defaultValue: 'US');

  /// Google Sign-In Web Client ID
  static const String googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

  /// Website/app display name
  static const String websiteName =
      String.fromEnvironment('WEBSITE_NAME', defaultValue: 'Twende');

  /// Base currency code e.g. "USD"
  static const String baseCurrency =
      String.fromEnvironment('BASE_CURRENCY', defaultValue: 'USD');

  /// Minimum age requirement
  static const int minimumAge = AppConstants.minimumAge;

  /// Deposit filter preset values
  static const double depositFilterValue1 = 1500;
  static const double depositFilterValue2 = 3000;
  static const double depositFilterValue3 = 5000;
}
