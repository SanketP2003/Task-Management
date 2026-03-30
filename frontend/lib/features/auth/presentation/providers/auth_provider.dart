import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';

const _baseUrl = 'http://localhost:8000/api/v1';
const _accessTokenKey = 'access_token';
const _refreshTokenKey = 'refresh_token';
const _emailKey = 'user_email';

final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.email,
  });

  final String accessToken;
  final String refreshToken;
  final String email;
}

class AuthNotifier extends AsyncNotifier<AuthSession?> {
  late final SharedPreferences _storage;
  late final ApiClient _apiClient;

  @override
  Future<AuthSession?> build() async {
    _storage = await ref.read(sharedPreferencesProvider.future);
    _apiClient = ApiClient(baseUrl: _baseUrl);

    final accessToken = _storage.getString(_accessTokenKey);
    final refreshToken = _storage.getString(_refreshTokenKey);
    final email = _storage.getString(_emailKey);

    if (accessToken == null || refreshToken == null || email == null) {
      return null;
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      email: email,
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _apiClient.post('/register', body: {
        'name': name,
        'email': email,
        'password': password,
      });
      return await _loginInternal(email: email, password: password);
    });
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _loginInternal(email: email, password: password),
    );
  }

  Future<AuthSession> _loginInternal({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post('/login', body: {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;

    final accessToken = response['access_token'] as String?;
    final refreshToken = response['refresh_token'] as String?;

    if (accessToken == null || refreshToken == null) {
      throw Exception('Invalid auth response from server');
    }

    await _storage.setString(_accessTokenKey, accessToken);
    await _storage.setString(_refreshTokenKey, refreshToken);
    await _storage.setString(_emailKey, email);

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      email: email,
    );
  }

  Future<void> logout() async {
    await _storage.remove(_accessTokenKey);
    await _storage.remove(_refreshTokenKey);
    await _storage.remove(_emailKey);
    state = const AsyncValue.data(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthSession?>(
  AuthNotifier.new,
);
