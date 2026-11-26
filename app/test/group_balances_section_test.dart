import 'package:bloc_test/bloc_test.dart';
import 'package:budgetbox/core/format/xof_format.dart';
import 'package:budgetbox/features/balances/domain/entities/group_balances.dart';
import 'package:budgetbox/features/balances/domain/entities/member_balance.dart';
import 'package:budgetbox/features/balances/domain/entities/settlement_suggestion.dart';
import 'package:budgetbox/features/balances/presentation/bloc/group_balances_cubit.dart';
import 'package:budgetbox/features/balances/presentation/bloc/group_balances_state.dart';
import 'package:budgetbox/features/balances/presentation/widgets/group_balances_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupBalancesCubit extends MockCubit<GroupBalancesState>
    implements GroupBalancesCubit {}

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

void main() {
  late MockGroupBalancesCubit cubit;

  setUp(() {
    cubit = MockGroupBalancesCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
  });

  Future<void> pumpSection(WidgetTester tester, GroupBalancesState state) {
    whenListen(
      cubit,
      const Stream<GroupBalancesState>.empty(),
      initialState: state,
    );
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<GroupBalancesCubit>.value(
            value: cubit,
            child: ListView(
              children: const [GroupBalancesSection(currentUserId: 'u2')],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'affiche le solde de l\'utilisateur, les soldes et les suggestions',
    (tester) async {
      await pumpSection(
        tester,
        const GroupBalancesLoaded(
          balances: _balances,
          suggestions: _suggestions,
        ),
      );

      expect(find.text('Votre solde'), findsOneWidget);
      expect(
        find.text('Vous devez ${formatXof(3333)} au groupe'),
        findsOneWidget,
      );
      expect(find.text('Binta (vous)'), findsOneWidget);
      expect(find.text('Awa'), findsOneWidget);
      expect(find.text(formatXof(6666)), findsOneWidget);
      expect(find.text('À recevoir'), findsOneWidget);
      expect(find.text('Doit au groupe'), findsNWidgets(2));
      expect(find.text('Binta → Awa'), findsOneWidget);
      expect(find.text('Chérif → Awa'), findsOneWidget);
    },
  );

  testWidgets('affiche l\'état vide quand tout est équilibré', (tester) async {
    await pumpSection(tester, const GroupBalancesEmpty());

    expect(find.text('Tous les comptes sont équilibrés'), findsOneWidget);
  });

  testWidgets('affiche l\'erreur et relance le chargement avec Réessayer', (
    tester,
  ) async {
    await pumpSection(
      tester,
      const GroupBalancesError('Impossible de joindre le serveur.'),
    );

    expect(find.text('Impossible de joindre le serveur.'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    verify(() => cubit.load()).called(1);
  });

  testWidgets('affiche un indicateur pendant le chargement', (tester) async {
    await pumpSection(tester, const GroupBalancesLoading());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final refresh = tester.widget<IconButton>(find.byType(IconButton));
    expect(refresh.onPressed, isNull);
  });
}
