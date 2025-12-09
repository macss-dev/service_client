import 'dart:io';

import '../core/service_core.dart';
import 'auth_exceptions.dart';
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
    final response = await client.send(request);
    return response.data;
  } on AuthReLoginException {
    rethrow;
  } catch (e) {
    stderr.writeln('HTTP Client Error: $e'
        'url: $method $baseUrl$endpoint');
    throw Exception('$errorMessage: [Connection error] - $e');
  } finally {
    await client?.close();
  }
}
