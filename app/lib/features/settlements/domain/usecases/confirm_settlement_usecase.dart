import '../repositories/settlement_repository.dart';
class ConfirmSettlementUseCase {
  const ConfirmSettlementUseCase(this._repository);
  final SettlementRepository _repository;
  Future<void> call(String groupId, String settlementId) => _repository.confirm(groupId, settlementId);
}
