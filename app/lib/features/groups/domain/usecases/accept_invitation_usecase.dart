import '../entities/group.dart';
import '../repositories/group_repository.dart';

class AcceptInvitationUseCase {
  const AcceptInvitationUseCase(this._repository);

  final GroupRepository _repository;

  Future<Group> call(String token) => _repository.acceptInvitation(token);
}
