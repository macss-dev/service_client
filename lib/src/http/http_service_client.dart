import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/service_core.dart';
import 'auth_exceptions.dart';
import 'http_exceptions.dart';
import 'token.dart';
import 'token_vault.dart';

class HttpServiceClient implements ServiceClient {
  HttpServiceClient(this.config) : _client = http.Client();

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

    if (config.auth && Token.accessToken != null) {
      effectiveHeaders['Authorization'] = 'Bearer ${Token.accessToken}';
    }

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
      var response = await doCall();

      final bool isLogin = request.endpoint.contains('/auth/login');
      if (isLogin && config.auth && response.statusCode == 200) {
        final m = jsonDecode(response.body) as Map<String, dynamic>;
        final access = m['access_token'] as String?;
        final expiresIn = (m['expires_in'] as num?)?.toInt();
        final rt = m['refresh_token'] as String?;

        if (access != null) {
          Token.accessToken = access;
        }
        if (expiresIn != null) {
          Token.accessExp = DateTime.now().add(Duration(seconds: expiresIn));
        }
        if (rt != null) {
          await TokenVault.saveRefresh(_kCurrentUser, rt);
        }

        return _toServiceResponse(response, decodedBody: m);
      }

      if (response.statusCode == 401 && config.auth) {
        final refreshEndpoint = _inferRefreshEndpoint(request.endpoint);
        final refreshed = await _tryRefresh(
          baseUrl: config.baseUrl,
          refreshEndpoint: refreshEndpoint,
          client: _client,
          timeout: config.timeout,
        );
        if (refreshed) {
          if (Token.accessToken != null) {
            effectiveHeaders['Authorization'] = 'Bearer ${Token.accessToken}';
          }
          response = await doCall();
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _toServiceResponse(response);
      }

      if (response.statusCode == 401 && config.auth) {
        throw AuthReLoginException();
      }

      // Log error response body for debugging
      stderr.writeln('HTTP Error Response:');
      stderr.writeln('  Status: ${response.statusCode}');
      stderr.writeln('  Body: ${response.body}');
      
      // Parsear response body si es JSON
      Map<String, dynamic>? responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>?;
      } catch (_) {
        // Si no se puede parsear, dejar como null
      }
      
      throw HttpClientException(
        statusCode: response.statusCode,
        message: request.errorMessage,
        response: responseData,
      );
    } catch (e) {
      if (e is AuthReLoginException) rethrow;
      if (e is HttpClientException) rethrow;

      stderr.writeln('HTTP Client Error: $e');
      throw Exception('${request.errorMessage}: [Connection error] - $e');
    }
  }

  @override
  Future<void> close() async {
    _client.close();
  }

  ServiceResponse _toServiceResponse(
    http.Response response, {
    dynamic decodedBody,
  }) {
    final rawBody = response.body;
    final data =
        decodedBody ?? (rawBody.isNotEmpty ? jsonDecode(rawBody) : null);
    return ServiceResponse(
      statusCode: response.statusCode,
      headers: response.headers,
      rawBody: rawBody,
      data: data,
    );
  }

  String _inferRefreshEndpoint(String endpoint) {
    var refreshEndpoint = 'auth/refresh';
    if (endpoint.contains('/')) {
      final parts = endpoint.split('/');
      if (parts.isNotEmpty && parts[0].isNotEmpty) {
        refreshEndpoint = '${parts[0]}/auth/refresh';
      }
    }
    return refreshEndpoint;
  }
}

const String _kCurrentUser = 'current_user';

Future<bool> _tryRefresh({
  required Uri baseUrl,
  required String refreshEndpoint,
  required http.Client client,
  required Duration timeout,
}) async {
  final rt = await TokenVault.readRefresh(_kCurrentUser);
  if (rt == null) return false;

  final url = baseUrl.resolve(refreshEndpoint);
  try {
    final r = await client
        .post(
          url,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': rt}),
        )
        .timeout(timeout);

    if (r.statusCode == 200) {
      final m = jsonDecode(r.body) as Map<String, dynamic>;
      final access = m['access_token'] as String?;
      final expiresIn = (m['expires_in'] as num?)?.toInt();
      final newRt = m['refresh_token'] as String?;

      if (access == null) return false;

      Token.accessToken = access;
      if (expiresIn != null) {
        Token.accessExp = DateTime.now().add(Duration(seconds: expiresIn));
      }
      if (newRt != null) {
        await TokenVault.saveRefresh(_kCurrentUser, newRt);
      }

      return true;
    }

    return false;
  } catch (e) {
    stderr.writeln('Token refresh error: $e');
    return false;
  }
}
