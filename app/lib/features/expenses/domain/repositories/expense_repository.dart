import '../entities/expense.dart';
import '../entities/expense_draft.dart';

abstract class ExpenseRepository {
  /// Crée une dépense dans le groupe.
  Future<Expense> createExpense(String groupId, ExpenseDraft draft);
}
