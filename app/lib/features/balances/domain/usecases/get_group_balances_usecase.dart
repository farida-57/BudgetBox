import '../entities/group_balances.dart';
import '../repositories/balance_repository.dart';

class GetGroupBalancesUseCase {
  const GetGroupBalancesUseCase(this._repository);

  final BalanceRepository _repository;

  Future<GroupBalances> call(String groupId) =>
      _repository.getBalances(groupId);
}
