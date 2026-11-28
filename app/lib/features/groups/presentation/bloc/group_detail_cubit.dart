import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/group_invitation.dart';
import '../../domain/entities/group_member.dart';
import '../../domain/usecases/add_member_usecase.dart';
import '../../domain/usecases/create_invitation_usecase.dart';
import '../../domain/usecases/get_group_members_usecase.dart';
import '../../domain/usecases/get_group_usecase.dart';
import '../../domain/usecases/remove_member_usecase.dart';
import 'group_detail_state.dart';

/// Détail d'un groupe : informations, membres, invitations, retraits.
///
/// Les actions [invite] et [removeMember] propagent les [Failure]
/// pour que la page affiche un SnackBar ; seul [load] émet un état d'erreur.
class GroupDetailCubit extends Cubit<GroupDetailState> {
  GroupDetailCubit({
    required String groupId,
    required GetGroupUseCase getGroupUseCase,
    required GetGroupMembersUseCase getGroupMembersUseCase,
    required CreateInvitationUseCase createInvitationUseCase,
    required AddMemberUseCase addMemberUseCase,
    required RemoveMemberUseCase removeMemberUseCase,
  })  : _groupId = groupId,
        _getGroup = getGroupUseCase,
        _getMembers = getGroupMembersUseCase,
        _createInvitation = createInvitationUseCase,
        _addMember = addMemberUseCase,
        _removeMember = removeMemberUseCase,
        super(const GroupDetailLoading());

  final String _groupId;
  final GetGroupUseCase _getGroup;
  final GetGroupMembersUseCase _getMembers;
  final CreateInvitationUseCase _createInvitation;
  final AddMemberUseCase _addMember;
  final RemoveMemberUseCase _removeMember;

  Future<void> load() async {
    emit(const GroupDetailLoading());
    try {
      final (group, members) = await (_getGroup(_groupId), _getMembers(_groupId)).wait;
      emit(GroupDetailLoaded(group: group, members: members));
    } catch (e) {
      emit(GroupDetailError(e.toString()));
    }
  }

  /// Génère une nouvelle invitation à usage unique.
  Future<GroupInvitation> invite() => _createInvitation(_groupId);

  /// Ajoute directement un membre par son courriel, puis recharge le détail.
  Future<GroupMember> addMember(String email) async {
    final member = await _addMember(_groupId, email);
    await load();
    return member;
  }

  /// Retire un membre puis recharge le détail.
  Future<void> removeMember(String userId) async {
    await _removeMember(_groupId, userId);
    await load();
  }
}
