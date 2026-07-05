class AppConfig {
  const AppConfig._();

  static const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'test',
  );

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://110.42.244.187:3338/api',
  );

  static bool get isTest => environment == 'test';

  static bool get isProduction => environment == 'production';
}
