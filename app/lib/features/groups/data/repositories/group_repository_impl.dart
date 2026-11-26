import '../../domain/entities/group.dart';
import '../../domain/entities/group_invitation.dart';
import '../../domain/entities/group_member.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/group_remote_datasource.dart';

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl(this._dataSource);

  final GroupRemoteDataSource _dataSource;

  @override
  Future<List<Group>> getMyGroups() => _dataSource.getMyGroups();

  @override
  Future<Group> getGroup(String groupId) => _dataSource.getGroup(groupId);

  @override
  Future<Group> createGroup({required String name, String currency = 'XOF'}) =>
      _dataSource.createGroup(name: name, currency: currency);

  @override
  Future<List<GroupMember>> getMembers(String groupId) => _dataSource.getMembers(groupId);

  @override
  Future<GroupInvitation> createInvitation(String groupId) =>
      _dataSource.createInvitation(groupId);

  @override
  Future<Group> acceptInvitation(String token) => _dataSource.acceptInvitation(token);

  @override
  Future<void> removeMember(String groupId, String userId) =>
      _dataSource.removeMember(groupId, userId);
}
