/// App Configuration
///
/// This file defines environment configurations for the app.
///
/// HOW TO SWITCH BETWEEN ENVIRONMENTS:
/// ====================================
///
/// To use DEV environment (to2mor-test):
///   Change: static const Environment currentEnvironment = Environment.dev;
///
/// To use PROD environment (to2mor-76e32):
///   Change: static const Environment currentEnvironment = Environment.prod;
///
/// The Firebase configuration in firebase_options.dart will automatically
/// use the correct configuration based on this setting.

enum Environment {
  dev, // Development environment (to2mor-test)
  prod, // Production environment (to2mor-76e32)
}

class AppConfig {
  /// Change this value to switch between dev and prod environments
  ///
  /// - Environment.dev: Uses Firebase project "to2mor-test"
  /// - Environment.prod: Uses Firebase project "to2mor-76e32"
  ///   static const Environment currentEnvironment = Environment.dev;
  static const Environment currentEnvironment = Environment.prod;

  static const String appName = 'Restaurant Dashboard';

  static bool get isDev => currentEnvironment == Environment.dev;
  static bool get isProd => currentEnvironment == Environment.prod;
}
