import 'dart:developer' as dev;

import '../core/service_core.dart';
import 'auth_exceptions.dart';
import 'http_exceptions.dart';
import 'http_service_client.dart';

Future<dynamic> httpClient({
  required String method,
  required String baseUrl,
  required String endpoint,
  Map<String, String>? headers,
  Map<String, dynamic>? body,
  String errorMessage = 'Error in HTTP request',
  bool auth = false,
}) async {
  ServiceClient? client;
  final config = ServiceClientConfig(
    baseUrl: Uri.parse(baseUrl),
    defaultHeaders: headers ?? const {},
    auth: auth,
  );

  try {
    client = HttpServiceClient(
      config,
    );

    final request = ServiceRequest.http(
      method: method,
      endpoint: endpoint,
      body: body,
      errorMessage: errorMessage,
    );

    // Log request details
    dev.log('\n🔵 HTTP Request:');
    dev.log('   Method: $method');
    dev.log('   URL: $baseUrl$endpoint');
    if (body != null) {
      dev.log('   Body: $body');
    }

    final response = await client.send(request);

    // Log response details
    dev.log('🟢 HTTP Response:');
    dev.log('   Status: ${response.statusCode}');
    dev.log('   Data: ${response.data}');

    return response.data;
  } on AuthReLoginException {
    rethrow;
  } on HttpClientException {
    rethrow;
  } catch (e) {
    dev.log('🔴 HTTP Client Error: $e');
    dev.log('   URL: $method $baseUrl$endpoint');
    throw Exception('$errorMessage: [Connection error] - $e');
  } finally {
    await client?.close();
  }
}
