import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/device_profile.dart';
import '../../../core/config/wardrive_config.dart';
import '../domain/csv_exporter.dart';
import '../domain/models.dart';

class LoginResponse {
  const LoginResponse({
    required this.access,
    required this.refresh,
    required this.username,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
      username: json['username'] as String,
    );
  }

  final String access;
  final String refresh;
  final String username;
}

class RegisterResponse {
  const RegisterResponse({required this.user, required this.tokens});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final tokens = json['tokens'] as Map<String, dynamic>;
    return RegisterResponse(
      user: RegisterUser(
        id: user['id'] as int,
        username: user['username'] as String,
        email: user['email'] as String,
      ),
      tokens: AuthTokens(
        access: tokens['access'] as String,
        refresh: tokens['refresh'] as String,
      ),
    );
  }

  final RegisterUser user;
  final AuthTokens tokens;
}

class RegisterUser {
  const RegisterUser({
    required this.id,
    required this.username,
    required this.email,
  });

  final int id;
  final String username;
  final String email;
}

class AuthTokens {
  const AuthTokens({required this.access, required this.refresh});

  final String access;
  final String refresh;
}

class ResetResponse {
  const ResetResponse({required this.detail});

  factory ResetResponse.fromJson(Map<String, dynamic> json) {
    return ResetResponse(detail: json['detail'] as String);
  }

  final String detail;
}

class WardriveApiRepository {
  WardriveApiRepository(this._config, {http.Client? client})
    : _client = client ?? http.Client();

  final WardriveConfig _config;
  final http.Client _client;

  String _requireEnv(String value, String name) {
    if (value.isEmpty) {
      throw ApiConfigError('API URL not configured: $name');
    }
    return value;
  }

  String parseApiError(Map<String, dynamic> data) {
    final detail = data['detail'];
    if (detail is String) return detail;

    final nonFieldErrors = data['non_field_errors'];
    if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
      return nonFieldErrors.first.toString();
    }

    return data.values
        .expand((value) => value is List ? value : [value])
        .map((value) => value.toString())
        .join(' ');
  }

  Future<LoginResponse> login(String username, String password) async {
    final url = _requireEnv(_config.loginUrl, 'WARDRIVE_LOGIN_URL');
    final response = await _client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(parseApiError(data));
    }
    return LoginResponse.fromJson(data);
  }

  Future<RegisterResponse> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    final url = _requireEnv(_config.registerUrl, 'WARDRIVE_REGISTER_URL');
    final response = await _client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'password_confirm': passwordConfirm,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(parseApiError(data));
    }
    return RegisterResponse.fromJson(data);
  }

  Future<ResetResponse> requestPasswordReset(String email) async {
    final url = _requireEnv(_config.resetUrl, 'WARDRIVE_RESET_URL');
    final response = await _client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(parseApiError(data));
    }
    return ResetResponse.fromJson(data);
  }

  Future<String> refreshToken(String refresh) async {
    final url = _requireEnv(
      _config.tokenRefreshUrl,
      'WARDRIVE_TOKEN_REFRESH_URL',
    );
    final response = await _client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Token refresh failed');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['access'] as String;
  }

  Future<http.Response> uploadCsv({
    required ScanType type,
    required String csvContent,
    required String filename,
    required String accessToken,
    required DeviceProfile profile,
  }) async {
    final url = _requireEnv(_config.uploadUrl, 'WARDRIVE_UPLOAD_URL');
    final deviceSource = profile.hasMarauderDeviceSource
        ? profile.deviceSource!
        : (type == ScanType.lte
              ? profile.deviceSourceLte
              : profile.deviceSourceWifiBle);

    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..fields['device_source'] = deviceSource
      ..files.add(
        http.MultipartFile.fromString('files', csvContent, filename: filename),
      );

    final streamed = await _client.send(request);
    return http.Response.fromStream(streamed);
  }

  String buildCsvForUpload(ScanType type, List<Object> rows) {
    return buildCsv(type, rows);
  }

  String filenameForUpload(ScanType type) => makeCsvFilename(type);

  Future<http.Response> uploadRawCsv({
    required String csvContent,
    required String filename,
    required String accessToken,
    required String deviceSource,
  }) async {
    final url = _requireEnv(_config.uploadUrl, 'WARDRIVE_UPLOAD_URL');

    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..fields['device_source'] = deviceSource
      ..files.add(
        http.MultipartFile.fromString('files', csvContent, filename: filename),
      );

    final streamed = await _client.send(request);
    return http.Response.fromStream(streamed);
  }
}
