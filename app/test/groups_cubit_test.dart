import 'package:bloc_test/bloc_test.dart';
import 'package:budgetbox/core/error/failure.dart';
import 'package:budgetbox/features/groups/domain/entities/group.dart';
import 'package:budgetbox/features/groups/domain/usecases/create_group_usecase.dart';
import 'package:budgetbox/features/groups/domain/usecases/get_my_groups_usecase.dart';
import 'package:budgetbox/features/groups/presentation/bloc/groups_cubit.dart';
import 'package:budgetbox/features/groups/presentation/bloc/groups_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetMyGroupsUseCase extends Mock implements GetMyGroupsUseCase {}

class MockCreateGroupUseCase extends Mock implements CreateGroupUseCase {}

const _group = Group(id: 'g1', name: 'Coloc', currency: 'XOF', role: GroupRole.admin);

GroupsCubit buildCubit({MockGetMyGroupsUseCase? getMyGroups, MockCreateGroupUseCase? createGroup}) {
  return GroupsCubit(
    getMyGroupsUseCase: getMyGroups ?? MockGetMyGroupsUseCase(),
    createGroupUseCase: createGroup ?? MockCreateGroupUseCase(),
  );
}

void main() {
  group('GroupsCubit.load', () {
    blocTest<GroupsCubit, GroupsState>(
      'charge la liste des groupes',
      build: () {
        final getMyGroups = MockGetMyGroupsUseCase();
        when(() => getMyGroups()).thenAnswer((_) async => [_group]);
        return buildCubit(getMyGroups: getMyGroups);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const GroupsLoading(),
        const GroupsLoaded([_group]),
      ],
    );

    blocTest<GroupsCubit, GroupsState>(
      'émet GroupsError en cas d\'échec réseau',
      build: () {
        final getMyGroups = MockGetMyGroupsUseCase();
        when(() => getMyGroups()).thenThrow(const NetworkFailure());
        return buildCubit(getMyGroups: getMyGroups);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const GroupsLoading(),
        isA<GroupsError>(),
      ],
    );
  });

  group('GroupsCubit.createGroup', () {
    test('retourne null et recharge la liste après création', () async {
      final getMyGroups = MockGetMyGroupsUseCase();
      final createGroup = MockCreateGroupUseCase();
      when(() => createGroup(name: any(named: 'name')))
          .thenAnswer((_) async => _group);
      when(() => getMyGroups()).thenAnswer((_) async => [_group]);
      final cubit = buildCubit(getMyGroups: getMyGroups, createGroup: createGroup);

      final result = await cubit.createGroup('Coloc');

      expect(result, isNull);
      expect(cubit.state, const GroupsLoaded([_group]));
    });

    test('retourne le message d\'erreur sans changer l\'état', () async {
      final createGroup = MockCreateGroupUseCase();
      when(() => createGroup(name: any(named: 'name')))
          .thenThrow(const ServerFailure('Nom invalide', statusCode: 422));
      final cubit = buildCubit(createGroup: createGroup);
      cubit.emit(const GroupsLoaded([]));

      final result = await cubit.createGroup('');

      expect(result, 'Nom invalide');
      expect(cubit.state, const GroupsLoaded([]));
    });
  });
}
