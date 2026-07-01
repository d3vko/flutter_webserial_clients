class WardriveConfig {
  const WardriveConfig({
    required this.loginUrl,
    required this.registerUrl,
    required this.resetUrl,
    required this.uploadUrl,
    required this.tokenRefreshUrl,
  });

  final String loginUrl;
  final String registerUrl;
  final String resetUrl;
  final String uploadUrl;
  final String tokenRefreshUrl;

  bool get isAuthConfigured =>
      loginUrl.isNotEmpty &&
      registerUrl.isNotEmpty &&
      resetUrl.isNotEmpty &&
      tokenRefreshUrl.isNotEmpty;

  bool get isUploadConfigured => uploadUrl.isNotEmpty;

  static WardriveConfig fromEnvironment() {
    return const WardriveConfig(
      loginUrl: String.fromEnvironment('WARDRIVE_LOGIN_URL'),
      registerUrl: String.fromEnvironment('WARDRIVE_REGISTER_URL'),
      resetUrl: String.fromEnvironment('WARDRIVE_RESET_URL'),
      uploadUrl: String.fromEnvironment('WARDRIVE_UPLOAD_URL'),
      tokenRefreshUrl: String.fromEnvironment('WARDRIVE_TOKEN_REFRESH_URL'),
    );
  }
}

class ApiConfigError implements Exception {
  ApiConfigError(this.message);

  final String message;

  @override
  String toString() => message;
}
