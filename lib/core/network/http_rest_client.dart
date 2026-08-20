import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../error/exceptions.dart';
import 'auth_token_provider.dart';
import 'network_config.dart';
import 'rest_client.dart';

class HttpRestClient implements RestClient {
  HttpRestClient({
    required http.Client client,
    required NetworkConfig config,
    required AuthTokenProvider authTokenProvider,
  }) : _client = client,
       _config = config,
       _authTokenProvider = authTokenProvider,
       _baseUri = Uri.parse(config.baseUrl);

  final http.Client _client;
  final NetworkConfig _config;
  final AuthTokenProvider _authTokenProvider;
  final Uri _baseUri;
  static const Duration _requestTimeout = Duration(seconds: 15);

  @override
  Future<RestResponse<T>> get<T>(
    String path, {
    QueryParams? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final requiresAuth = _requiresDevelopWorkflowAuth(path);
    final headers = await _buildHeaders(path, requiresAuth: requiresAuth);

    return _send<T>(
      request: () => _client.get(uri, headers: headers),
      requiresAuth: requiresAuth,
    );
  }

  @override
  Future<RestResponse<T>> post<T>(
    String path, {
    Object? body,
    QueryParams? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final requiresAuth = _requiresDevelopWorkflowAuth(path);
    final headers = await _buildHeaders(path, requiresAuth: requiresAuth);

    return _send<T>(
      request: () =>
          _client.post(uri, headers: headers, body: _encodeBody(body)),
      requiresAuth: requiresAuth,
    );
  }

  @override
  Future<RestResponse<T>> postMultipart<T>(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    required List<int> fileBytes,
    required String fileName,
    QueryParams? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final requiresAuth = _requiresDevelopWorkflowAuth(path);
    final headers = await _buildHeaders(path, requiresAuth: requiresAuth);
    headers.remove('Content-Type');

    return _send<T>(
      request: () async {
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll(headers);
        request.fields.addAll(fields);
        request.files.add(
          http.MultipartFile.fromBytes(
            fileField,
            fileBytes,
            filename: fileName,
          ),
        );

        final streamed = await _client.send(request);
        return http.Response.fromStream(streamed);
      },
      requiresAuth: requiresAuth,
    );
  }

  @override
  Future<RestResponse<T>> put<T>(
    String path, {
    Object? body,
    QueryParams? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final requiresAuth = _requiresDevelopWorkflowAuth(path);
    final headers = await _buildHeaders(path, requiresAuth: requiresAuth);

    return _send<T>(
      request: () =>
          _client.put(uri, headers: headers, body: _encodeBody(body)),
      requiresAuth: requiresAuth,
    );
  }

  @override
  Future<RestResponse<T>> patch<T>(
    String path, {
    Object? body,
    QueryParams? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final requiresAuth = _requiresDevelopWorkflowAuth(path);
    final headers = await _buildHeaders(path, requiresAuth: requiresAuth);

    return _send<T>(
      request: () =>
          _client.patch(uri, headers: headers, body: _encodeBody(body)),
      requiresAuth: requiresAuth,
    );
  }

  @override
  Future<RestResponse<T>> delete<T>(
    String path, {
    Object? body,
    QueryParams? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final requiresAuth = _requiresDevelopWorkflowAuth(path);
    final headers = await _buildHeaders(path, requiresAuth: requiresAuth);

    return _send<T>(
      request: () =>
          _client.delete(uri, headers: headers, body: _encodeBody(body)),
      requiresAuth: requiresAuth,
    );
  }

  Future<RestResponse<T>> _send<T>({
    required Future<http.Response> Function() request,
    required bool requiresAuth,
  }) async {
    try {
      final response = await request().timeout(_requestTimeout);
      final decoded = _decodeBody(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (requiresAuth && response.statusCode == 401) {
          await _authTokenProvider.clearAccessToken();
          _authTokenProvider.notifySessionExpired();
          throw const UnauthorizedSessionException(
            'Tu sesion expiro o no es valida. Inicia sesion nuevamente.',
          );
        }

        if (requiresAuth && response.statusCode == 403) {
          throw const PermissionDeniedException(
            'Permisos insuficientes para esta accion. Se requiere rol developer.',
          );
        }

        throw HttpStatusException(
          statusCode: response.statusCode,
          message: _resolveErrorMessage(decoded, response.statusCode),
          body: response.body,
        );
      }

      return RestResponse<T>(
        data: decoded as T,
        statusCode: response.statusCode,
      );
    } on SocketException catch (error) {
      throw NetworkException(
        'No se pudo conectar con el servidor: ${error.message}',
      );
    } on http.ClientException catch (error) {
      throw NetworkException(
        'Error de cliente HTTP: ${error.message}. '
        'Verifica que API_BASE_URL sea accesible por HTTPS y que CORS permita este origen.',
      );
    } on TimeoutException {
      throw NetworkException(
        'Timeout al conectar con ${_baseUri.toString()}. '
        'Revisa disponibilidad del backend y CORS.',
      );
    } on FormatException catch (error) {
      throw DataParsingException(
        'Respuesta con formato invalido: ${error.message}',
      );
    }
  }

  Uri _buildUri(String path, QueryParams? queryParameters) {
    final normalizedBasePath = _baseUri.path.endsWith('/')
        ? _baseUri.path.substring(0, _baseUri.path.length - 1)
        : _baseUri.path;
    final trimmedBasePath = normalizedBasePath.startsWith('/')
        ? normalizedBasePath.substring(1)
        : normalizedBasePath;

    final trimmedPath = path.startsWith('/') ? path.substring(1) : path;

    final combinedPath = <String>[
      if (trimmedBasePath.isNotEmpty) trimmedBasePath,
      if (trimmedPath.isNotEmpty) trimmedPath,
    ].join('/');

    return _baseUri.replace(
      path: '/$combinedPath',
      queryParameters: _normalizeQueryParameters(queryParameters),
    );
  }

  Future<Map<String, String>> _buildHeaders(
    String path, {
    required bool requiresAuth,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ..._config.defaultHeaders,
    };

    if (!requiresAuth) {
      return headers;
    }

    final token = await _authTokenProvider.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      _authTokenProvider.notifySessionRequired();
      throw const SessionNotStartedException(
        'Sesion no iniciada. Inicia sesion para continuar.',
      );
    }

    headers['Authorization'] = 'Bearer ${token.trim()}';
    return headers;
  }

  bool _requiresDevelopWorkflowAuth(String path) {
    final normalizedPath = path.trim().toLowerCase();

    return normalizedPath.startsWith('/develop-workflow') ||
        normalizedPath.startsWith('develop-workflow');
  }

  String? _encodeBody(Object? body) {
    if (body == null) {
      return null;
    }

    if (body is String) {
      return body;
    }

    return jsonEncode(body);
  }

  Object? _decodeBody(String body) {
    if (body.isEmpty) {
      return null;
    }

    return jsonDecode(body);
  }

  String _resolveErrorMessage(Object? decoded, int statusCode) {
    if (decoded is Map<String, dynamic>) {
      final value = decoded['message'] ?? decoded['error'] ?? decoded['detail'];
      final resolved = _resolveErrorValue(value);
      if (resolved != null) {
        return resolved;
      }
    }

    if (decoded is List) {
      final resolved = _resolveErrorValue(decoded);
      if (resolved != null) {
        return resolved;
      }
    }

    if (decoded is String && decoded.trim().isNotEmpty) {
      return decoded;
    }

    return 'La solicitud HTTP fallo con estado $statusCode.';
  }

  String? _resolveErrorValue(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    if (value is List) {
      final parts = value
          .map(_resolveErrorValue)
          .whereType<String>()
          .where((part) => part.trim().isNotEmpty)
          .toList(growable: false);

      if (parts.isEmpty) {
        return null;
      }

      return parts.join(' | ');
    }

    if (value is Map<String, dynamic>) {
      final nested = value['message'] ?? value['error'] ?? value['detail'];
      final resolvedNested = _resolveErrorValue(nested);
      if (resolvedNested != null) {
        return resolvedNested;
      }

      final asString = value.toString().trim();
      return asString.isEmpty ? null : asString;
    }

    final asString = value.toString().trim();
    return asString.isEmpty ? null : asString;
  }

  Map<String, String>? _normalizeQueryParameters(QueryParams? queryParameters) {
    if (queryParameters == null || queryParameters.isEmpty) {
      return null;
    }

    final map = <String, String>{};

    queryParameters.forEach((key, value) {
      if (value != null) {
        map[key] = value.toString();
      }
    });

    return map;
  }
}
