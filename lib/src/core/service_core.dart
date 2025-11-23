enum ServiceProtocol { http, graphql, grpc, websocket, mq }

class ServiceClientConfig {
  ServiceClientConfig({
    required Uri baseUrl,
    this.defaultHeaders = const {},
    this.timeout = const Duration(seconds: 30),
    this.auth = false,
  }) : baseUrl = _normalizeBaseUrl(baseUrl);

  final Uri baseUrl;
  final Map<String, String> defaultHeaders;
  final Duration timeout;
  final bool auth;

  static Uri _normalizeBaseUrl(Uri uri) {
    // Ensure that the path ends with / for correct endpoint resolution
    final path = uri.path;
    if (path.isEmpty || path.endsWith('/')) {
      return uri;
    }
    return uri.replace(path: '$path/');
  }
}

class ServiceRequest {
  const ServiceRequest({
    required this.protocol,
    required this.method,
    required this.endpoint,
    this.headers,
    this.body,
    this.errorMessage = 'Error in service request',
  });

  factory ServiceRequest.http({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Object? body,
    String errorMessage = 'Error in HTTP request',
  }) {
    return ServiceRequest(
      protocol: ServiceProtocol.http,
      method: method,
      endpoint: endpoint,
      headers: headers,
      body: body,
      errorMessage: errorMessage,
    );
  }

  final ServiceProtocol protocol;
  final String method;
  final String endpoint;
  final Map<String, String>? headers;
  final Object? body;
  final String errorMessage;
}

class ServiceResponse {
  const ServiceResponse({
    required this.statusCode,
    required this.headers,
    required this.rawBody,
    this.data,
  });

  final int statusCode;
  final Map<String, String> headers;
  final String rawBody;
  final dynamic data;
}

abstract interface class ServiceClient {
  Future<ServiceResponse> send(ServiceRequest request);

  Future<void> close();
}
