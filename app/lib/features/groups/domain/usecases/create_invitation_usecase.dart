import '../entities/group_invitation.dart';
import '../repositories/group_repository.dart';

class CreateInvitationUseCase {
  const CreateInvitationUseCase(this._repository);

  final GroupRepository _repository;

  Future<GroupInvitation> call(String groupId) => _repository.createInvitation(groupId);
}
