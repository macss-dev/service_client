import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;

import '../core/service_core.dart';
import 'http_exceptions.dart';

class HttpServiceClient implements ServiceClient {
  HttpServiceClient(this.config, {http.Client? client})
      : _client = client ?? http.Client();

  final ServiceClientConfig config;
  final http.Client _client;

  @override
  Future<ServiceResponse> send(ServiceRequest request) async {
    if (request.protocol != ServiceProtocol.http) {
      throw Exception('Unsupported protocol for HttpServiceClient');
    }

    final url = config.baseUrl.resolve(request.endpoint);
    final effectiveHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...config.defaultHeaders,
      if (request.headers != null) ...request.headers!,
    };

    String? encodeBody(Object? body, {bool useEmptyObjectWhenNull = false}) {
      if (body == null) {
        return useEmptyObjectWhenNull ? jsonEncode(<String, dynamic>{}) : null;
      }
      if (body is String) return body;
      return jsonEncode(body);
    }

    Future<http.Response> doCall() {
      final method = request.method.toUpperCase();
      switch (method) {
        case 'GET':
          return _client
              .get(url, headers: effectiveHeaders)
              .timeout(config.timeout);
        case 'POST':
          return _client
              .post(
                url,
                headers: effectiveHeaders,
                body: encodeBody(request.body, useEmptyObjectWhenNull: true),
              )
              .timeout(config.timeout);
        case 'PATCH':
          return _client
              .patch(
                url,
                headers: effectiveHeaders,
                body: encodeBody(request.body),
              )
              .timeout(config.timeout);
        default:
          final req = http.Request(method, url)
            ..headers.addAll(effectiveHeaders);
          final encoded = encodeBody(request.body);
          if (encoded != null) {
            req.body = encoded;
          }
          return _client
              .send(req)
              .then(http.Response.fromStream)
              .timeout(config.timeout);
      }
    }

    try {
      final response = await doCall();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _toServiceResponse(response);
      }

      dev.log('HTTP Error Response:');
      dev.log('  Status: ${response.statusCode}');
      dev.log('  Body: ${response.body}');

      Map<String, dynamic>? responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>?;
      } catch (_) {
        // Response body is not valid JSON — leave as null
      }

      throw HttpClientException(
        statusCode: response.statusCode,
        message: request.errorMessage,
        response: responseData,
      );
    } catch (e) {
      if (e is HttpClientException) rethrow;

      dev.log('HTTP Client Error: $e');
      throw Exception('${request.errorMessage}: [Connection error] - $e');
    }
  }

  @override
  Future<void> close() async {
    _client.close();
  }

  ServiceResponse _toServiceResponse(http.Response response) {
    final rawBody = response.body;
    final data = rawBody.isNotEmpty ? jsonDecode(rawBody) : null;
    return ServiceResponse(
      statusCode: response.statusCode,
      headers: response.headers,
      rawBody: rawBody,
      data: data,
    );
  }
}
