import 'dart:developer' as dev;

import 'package:http/http.dart' as http;

import '../core/service_core.dart';
import 'http_exceptions.dart';
import 'http_service_client.dart';

/// Convenience function for one-shot HTTP requests.
///
/// Creates a temporary [HttpServiceClient], sends the request,
/// and closes the client. Returns the parsed response data.
///
/// The optional [client] parameter exists for testing only.
@Deprecated('Use HttpServiceClient directly. Will be removed in v0.3.0.')
Future<dynamic> httpClient({
  required String method,
  required String baseUrl,
  required String endpoint,
  Map<String, String>? headers,
  Map<String, dynamic>? body,
  String errorMessage = 'Error in HTTP request',
  http.Client? httpClient,
}) async {
  ServiceClient? serviceClient;
  final config = ServiceClientConfig(
    baseUrl: Uri.parse(baseUrl),
    defaultHeaders: headers ?? const {},
  );

  try {
    serviceClient = HttpServiceClient(config, client: httpClient);

    final request = ServiceRequest.http(
      method: method,
      endpoint: endpoint,
      body: body,
      errorMessage: errorMessage,
    );

    dev.log('\n🔵 HTTP Request:');
    dev.log('   Method: $method');
    dev.log('   URL: $baseUrl$endpoint');
    if (body != null) {
      dev.log('   Body: $body');
    }

    final response = await serviceClient.send(request);

    dev.log('🟢 HTTP Response:');
    dev.log('   Status: ${response.statusCode}');
    dev.log('   Data: ${response.data}');

    return response.data;
  } on HttpClientException {
    rethrow;
  } catch (e) {
    dev.log('🔴 HTTP Client Error: $e');
    dev.log('   URL: $method $baseUrl$endpoint');
    throw Exception('$errorMessage: [Connection error] - $e');
  } finally {
    await serviceClient?.close();
  }
}
