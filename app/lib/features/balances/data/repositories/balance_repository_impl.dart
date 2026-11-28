import '../../domain/entities/group_balances.dart';
import '../../domain/entities/settlement_suggestion.dart';
import '../../domain/repositories/balance_repository.dart';
import '../datasources/balance_remote_datasource.dart';

class BalanceRepositoryImpl implements BalanceRepository {
  BalanceRepositoryImpl(this._dataSource);

  final BalanceRemoteDataSource _dataSource;

  @override
  Future<GroupBalances> getBalances(String groupId) =>
      _dataSource.getBalances(groupId);

  @override
  Future<List<SettlementSuggestion>> getSettlementSuggestions(String groupId) =>
      _dataSource.getSettlementSuggestions(groupId);
}
