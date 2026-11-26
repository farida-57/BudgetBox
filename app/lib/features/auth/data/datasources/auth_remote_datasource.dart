import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/auth_payload_model.dart';
import '../models/user_model.dart';

/// Contrat des appels API d'authentification.
abstract class AuthRemoteDataSource {
  Future<AuthPayloadModel> register({
    required String displayName,
    required String email,
    required String password,
  });

  Future<AuthPayloadModel> login({required String email, required String password});

  Future<AuthPayloadModel> refresh(String refreshToken);

  Future<void> logout();

  Future<UserModel> me();

  Future<UserModel> updateDisplayName(String displayName);
}

class AuthApiDataSource implements AuthRemoteDataSource {
  AuthApiDataSource(this._dio);

  final Dio _dio;

  @override
  Future<AuthPayloadModel> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {'displayName': displayName, 'email': email, 'password': password},
      );
      return AuthPayloadModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<AuthPayloadModel> login({required String email, required String password}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return AuthPayloadModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<AuthPayloadModel> refresh(String refreshToken) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return AuthPayloadModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post<void>('/auth/logout');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<UserModel> me() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/me');
      return UserModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<UserModel> updateDisplayName(String displayName) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/users/me',
        data: {'displayName': displayName},
      );
      return UserModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
