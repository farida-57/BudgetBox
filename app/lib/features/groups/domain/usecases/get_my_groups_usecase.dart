import '../entities/group.dart';
import '../repositories/group_repository.dart';

class GetMyGroupsUseCase {
  const GetMyGroupsUseCase(this._repository);

  final GroupRepository _repository;

  Future<List<Group>> call() => _repository.getMyGroups();
}
