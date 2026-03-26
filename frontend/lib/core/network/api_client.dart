import 'dart:convert';

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
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParameters: queryParameters);
    final response = await _client.get(uri, headers: _headers(headers));
    return _parseResponse(response);
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    final response = await _client.post(
      uri,
      headers: _headers(headers),
      body: body == null ? null : jsonEncode(body),
    );
    return _parseResponse(response);
  }

  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    final response = await _client.put(
      uri,
      headers: _headers(headers),
      body: body == null ? null : jsonEncode(body),
    );
    return _parseResponse(response);
  }

  Future<dynamic> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    final response = await _client.delete(uri, headers: _headers(headers));
    return _parseResponse(response);
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
      queryParameters: queryParameters?.isEmpty == true ? null : queryParameters,
    );
  }

  Map<String, String> _headers(Map<String, String>? headers) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };
  }

  dynamic _parseResponse(http.Response response) {
    final hasBody = response.body.isNotEmpty;
    final parsedBody = hasBody ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return parsedBody;
    }

    final message = parsedBody is Map<String, dynamic>
        ? (parsedBody['detail']?.toString() ?? 'Request failed')
        : 'Request failed';

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      body: parsedBody,
    );
  }
}