import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.message,
    this.body,
  });

  final int statusCode;
  final String message;
  final dynamic body;

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
    String? Function()? tokenProvider,
  })  : _client = client ?? http.Client(),
        _tokenProvider = tokenProvider;

  final String baseUrl;
  final http.Client _client;
  final String? Function()? _tokenProvider;
  static const Duration _timeout = Duration(seconds: 15);

  Future<dynamic> _safeApiCall(Future<http.Response> Function() call) async {
    try {
      final response = await call().timeout(_timeout);
      return _parseResponse(response);
    } on SocketException {
      throw NetworkException(
          'Network error: Please check your internet connection.');
    } on TimeoutException {
      throw NetworkException('Request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      throw NetworkException('Something went wrong. Please try again later.');
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParameters: queryParameters);
    return _safeApiCall(() => _client.get(uri, headers: _headers(headers)));
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    return _safeApiCall(() => _client.post(
          uri,
          headers: _headers(headers),
          body: body == null ? null : jsonEncode(body),
        ));
  }

  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    return _safeApiCall(() => _client.put(
          uri,
          headers: _headers(headers),
          body: body == null ? null : jsonEncode(body),
        ));
  }

  Future<dynamic> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    return _safeApiCall(() => _client.delete(uri, headers: _headers(headers)));
  }

  Uri _buildUri(String path, {Map<String, String>? queryParameters}) {
    final base = Uri.parse(baseUrl);
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final mergedPath = [
      ...base.pathSegments.where((segment) => segment.isNotEmpty),
      ...normalizedPath.split('/').where((segment) => segment.isNotEmpty),
    ];

    return base.replace(
      pathSegments: mergedPath,
      queryParameters:
          queryParameters?.isEmpty == true ? null : queryParameters,
    );
  }

  Map<String, String> _headers(Map<String, String>? headers) {
    final token = _tokenProvider?.call();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?headers,
    };
  }

  dynamic _parseResponse(http.Response response) {
    final hasBody = response.body.isNotEmpty;
    final parsedBody = hasBody ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return parsedBody;
    }

    String message = 'Something went wrong';

    if (parsedBody is Map<String, dynamic> && parsedBody['detail'] != null) {
      message = parsedBody['detail'].toString();
    } else {
      switch (response.statusCode) {
        case 400:
          message = 'Bad request. Please check your data.';
          break;
        case 401:
          message = 'Unauthorized access.';
          break;
        case 403:
          message = 'Forbidden access.';
          break;
        case 404:
          message = 'Resource not found.';
          break;
        case 500:
          message = 'Internal server error. Please try again later.';
          break;
        case 502:
          message = 'Bad gateway.';
          break;
        case 503:
          message = 'Service unavailable.';
          break;
        default:
          message =
              'Failed to load data (Status code: ${response.statusCode}).';
      }
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      body: parsedBody,
    );
  }
}
