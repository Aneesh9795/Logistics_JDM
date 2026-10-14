enum Environment { dev, staging, prod }

class AppConfig {
  AppConfig._();

  // Active Environment
  static const Environment currentEnvironment = Environment.prod;

  // Base URLs for different environments
  static const String _devBaseUrl = 'https://jmdlogisticsolutions.com/api';
  static const String _stagingBaseUrl = 'https://jmdlogisticsolutions.com/api';
  static const String _prodBaseUrl = 'https://jmdlogisticsolutions.com/api';

  // Dynamic Base URL based on Environment
  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.dev:
        return _devBaseUrl;
      case Environment.staging:
        return _stagingBaseUrl;
      case Environment.prod:
        return _prodBaseUrl;
    }
  }

  // Network Timeouts
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);

  // App Metadata
  static const String appName = 'JMD Logistics';
  static const String apiVersion = 'v1';
}
