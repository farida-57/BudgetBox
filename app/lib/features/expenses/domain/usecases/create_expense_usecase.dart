import '../entities/expense.dart';
import '../entities/expense_draft.dart';
import '../repositories/expense_repository.dart';

class CreateExpenseUseCase {
  const CreateExpenseUseCase(this._repository);

  final ExpenseRepository _repository;

  Future<Expense> call(String groupId, ExpenseDraft draft) =>
      _repository.createExpense(groupId, draft);
}
