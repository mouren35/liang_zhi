enum AppEnvironment {
  development('development', '开发环境'),
  test('test', '测试环境'),
  production('production', '');

  const AppEnvironment(this.value, this.label);

  final String value;
  final String label;

  static AppEnvironment parse(String value) {
    return AppEnvironment.values.firstWhere(
      (AppEnvironment environment) => environment.value == value,
      orElse: () => AppEnvironment.development,
    );
  }
}

class AppConfig {
  AppConfig({required this.environment, required Uri openFoodFactsBaseUri})
    : openFoodFactsBaseUri = _requireHttps(openFoodFactsBaseUri);

  factory AppConfig.fromEnvironment() {
    const String environmentValue = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );
    const String baseUrl = String.fromEnvironment(
      'OPEN_FOOD_FACTS_BASE_URL',
      defaultValue: 'https://world.openfoodfacts.org',
    );
    return AppConfig(
      environment: AppEnvironment.parse(environmentValue),
      openFoodFactsBaseUri: Uri.parse(baseUrl),
    );
  }

  static final AppConfig current = AppConfig.fromEnvironment();

  final AppEnvironment environment;
  final Uri openFoodFactsBaseUri;

  bool get showEnvironmentBadge => environment != AppEnvironment.production;

  static Uri _requireHttps(Uri uri) {
    if (uri.scheme != 'https' || uri.host.isEmpty) {
      throw ArgumentError.value(uri, 'openFoodFactsBaseUri', '必须是有效的 HTTPS 地址');
    }
    return uri;
  }
}
