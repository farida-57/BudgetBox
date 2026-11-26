import 'package:equatable/equatable.dart';

import '../../domain/entities/group.dart';

sealed class GroupsState extends Equatable {
  const GroupsState();

  @override
  List<Object?> get props => [];
}

class GroupsLoading extends GroupsState {
  const GroupsLoading();
}

class GroupsLoaded extends GroupsState {
  const GroupsLoaded(this.groups);

  final List<Group> groups;

  @override
  List<Object?> get props => [groups];
}

class GroupsError extends GroupsState {
  const GroupsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
