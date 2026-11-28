import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/group_invitation_model.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';

/// Contrat des appels API des groupes.
abstract class GroupRemoteDataSource {
  Future<List<GroupModel>> getMyGroups();
  Future<GroupModel> getGroup(String groupId);
  Future<GroupModel> createGroup({required String name, String currency});
  Future<List<GroupMemberModel>> getMembers(String groupId);
  Future<GroupInvitationModel> createInvitation(String groupId);
  Future<GroupModel> acceptInvitation(String token);
  Future<GroupMemberModel> addMember(String groupId, String email);
  Future<void> removeMember(String groupId, String userId);
}

class GroupApiDataSource implements GroupRemoteDataSource {
  GroupApiDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<GroupModel>> getMyGroups() async {
    try {
      final res = await _dio.get<List<dynamic>>('/groups');
      return (res.data ?? [])
          .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<GroupModel> getGroup(String groupId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/groups/$groupId');
      return GroupModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<GroupModel> createGroup({required String name, String currency = 'XOF'}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/groups',
        data: {'name': name, 'currency': currency},
      );
      return GroupModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<List<GroupMemberModel>> getMembers(String groupId) async {
    try {
      final res = await _dio.get<List<dynamic>>('/groups/$groupId/members');
      return (res.data ?? [])
          .map((e) => GroupMemberModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<GroupInvitationModel> createInvitation(String groupId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/groups/$groupId/invitations');
      return GroupInvitationModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<GroupModel> acceptInvitation(String token) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/invitations/$token/accept');
      return GroupModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<GroupMemberModel> addMember(String groupId, String email) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/groups/$groupId/members',
        data: {'email': email},
      );
      return GroupMemberModel.fromJson(res.data!);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> removeMember(String groupId, String userId) async {
    try {
      await _dio.delete<void>('/groups/$groupId/members/$userId');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
