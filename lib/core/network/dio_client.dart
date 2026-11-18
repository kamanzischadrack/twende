// lib/core/network/dio_client.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/env_config.dart';
import '../constants/app_constants.dart';

class DioClient {
  DioClient._() {
    initialize();
  }

  static final DioClient _instance = DioClient._();
  static DioClient get instance => _instance;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiHost,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Inject auth token if available
          final token = await _getAccessToken();
          if (token != null) {
            options.headers['x-access-token'] = token;
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Retry on connection errors (up to maxRetries)
          final extra = e.requestOptions.extra;
          final retryCount = extra['retryCount'] as int? ?? 0;

          if (_shouldRetry(e) && retryCount < AppConstants.maxRetries) {
            await Future.delayed(
              const Duration(milliseconds: AppConstants.retryInterval),
            );
            e.requestOptions.extra['retryCount'] = retryCount + 1;
            try {
              final response = await _dio.fetch(e.requestOptions);
              return handler.resolve(response);
            } catch (_) {}
          }
          return handler.next(e);
        },
      ),
    );
  }

  bool _shouldRetry(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  Future<String?> _getAccessToken() async {
    try {
      final userJson = await _storage.read(key: AppConstants.userStorageKey);
      if (userJson != null) {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        return map['accessToken'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Dio get dio => _dio;
}
