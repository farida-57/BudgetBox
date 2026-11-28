import '../entities/settlement_suggestion.dart';
import '../repositories/balance_repository.dart';

class GetSettlementSuggestionsUseCase {
  const GetSettlementSuggestionsUseCase(this._repository);

  final BalanceRepository _repository;

  Future<List<SettlementSuggestion>> call(String groupId) =>
      _repository.getSettlementSuggestions(groupId);
}
