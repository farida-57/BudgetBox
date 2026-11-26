import '../repositories/group_repository.dart';

class RemoveMemberUseCase {
  const RemoveMemberUseCase(this._repository);

  final GroupRepository _repository;

  Future<void> call(String groupId, String userId) =>
      _repository.removeMember(groupId, userId);
}
