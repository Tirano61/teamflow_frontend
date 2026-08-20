class NetworkConfig {
  const NetworkConfig({required this.baseUrl, this.defaultHeaders = const {}});

  final String baseUrl;
  final Map<String, String> defaultHeaders;

  factory NetworkConfig.fromEnvironment() {
    final headers = <String, String>{'Accept': 'application/json'};
    final apiBaseUrl = const String.fromEnvironment('API_BASE_URL');
    final useLocalApi = const bool.fromEnvironment(
      'USE_LOCAL_API',
      defaultValue: false,
    );
    const productionApi = 'https://marketing.balanzashook.com.ar/api/v1';
    const localTunnelApi = 'https://l002n256-3000.brs.devtunnels.ms/api/v1';

    final normalizedApiBaseUrl = apiBaseUrl.trim();
    if (normalizedApiBaseUrl.isNotEmpty) {
      return NetworkConfig(
        baseUrl: normalizedApiBaseUrl,
        defaultHeaders: headers,
      );
    }

    final defaultApi = useLocalApi ? localTunnelApi : productionApi;

    return NetworkConfig(baseUrl: defaultApi, defaultHeaders: headers);
  }
}

// Produccion por defecto: https://marketing.balanzashook.com.ar/api/v1
// Local opcional: flutter run --dart-define=USE_LOCAL_API=true
// Override explicito: --dart-define=API_BASE_URL=https://tu-api.com/api/v1
