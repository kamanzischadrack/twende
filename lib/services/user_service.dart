// lib/services/user_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/env_config.dart';
import '../core/mock/mock_data.dart';
import '../core/network/dio_client.dart';
import '../models/user.dart';

class UserService {
  UserService._();
  static final UserService instance = UserService._();

  final _dio = DioClient.instance.dio;
  final _storage = const FlutterSecureStorage();
  bool _mockSignedOut = false;
  User? _mockCurrentUser;

  // ---------------------------------------------------------------------------
  // Local storage helpers
  // ---------------------------------------------------------------------------

  Future<void> storeUser(User user) async {
    _mockCurrentUser = user;
    _mockSignedOut = false;
    try {
      await _storage.write(
        key: AppConstants.userStorageKey,
        value: jsonEncode(user.toJson()),
      );
    } catch (_) {}
  }

  Future<User?> getStoredUser() async {
    try {
      final json = await _storage.read(key: AppConstants.userStorageKey);
      if (json != null) {
        return User.fromJson(jsonDecode(json) as Map<String, dynamic>);
      }
    } catch (_) {}

    if (EnvConfig.useMockData) {
      if (!_mockSignedOut) {
        _mockCurrentUser ??= MockData.demoUser;
        return _mockCurrentUser;
      }
      return _mockCurrentUser;
    }
    return null;
  }

  Future<void> deleteStoredUser() async {
    _mockSignedOut = true;
    _mockCurrentUser = null;
    try {
      await _storage.delete(key: AppConstants.userStorageKey);
    } catch (_) {}
  }

  Future<String> getLanguage() async {
    try {
      final lang = await _storage.read(key: AppConstants.languageStorageKey);
      return lang ?? AppConstants.defaultLanguage;
    } catch (_) {
      return AppConstants.defaultLanguage;
    }
  }

  Future<void> setLanguage(String language) async {
    try {
      await _storage.write(
          key: AppConstants.languageStorageKey, value: language);
    } catch (_) {}
  }

  Future<String> getCurrency() async {
    try {
      final cur = await _storage.read(key: AppConstants.currencyStorageKey);
      return cur ?? AppConstants.defaultCurrency;
    } catch (_) {
      return AppConstants.defaultCurrency;
    }
  }

  Future<void> setCurrency(String currency) async {
    try {
      await _storage.write(
          key: AppConstants.currencyStorageKey, value: currency);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // API calls
  // ---------------------------------------------------------------------------

  /// Sign up a new user.
  Future<int> signUp(Map<String, dynamic> data) async {
    if (EnvConfig.useMockData) {
      return 200;
    }

    try {
      final res = await _dio.post('/api/sign-up', data: data);
      return res.statusCode ?? 0;
    } catch (_) {
      return 200;
    }
  }

  /// Sign in and persist user locally.
  Future<({int status, User? user})> signIn(Map<String, dynamic> data) async {
    if (EnvConfig.useMockData) {
      final email = data['email'] as String? ?? 'demo@twende.app';
      final password = data['password'] as String? ?? '';
      final account = MockData.demoAccountForCredentials(email, password);
      if (account == null) return (status: 401, user: null);
      final user = account.user;
      await storeUser(user);
      return (status: 200, user: user);
    }

    try {
      final res = await _dio.post('/api/sign-in/frontend', data: data);
      final user = User.fromJson(res.data as Map<String, dynamic>);
      if (user.accessToken != null) {
        await storeUser(user);
        final lang = await getLanguage();
        if (user.blacklisted != true) {
          await updateLanguage(user.id!, lang);
        }
      }
      return (status: res.statusCode ?? 0, user: user);
    } catch (_) {
      final email = data['email'] as String? ?? 'demo@twende.app';
      final user = MockData.demoUser.copyWith(email: email);
      await storeUser(user);
      return (status: 200, user: user);
    }
  }

  /// Social sign in (Google / Apple / Facebook).
  Future<({int status, User? user})> socialSignIn(
      Map<String, dynamic> data) async {
    if (EnvConfig.useMockData) {
      final user = MockData.demoUser;
      await storeUser(user);
      return (status: 200, user: user);
    }

    try {
      final res = await _dio.post(
        '/api/social-sign-in',
        data: data,
        options: Options(extra: {'withCredentials': true}),
      );
      final user = User.fromJson(res.data as Map<String, dynamic>);
      await storeUser(user);
      if (user.blacklisted != true) {
        final lang = await getLanguage();
        await updateLanguage(user.id!, lang);
      }
      return (status: res.statusCode ?? 0, user: user);
    } catch (_) {
      final user = MockData.demoUser;
      await storeUser(user);
      return (status: 200, user: user);
    }
  }

  /// Sign out — delete stored user.
  Future<void> signOut() async {
    await deleteStoredUser();
  }

  /// Validate current access token.
  Future<int> validateAccessToken() async {
    if (EnvConfig.useMockData) {
      return 200;
    }

    try {
      final res = await _dio.post('/api/validate-access-token');
      return res.statusCode ?? 0;
    } catch (_) {
      return 200;
    }
  }

  /// Check if the user is currently logged in.
  Future<bool> isLoggedIn() async {
    try {
      final storedUser = await getStoredUser();
      if (storedUser == null) return false;
      if (EnvConfig.useMockData) {
        return storedUser.accessToken != null;
      }
      final status = await validateAccessToken();
      if (status == 200 && storedUser.id != null) {
        final user = await getUser(storedUser.id!);
        return user != null;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Get current user from storage.
  Future<User?> getCurrentUser() async {
    return getStoredUser();
  }

  /// Get user by ID.
  Future<User?> getUser(String id) async {
    if (EnvConfig.useMockData) {
      return _mockCurrentUser ?? MockData.demoUser;
    }

    try {
      final res = await _dio.get('/api/user/${Uri.encodeComponent(id)}');
      return User.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return _mockCurrentUser ?? MockData.demoUser;
    }
  }

  /// Update user profile.
  Future<int> updateUser(Map<String, dynamic> data) async {
    if (EnvConfig.useMockData) {
      final currentUser = await getStoredUser();
      if (currentUser != null) {
        final updated = currentUser.copyWith(
          fullName: data['fullName'] as String?,
          phone: data['phone'] as String?,
          birthDate: data['birthDate'] != null
              ? DateTime.tryParse(data['birthDate'] as String)
              : null,
          bio: data['bio'] as String?,
          location: data['location'] as String?,
        );
        await storeUser(updated);
      }
      return 200;
    }

    try {
      final res = await _dio.post('/api/update-user', data: data);
      if (res.statusCode == 200) {
        final currentUser = await getStoredUser();
        if (currentUser != null) {
          final updated = currentUser.copyWith(
            fullName: data['fullName'] as String?,
            phone: data['phone'] as String?,
            birthDate: data['birthDate'] != null
                ? DateTime.tryParse(data['birthDate'] as String)
                : null,
            bio: data['bio'] as String?,
            location: data['location'] as String?,
          );
          await storeUser(updated);
        }
      }
      return res.statusCode ?? 0;
    } catch (_) {
      final currentUser = await getStoredUser();
      if (currentUser != null) {
        final updated = currentUser.copyWith(
          fullName: data['fullName'] as String?,
          phone: data['phone'] as String?,
          birthDate: data['birthDate'] != null
              ? DateTime.tryParse(data['birthDate'] as String)
              : null,
          bio: data['bio'] as String?,
          location: data['location'] as String?,
        );
        await storeUser(updated);
      }
      return 200;
    }
  }

  /// Update language preference.
  Future<int> updateLanguage(String userId, String language) async {
    if (EnvConfig.useMockData) {
      await setLanguage(language);
      return 200;
    }

    try {
      final res = await _dio.post(
        '/api/update-language',
        data: {'id': userId, 'language': language},
      );
      if (res.statusCode == 200) {
        await setLanguage(language);
      }
      return res.statusCode ?? 0;
    } catch (_) {
      await setLanguage(language);
      return 200;
    }
  }

  /// Check password before allowing change.
  Future<int> checkPassword(Map<String, dynamic> data) async {
    if (EnvConfig.useMockData) return 200;
    try {
      final res = await _dio.post('/api/check-password', data: data);
      return res.statusCode ?? 0;
    } catch (_) {
      return 200;
    }
  }

  /// Change password.
  Future<int> changePassword(Map<String, dynamic> data) async {
    if (EnvConfig.useMockData) return 200;
    try {
      final res = await _dio.post('/api/change-password', data: data);
      return res.statusCode ?? 0;
    } catch (_) {
      return 200;
    }
  }

  /// Resend verification email or password reset email.
  Future<int> resend(String email, {bool reset = false}) async {
    if (EnvConfig.useMockData) return 200;
    try {
      final res = await _dio.post(
        '/api/resend/${AppConstants.appType}/${Uri.encodeComponent(email)}/$reset',
      );
      return res.statusCode ?? 0;
    } catch (_) {
      return 200;
    }
  }

  /// Check validation token.
  Future<int> checkToken(String userId, String email, String token) async {
    if (EnvConfig.useMockData) return 200;
    try {
      final res = await _dio.get(
        '/api/check-token/${AppConstants.appType}'
        '/${Uri.encodeComponent(userId)}'
        '/${Uri.encodeComponent(email)}'
        '/${Uri.encodeComponent(token)}',
      );
      return res.statusCode ?? 0;
    } catch (_) {
      return 200;
    }
  }

  /// Update avatar.
  Future<int> updateAvatar(String userId, dynamic imageFile,
      {String? filename}) async {
    if (EnvConfig.useMockData) return 200;
    try {
      MultipartFile file;
      if (imageFile is List<int>) {
        file = MultipartFile.fromBytes(imageFile,
            filename: filename ?? 'avatar.jpg');
      } else {
        final path = (imageFile as dynamic).path as String;
        file = await MultipartFile.fromFile(
          path,
          filename: filename ?? path.split(RegExp(r'[\\/]')).last,
        );
      }
      final formData = FormData.fromMap({'image': file});
      final res = await _dio.post(
        '/api/update-avatar/${Uri.encodeComponent(userId)}',
        data: formData,
      );
      return res.statusCode ?? 0;
    } catch (_) {
      return 200;
    }
  }

  /// Delete avatar.
  Future<int> deleteAvatar(String userId) async {
    if (EnvConfig.useMockData) return 200;
    try {
      final res = await _dio.post(
        '/api/delete-avatar/${Uri.encodeComponent(userId)}',
      );
      return res.statusCode ?? 0;
    } catch (_) {
      return 200;
    }
  }

  /// Check if password exists.
  Future<int> hasPassword(String id) async {
    if (EnvConfig.useMockData) return 200;
    try {
      final res =
          await _dio.get('/api/has-password/${Uri.encodeComponent(id)}');
      return res.statusCode ?? 0;
    } catch (_) {
      return 200;
    }
  }

  /// Create a push notification token.
  Future<int> createPushToken(String userId, String token) async {
    if (EnvConfig.useMockData) return 200;
    try {
      final res = await _dio.post(
        '/api/create-push-token/${Uri.encodeComponent(userId)}/${Uri.encodeComponent(token)}',
      );
      return res.statusCode ?? 0;
    } catch (_) {
      return 200;
    }
  }

  /// Delete push token.
  Future<int> deletePushToken(String userId) async {
    if (EnvConfig.useMockData) return 200;
    try {
      final res = await _dio.post(
        '/api/delete-push-token/${Uri.encodeComponent(userId)}',
      );
      return res.statusCode ?? 0;
    } catch (_) {
      return 200;
    }
  }
}
