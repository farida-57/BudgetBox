import 'package:bloc_test/bloc_test.dart';
import 'package:budgetbox/core/error/failure.dart';
import 'package:budgetbox/features/balances/domain/entities/group_balances.dart';
import 'package:budgetbox/features/balances/domain/entities/member_balance.dart';
import 'package:budgetbox/features/balances/domain/entities/settlement_suggestion.dart';
import 'package:budgetbox/features/balances/domain/usecases/get_group_balances_usecase.dart';
import 'package:budgetbox/features/balances/domain/usecases/get_settlement_suggestions_usecase.dart';
import 'package:budgetbox/features/balances/presentation/bloc/group_balances_cubit.dart';
import 'package:budgetbox/features/balances/presentation/bloc/group_balances_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetGroupBalancesUseCase extends Mock
    implements GetGroupBalancesUseCase {}

class MockGetSettlementSuggestionsUseCase extends Mock
    implements GetSettlementSuggestionsUseCase {}

/// Exemple du cahier : 10 000 XOF payés par Awa et partagés à trois.
const _balances = GroupBalances(
  groupId: 'g1',
  currency: 'XOF',
  balances: [
    MemberBalance(userId: 'u1', displayName: 'Awa', balance: 6666),
    MemberBalance(userId: 'u2', displayName: 'Binta', balance: -3333),
    MemberBalance(userId: 'u3', displayName: 'Chérif', balance: -3333),
  ],
);

const _suggestions = [
  SettlementSuggestion(
    fromUserId: 'u2',
    fromDisplayName: 'Binta',
    toUserId: 'u1',
    toDisplayName: 'Awa',
    amount: 3333,
  ),
  SettlementSuggestion(
    fromUserId: 'u3',
    fromDisplayName: 'Chérif',
    toUserId: 'u1',
    toDisplayName: 'Awa',
    amount: 3333,
  ),
];

const _settled = GroupBalances(
  groupId: 'g1',
  currency: 'XOF',
  balances: [
    MemberBalance(userId: 'u1', displayName: 'Awa', balance: 0),
    MemberBalance(userId: 'u2', displayName: 'Binta', balance: 0),
  ],
);

void main() {
  late MockGetGroupBalancesUseCase getBalances;
  late MockGetSettlementSuggestionsUseCase getSuggestions;

  GroupBalancesCubit buildCubit() => GroupBalancesCubit(
    groupId: 'g1',
    getGroupBalancesUseCase: getBalances,
    getSettlementSuggestionsUseCase: getSuggestions,
  );

  setUp(() {
    getBalances = MockGetGroupBalancesUseCase();
    getSuggestions = MockGetSettlementSuggestionsUseCase();
  });

  test('démarre dans l\'état de chargement', () {
    expect(buildCubit().state, const GroupBalancesLoading());
  });

  group('GroupBalancesCubit.load', () {
    blocTest<GroupBalancesCubit, GroupBalancesState>(
      'affiche les soldes et suggestions tels que renvoyés par l\'API',
      setUp: () {
        when(() => getBalances('g1')).thenAnswer((_) async => _balances);
        when(() => getSuggestions('g1')).thenAnswer((_) async => _suggestions);
      },
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const GroupBalancesLoading(),
        const GroupBalancesLoaded(
          balances: _balances,
          suggestions: _suggestions,
        ),
      ],
      verify: (_) {
        verify(() => getBalances('g1')).called(1);
        verify(() => getSuggestions('g1')).called(1);
      },
    );

    blocTest<GroupBalancesCubit, GroupBalancesState>(
      'émet un état vide quand tous les soldes valent zéro',
      setUp: () {
        when(() => getBalances('g1')).thenAnswer((_) async => _settled);
        when(
          () => getSuggestions('g1'),
        ).thenAnswer((_) async => const <SettlementSuggestion>[]);
      },
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [const GroupBalancesLoading(), const GroupBalancesEmpty()],
    );

    blocTest<GroupBalancesCubit, GroupBalancesState>(
      'émet une erreur avec le message de l\'API (non-membre, 403)',
      setUp: () {
        when(() => getBalances('g1')).thenAnswer(
          (_) async => throw const ServerFailure(
            'Vous n\'êtes pas membre de ce groupe',
            statusCode: 403,
            code: 'FORBIDDEN',
          ),
        );
        when(() => getSuggestions('g1')).thenAnswer((_) async => _suggestions);
      },
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const GroupBalancesLoading(),
        const GroupBalancesError('Vous n\'êtes pas membre de ce groupe'),
      ],
    );

    blocTest<GroupBalancesCubit, GroupBalancesState>(
      'émet une erreur si seules les suggestions échouent (réseau)',
      setUp: () {
        when(() => getBalances('g1')).thenAnswer((_) async => _balances);
        when(
          () => getSuggestions('g1'),
        ).thenAnswer((_) async => throw const NetworkFailure());
      },
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const GroupBalancesLoading(),
        GroupBalancesError(const NetworkFailure().message),
      ],
    );

    blocTest<GroupBalancesCubit, GroupBalancesState>(
      'émet un message générique pour une erreur inattendue',
      setUp: () {
        when(
          () => getBalances('g1'),
        ).thenAnswer((_) async => throw StateError('boom'));
        when(() => getSuggestions('g1')).thenAnswer((_) async => _suggestions);
      },
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const GroupBalancesLoading(),
        const GroupBalancesError('Impossible de charger les soldes.'),
      ],
    );

    blocTest<GroupBalancesCubit, GroupBalancesState>(
      'réessaie après une erreur et affiche le contenu',
      setUp: () {
        when(() => getBalances('g1')).thenAnswer((_) async => _balances);
        when(() => getSuggestions('g1')).thenAnswer((_) async => _suggestions);
      },
      build: buildCubit,
      seed: () => const GroupBalancesError('Impossible de joindre le serveur.'),
      act: (cubit) => cubit.load(),
      expect: () => [
        const GroupBalancesLoading(),
        const GroupBalancesLoaded(
          balances: _balances,
          suggestions: _suggestions,
        ),
      ],
    );
  });
}
