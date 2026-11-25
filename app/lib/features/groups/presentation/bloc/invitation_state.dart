import 'package:equatable/equatable.dart';

import '../../domain/entities/group.dart';

sealed class InvitationState extends Equatable {
  const InvitationState();

  @override
  List<Object?> get props => [];
}

class InvitationIdle extends InvitationState {
  const InvitationIdle();
}

class InvitationLoading extends InvitationState {
  const InvitationLoading();
}

class InvitationSuccess extends InvitationState {
  const InvitationSuccess(this.group);

  final Group group;

  @override
  List<Object?> get props => [group];
}

class InvitationError extends InvitationState {
  const InvitationError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
