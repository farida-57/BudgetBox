import 'package:equatable/equatable.dart';

import '../../domain/entities/group.dart';
import '../../domain/entities/group_member.dart';

sealed class GroupDetailState extends Equatable {
  const GroupDetailState();

  @override
  List<Object?> get props => [];
}

class GroupDetailLoading extends GroupDetailState {
  const GroupDetailLoading();
}

class GroupDetailLoaded extends GroupDetailState {
  const GroupDetailLoaded({required this.group, required this.members});

  final Group group;
  final List<GroupMember> members;

  @override
  List<Object?> get props => [group, members];
}

class GroupDetailError extends GroupDetailState {
  const GroupDetailError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
