import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/accept_invitation_usecase.dart';
import 'invitation_state.dart';

/// Acceptation d'une invitation de groupe.
class InvitationCubit extends Cubit<InvitationState> {
  InvitationCubit({required AcceptInvitationUseCase acceptInvitationUseCase})
      : _accept = acceptInvitationUseCase,
        super(const InvitationIdle());

  final AcceptInvitationUseCase _accept;

  Future<void> accept(String token) async {
    emit(const InvitationLoading());
    try {
      final group = await _accept(token);
      emit(InvitationSuccess(group));
    } catch (e) {
      emit(InvitationError(e.toString()));
    }
  }
}
