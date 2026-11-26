import '../entities/group_member.dart';
import '../repositories/group_repository.dart';

class GetGroupMembersUseCase {
  const GetGroupMembersUseCase(this._repository);

  final GroupRepository _repository;

  Future<List<GroupMember>> call(String groupId) => _repository.getMembers(groupId);
}
