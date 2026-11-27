import 'package:bloc_test/bloc_test.dart';
import 'package:budgetbox/features/expenses/domain/entities/expense.dart';
import 'package:budgetbox/features/expenses/domain/entities/expense_draft.dart';
import 'package:budgetbox/features/expenses/domain/entities/expense_validation_exception.dart';
import 'package:budgetbox/features/expenses/domain/usecases/create_expense_usecase.dart';
import 'package:budgetbox/features/expenses/presentation/bloc/expense_form_cubit.dart';
import 'package:budgetbox/features/expenses/presentation/bloc/expense_form_state.dart';
import 'package:budgetbox/features/groups/domain/entities/group.dart';
import 'package:budgetbox/features/groups/domain/entities/group_member.dart';
import 'package:budgetbox/features/groups/domain/usecases/get_group_members_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetMembers extends Mock implements GetGroupMembersUseCase {}

class MockCreateExpense extends Mock implements CreateExpenseUseCase {}

const members = [
  GroupMember(
    userId: 'u1',
    displayName: 'Awa',
    email: 'awa@test.com',
    role: GroupRole.admin,
  ),
  GroupMember(
    userId: 'u2',
    displayName: 'Binta',
    email: 'binta@test.com',
    role: GroupRole.membre,
  ),
];

final expense = Expense(
  id: 'e1',
  label: 'Courses',
  amount: 5000,
  payerId: 'u1',
  category: 'alimentation',
  date: DateTime(2026, 11, 27),
);

ExpenseFormState readyState({
  bool custom = false,
  Map<String, int> amounts = const {},
}) => ExpenseFormState(
  status: ExpenseFormStatus.ready,
  members: members,
  payerId: 'u1',
  isCustom: custom,
  selectedIds: const {'u1', 'u2'},
  customAmounts: amounts,
);

void main() {
  late MockGetMembers getMembers;
  late MockCreateExpense createExpense;

  setUpAll(() {
    registerFallbackValue(
      ExpenseDraft(
        label: 'x',
        amount: 1,
        payerId: 'u1',
        category: 'autre',
        date: DateTime(2026),
      ),
    );
  });

  setUp(() {
    getMembers = MockGetMembers();
    createExpense = MockCreateExpense();
  });

  ExpenseFormCubit build() => ExpenseFormCubit(
    groupId: 'g1',
    getMembersUseCase: getMembers,
    createExpenseUseCase: createExpense,
  );

  group('load', () {
    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'charge les membres : payeur = premier membre, tous cochés',
      setUp: () =>
          when(() => getMembers('g1')).thenAnswer((_) async => members),
      build: build,
      act: (c) => c.load(),
      expect: () => [
        isA<ExpenseFormState>().having(
          (s) => s.status,
          'status',
          ExpenseFormStatus.loading,
        ),
        isA<ExpenseFormState>()
            .having((s) => s.status, 'status', ExpenseFormStatus.ready)
            .having((s) => s.members, 'members', members)
            .having((s) => s.payerId, 'payerId', 'u1')
            .having((s) => s.selectedIds, 'selectedIds', {'u1', 'u2'}),
      ],
    );

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'émet loadError si le chargement échoue',
      setUp: () => when(() => getMembers('g1')).thenThrow(Exception('boom')),
      build: build,
      act: (c) => c.load(),
      expect: () => [
        isA<ExpenseFormState>().having(
          (s) => s.status,
          'status',
          ExpenseFormStatus.loading,
        ),
        isA<ExpenseFormState>()
            .having((s) => s.status, 'status', ExpenseFormStatus.loadError)
            .having((s) => s.message, 'message', 'Exception: boom'),
      ],
    );
  });

  group('submit — contrôles locaux', () {
    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'refuse un libellé vide et un montant invalide, sans appeler le serveur',
      build: build,
      seed: readyState,
      act: (c) => c.submit(
        label: '  ',
        amountText: 'abc',
        category: 'alimentation',
        date: DateTime(2026, 11, 27),
      ),
      expect: () => [
        isA<ExpenseFormState>()
            .having((s) => s.fieldErrors.containsKey('label'), 'label', true)
            .having((s) => s.fieldErrors.containsKey('amount'), 'amount', true),
      ],
      verify: (_) => verifyNever(() => createExpense(any(), any())),
    );

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'partage personnalisé : refuse une somme de parts différente du total',
      build: build,
      seed: () => readyState(custom: true, amounts: {'u1': 3000, 'u2': 1000}),
      act: (c) => c.submit(
        label: 'Courses',
        amountText: '5000',
        category: 'alimentation',
        date: DateTime(2026, 11, 27),
      ),
      expect: () => [
        isA<ExpenseFormState>().having(
          (s) => s.fieldErrors['split'],
          'split',
          contains('4000'),
        ),
      ],
      verify: (_) => verifyNever(() => createExpense(any(), any())),
    );

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'partage égal : refuse si aucun participant n\'est coché',
      build: build,
      seed: () => readyState().copyWith(selectedIds: <String>{}),
      act: (c) => c.submit(
        label: 'Courses',
        amountText: '5000',
        category: 'alimentation',
        date: DateTime(2026, 11, 27),
      ),
      expect: () => [
        isA<ExpenseFormState>().having(
          (s) => s.fieldErrors.containsKey('split'),
          'split',
          true,
        ),
      ],
      verify: (_) => verifyNever(() => createExpense(any(), any())),
    );
  });

  group('submit — serveur', () {
    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'succès : submitting puis success, un seul appel',
      setUp: () => when(
        () => createExpense(any(), any()),
      ).thenAnswer((_) async => expense),
      build: build,
      seed: readyState,
      act: (c) => c.submit(
        label: 'Courses',
        amountText: '5000',
        category: 'alimentation',
        date: DateTime(2026, 11, 27),
      ),
      expect: () => [
        isA<ExpenseFormState>().having(
          (s) => s.status,
          'status',
          ExpenseFormStatus.submitting,
        ),
        isA<ExpenseFormState>().having(
          (s) => s.status,
          'status',
          ExpenseFormStatus.success,
        ),
      ],
      verify: (_) => verify(() => createExpense('g1', any())).called(1),
    );

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'erreur 422 : revient à ready avec l\'erreur rattachée au champ split',
      setUp: () => when(() => createExpense(any(), any())).thenThrow(
        const ExpenseValidationException(
          'Somme des parts incorrecte',
          code: 'SHARES_MISMATCH',
        ),
      ),
      build: build,
      seed: readyState,
      act: (c) => c.submit(
        label: 'Courses',
        amountText: '5000',
        category: 'alimentation',
        date: DateTime(2026, 11, 27),
      ),
      expect: () => [
        isA<ExpenseFormState>().having(
          (s) => s.status,
          'status',
          ExpenseFormStatus.submitting,
        ),
        isA<ExpenseFormState>()
            .having((s) => s.status, 'status', ExpenseFormStatus.ready)
            .having(
              (s) => s.fieldErrors['split'],
              'split',
              'Somme des parts incorrecte',
            )
            .having((s) => s.message, 'message', 'Somme des parts incorrecte'),
      ],
    );
  });
}
