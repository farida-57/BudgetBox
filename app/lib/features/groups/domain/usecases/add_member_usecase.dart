import '../entities/group_member.dart';
import '../repositories/group_repository.dart';

/// Ajoute directement un membre par son courriel (admin uniquement).
class AddMemberUseCase {
  const AddMemberUseCase(this._repository);

  final GroupRepository _repository;

  Future<GroupMember> call(String groupId, String email) =>
      _repository.addMember(groupId, email);
}
