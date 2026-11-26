import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/create_group_usecase.dart';
import '../../domain/usecases/get_my_groups_usecase.dart';
import 'groups_state.dart';

/// Liste des groupes de l'utilisateur et création de groupe.
class GroupsCubit extends Cubit<GroupsState> {
  GroupsCubit({
    required GetMyGroupsUseCase getMyGroupsUseCase,
    required CreateGroupUseCase createGroupUseCase,
  })  : _getMyGroups = getMyGroupsUseCase,
        _createGroup = createGroupUseCase,
        super(const GroupsLoading());

  final GetMyGroupsUseCase _getMyGroups;
  final CreateGroupUseCase _createGroup;

  Future<void> load() async {
    emit(const GroupsLoading());
    try {
      final groups = await _getMyGroups();
      emit(GroupsLoaded(groups));
    } catch (e) {
      emit(GroupsError(e.toString()));
    }
  }

  /// Retourne null si le groupe est créé (la liste est rechargée),
  /// sinon un message d'erreur pour l'UI.
  Future<String?> createGroup(String name) async {
    try {
      await _createGroup(name: name.trim());
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
