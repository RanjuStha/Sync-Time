import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flexyear/services/api_urls.dart';

/// What every API call returns. Controllers only ever deal with this.
class ApiResponse {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });

  final bool success;
  final String message; // server message, or a friendly error
  final dynamic data; // decoded JSON (Map or List)
  final int? statusCode;

  /// Response body as a Map (empty if the body isn't a Map).
  Map<String, dynamic> get map =>
      data is Map<String, dynamic> ? data as Map<String, dynamic> : {};

  /// Response body as a List (empty if the body isn't a List).
  List<dynamic> get list => data is List ? data as List : [];
}

/// Global API helper: Api.get(...), Api.post(...)
/// Change anything about networking here, once.
class Api {
  Api._();

  // ---------------- Settings (edit here) ----------------
  static const String baseUrl = ApiUrls.serverUrl;
  static const Duration timeout = Duration(seconds: 15);

  /// Set after login / PIN verify. Sent on every request.
  static String? token;

  /// Called when the server returns 401 (e.g. go back to the welcome screen).
  static VoidCallback? onUnauthorized;

  // ---------------- Logging ----------------
  static const bool logEnabled = true; // turn off to silence all API logs

  static void _log(String text) {
    if (!kDebugMode || !logEnabled) return;
    // wrapWidth splits long text into chunks so it isn't cut off
    debugPrint(text, wrapWidth: 1024);
  }

  /// Pretty prints JSON (Map or List); falls back to plain text.
  static String _pretty(dynamic data) {
    try {
      if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
    } catch (_) {}
    return data.toString();
  }

  // ---------------- Dio instance ----------------
  static final Dio _dio = _create();

  static Dio _create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        sendTimeout: timeout,
        headers: {'Content-Type': 'application/json'},
        // We handle status codes ourselves, so no exception for 4xx/5xx
        validateStatus: (_) => true,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          _log('➡️ ${options.method} ${options.uri}');
          if (options.queryParameters.isNotEmpty) {
            _log('   query: ${options.queryParameters}');
          }
          if (options.data != null) {
            _log('   body: ${_pretty(options.data)}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          _log('⬅️ ${response.statusCode} ${response.requestOptions.uri}');
          _log('   response: ${_pretty(response.data)}');
          handler.next(response);
        },
        onError: (e, handler) {
          _log('❌ ${e.type.name} ${e.requestOptions.uri}');
          _log('   message: ${e.message}');
          if (e.response != null) {
            _log('   response: ${_pretty(e.response?.data)}');
          }
          handler.next(e);
        },
      ),
    );

    return dio;
  }

  // ---------------- Public methods ----------------
  static Future<ApiResponse> get(
      String path, {
        Map<String, dynamic>? query,
      }) =>
      _send('GET', path, query: query);

  static Future<ApiResponse> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  static Future<ApiResponse> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  static Future<ApiResponse> delete(String path, {Object? body}) =>
      _send('DELETE', path, body: body);

  // ---------------- One place that does the work ----------------
  static Future<ApiResponse> _send(
      String method,
      String path, {
        Map<String, dynamic>? query,
        Object? body,
      }) async {
    try {
      final res = await _dio.request(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method),
      );

      final code = res.statusCode ?? 0;
      final ok = code >= 200 && code < 300;

      if (code == 401) onUnauthorized?.call();

      return ApiResponse(
        success: ok,
        data: res.data,
        statusCode: code,
        message: _serverMessage(res.data) ??
            (ok ? 'Success' : _messageForStatus(code)),
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: _messageForError(e),
        statusCode: e.response?.statusCode,
      );
    } catch (_) {
      return const ApiResponse(
        success: false,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  // ---------------- Messages ----------------
  /// Reads {"message": "..."} from the server if present.
  static String? _serverMessage(dynamic data) {
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return null;
  }

  static String _messageForStatus(int code) {
    if (code == 401) return 'Session expired. Please sign in again.';
    if (code == 403) return 'You do not have permission to do this.';
    if (code == 404) return 'Not found.';
    if (code >= 500) return 'Server error. Please try again later.';
    return 'Something went wrong. Please try again.';
  }

  static String _messageForError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}