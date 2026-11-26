import 'package:bloc_test/bloc_test.dart';
import 'package:budgetbox/core/error/failure.dart';
import 'package:budgetbox/features/groups/domain/entities/group.dart';
import 'package:budgetbox/features/groups/domain/usecases/accept_invitation_usecase.dart';
import 'package:budgetbox/features/groups/presentation/bloc/invitation_cubit.dart';
import 'package:budgetbox/features/groups/presentation/bloc/invitation_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAcceptInvitationUseCase extends Mock implements AcceptInvitationUseCase {}

const _group = Group(id: 'g1', name: 'Coloc', currency: 'XOF', role: GroupRole.membre);

void main() {
  blocTest<InvitationCubit, InvitationState>(
    'rejoint le groupe après acceptation',
    build: () {
      final accept = MockAcceptInvitationUseCase();
      when(() => accept('tok')).thenAnswer((_) async => _group);
      return InvitationCubit(acceptInvitationUseCase: accept);
    },
    act: (cubit) => cubit.accept('tok'),
    expect: () => [const InvitationLoading(), const InvitationSuccess(_group)],
  );

  blocTest<InvitationCubit, InvitationState>(
    'émet InvitationError si le lien est invalide',
    build: () {
      final accept = MockAcceptInvitationUseCase();
      when(() => accept('bad')).thenThrow(const ServerFailure('Invitation invalide', statusCode: 404));
      return InvitationCubit(acceptInvitationUseCase: accept);
    },
    act: (cubit) => cubit.accept('bad'),
    expect: () => [const InvitationLoading(), isA<InvitationError>()],
  );
}
