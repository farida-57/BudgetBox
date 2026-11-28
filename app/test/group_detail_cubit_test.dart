import 'package:bloc_test/bloc_test.dart';
import 'package:budgetbox/core/error/failure.dart';
import 'package:budgetbox/features/groups/domain/entities/group.dart';
import 'package:budgetbox/features/groups/domain/entities/group_invitation.dart';
import 'package:budgetbox/features/groups/domain/entities/group_member.dart';
import 'package:budgetbox/features/groups/domain/usecases/add_member_usecase.dart';
import 'package:budgetbox/features/groups/domain/usecases/create_invitation_usecase.dart';
import 'package:budgetbox/features/groups/domain/usecases/get_group_members_usecase.dart';
import 'package:budgetbox/features/groups/domain/usecases/get_group_usecase.dart';
import 'package:budgetbox/features/groups/domain/usecases/remove_member_usecase.dart';
import 'package:budgetbox/features/groups/presentation/bloc/group_detail_cubit.dart';
import 'package:budgetbox/features/groups/presentation/bloc/group_detail_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetGroupUseCase extends Mock implements GetGroupUseCase {}

class MockGetGroupMembersUseCase extends Mock implements GetGroupMembersUseCase {}

class MockCreateInvitationUseCase extends Mock implements CreateInvitationUseCase {}

class MockAddMemberUseCase extends Mock implements AddMemberUseCase {}

class MockRemoveMemberUseCase extends Mock implements RemoveMemberUseCase {}

const _group = Group(id: 'g1', name: 'Coloc', currency: 'XOF', role: GroupRole.admin);
const _member = GroupMember(
  userId: 'u2',
  displayName: 'Binta',
  email: 'binta@test.com',
  role: GroupRole.membre,
);

GroupDetailCubit buildCubit({
  MockGetGroupUseCase? getGroup,
  MockGetGroupMembersUseCase? getMembers,
  MockCreateInvitationUseCase? createInvitation,
  MockAddMemberUseCase? addMember,
  MockRemoveMemberUseCase? removeMember,
}) {
  return GroupDetailCubit(
    groupId: 'g1',
    getGroupUseCase: getGroup ?? MockGetGroupUseCase(),
    getGroupMembersUseCase: getMembers ?? MockGetGroupMembersUseCase(),
    createInvitationUseCase: createInvitation ?? MockCreateInvitationUseCase(),
    addMemberUseCase: addMember ?? MockAddMemberUseCase(),
    removeMemberUseCase: removeMember ?? MockRemoveMemberUseCase(),
  );
}

void main() {
  group('GroupDetailCubit.load', () {
    blocTest<GroupDetailCubit, GroupDetailState>(
      'charge groupe et membres',
      build: () {
        final getGroup = MockGetGroupUseCase();
        final getMembers = MockGetGroupMembersUseCase();
        when(() => getGroup('g1')).thenAnswer((_) async => _group);
        when(() => getMembers('g1')).thenAnswer((_) async => [_member]);
        return buildCubit(getGroup: getGroup, getMembers: getMembers);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const GroupDetailLoading(),
        const GroupDetailLoaded(group: _group, members: [_member]),
      ],
    );

    blocTest<GroupDetailCubit, GroupDetailState>(
      'émet GroupDetailError si non-membre (403)',
      build: () {
        final getGroup = MockGetGroupUseCase();
        when(() => getGroup('g1'))
            .thenThrow(const ServerFailure('Accès refusé', statusCode: 403));
        return buildCubit(getGroup: getGroup);
      },
      act: (cubit) => cubit.load(),
      expect: () => [const GroupDetailLoading(), isA<GroupDetailError>()],
    );
  });

  group('GroupDetailCubit.invite', () {
    test('retourne l\'invitation générée', () async {
      final invitation =
          GroupInvitation(token: 'tok123', expiresAt: DateTime(2030));
      final createInvitation = MockCreateInvitationUseCase();
      when(() => createInvitation('g1')).thenAnswer((_) async => invitation);
      final cubit = buildCubit(createInvitation: createInvitation);

      final result = await cubit.invite();
      expect(result.token, 'tok123');
    });
  });

  group('GroupDetailCubit.addMember', () {
    test('ajoute le membre par courriel et recharge le détail', () async {
      final getGroup = MockGetGroupUseCase();
      final getMembers = MockGetGroupMembersUseCase();
      final addMember = MockAddMemberUseCase();
      when(() => addMember('g1', 'binta@test.com')).thenAnswer((_) async => _member);
      when(() => getGroup('g1')).thenAnswer((_) async => _group);
      when(() => getMembers('g1')).thenAnswer((_) async => [_member]);
      final cubit = buildCubit(
        getGroup: getGroup,
        getMembers: getMembers,
        addMember: addMember,
      );

      final result = await cubit.addMember('binta@test.com');

      expect(result.userId, 'u2');
      verify(() => addMember('g1', 'binta@test.com')).called(1);
      expect(cubit.state, const GroupDetailLoaded(group: _group, members: [_member]));
    });
  });

  group('GroupDetailCubit.removeMember', () {
    test('retire le membre et recharge le détail', () async {
      final getGroup = MockGetGroupUseCase();
      final getMembers = MockGetGroupMembersUseCase();
      final removeMember = MockRemoveMemberUseCase();
      when(() => removeMember('g1', 'u2')).thenAnswer((_) async {});
      when(() => getGroup('g1')).thenAnswer((_) async => _group);
      when(() => getMembers('g1')).thenAnswer((_) async => const []);
      final cubit = buildCubit(
        getGroup: getGroup,
        getMembers: getMembers,
        removeMember: removeMember,
      );

      await cubit.removeMember('u2');

      verify(() => removeMember('g1', 'u2')).called(1);
      expect(cubit.state, const GroupDetailLoaded(group: _group, members: []));
    });
  });
}
