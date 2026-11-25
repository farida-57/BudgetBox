import '../entities/group.dart';
import '../repositories/group_repository.dart';

class GetGroupUseCase {
  const GetGroupUseCase(this._repository);

  final GroupRepository _repository;

  Future<Group> call(String groupId) => _repository.getGroup(groupId);
}
