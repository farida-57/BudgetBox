import 'package:dio/dio.dart';

import '../error/failure.dart';
import '../storage/token_storage.dart';

/// Client HTTP unique de l'application.
///
/// - ajoute le jeton d'accès aux requêtes ;
/// - sur 401, tente une fois un refresh rotatif puis rejoue la requête ;
/// - convertit les DioException en [Failure] métier.
class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    Dio? dio,
    String? baseUrl,
  })  : _tokenStorage = tokenStorage,
        dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ??
                    const String.fromEnvironment(
                      'BUDGETBOX_API_URL',
                      defaultValue: 'http://10.0.2.2:3000/api/v1',
                    ),
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                contentType: 'application/json',
              ),
            ) {
    // Client secondaire sans intercepteur pour le refresh (évite la boucle).
    final client = this.dio;
    _refreshDio = Dio(client.options);
    client.interceptors.add(_AuthInterceptor(client, _refreshDio, _tokenStorage));
  }

  final TokenStorage _tokenStorage;
  final Dio dio;
  late final Dio _refreshDio;
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio, this._refreshDio, this._tokenStorage);

  final Dio _dio;
  final Dio _refreshDio;
  final TokenStorage _tokenStorage;

  static const _publicPaths = ['/auth/login', '/auth/register', '/auth/refresh'];

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final is401 = err.response?.statusCode == 401;
    final path = err.requestOptions.path;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (!is401 || alreadyRetried || _publicPaths.any((p) => path.contains(p))) {
      return handler.next(err);
    }

    final refreshed = await _tryRefresh();
    if (!refreshed) {
      await _tokenStorage.clear();
      return handler.next(err);
    }

    try {
      final opts = err.requestOptions;
      opts.extra['retried'] = true;
      final token = await _tokenStorage.readAccessToken();
      opts.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.fetch<dynamic>(opts);
      return handler.resolve(response);
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    }
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final res = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final tokens = res.data?['tokens'] as Map<String, dynamic>?;
      final access = tokens?['accessToken'] as String?;
      final refresh = tokens?['refreshToken'] as String?;
      if (access == null || refresh == null) return false;
      await _tokenStorage.saveTokens(accessToken: access, refreshToken: refresh);
      return true;
    } on DioException {
      return false;
    }
  }
}

/// Convertit une DioException en [Failure] exploitable par l'UI.
Failure mapDioException(DioException err) {
  switch (err.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const NetworkFailure();
    default:
      break;
  }

  final response = err.response;
  if (response == null) {
    return const NetworkFailure();
  }

  final data = response.data;
  String? code;
  String? message;
  final details = <String>[];
  if (data is Map<String, dynamic>) {
    final error = data['error'];
    if (error is Map<String, dynamic>) {
      code = error['code'] as String?;
      message = error['message'] as String?;
      final rawDetails = error['details'];
      if (rawDetails is List) {
        for (final d in rawDetails) {
          if (d is Map<String, dynamic> && d['message'] is String) {
            details.add(d['message'] as String);
          }
        }
      }
    }
  }

  final fullMessage = details.isEmpty
      ? (message ?? 'Erreur serveur (${response.statusCode})')
      : '${message ?? 'Erreur serveur (${response.statusCode})'} : ${details.join(' ; ')}';

  return ServerFailure(
    fullMessage,
    statusCode: response.statusCode,
    code: code,
  );
}
