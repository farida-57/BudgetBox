import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_draft.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_datasource.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl(this._dataSource);

  final ExpenseRemoteDataSource _dataSource;

  @override
  Future<Expense> createExpense(String groupId, ExpenseDraft draft) =>
      _dataSource.createExpense(groupId, draft);
}
