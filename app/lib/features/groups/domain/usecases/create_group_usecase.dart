import '../entities/group.dart';
import '../repositories/group_repository.dart';

class CreateGroupUseCase {
  const CreateGroupUseCase(this._repository);

  final GroupRepository _repository;

  Future<Group> call({required String name, String currency = 'XOF'}) =>
      _repository.createGroup(name: name, currency: currency);
}
