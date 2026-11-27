import '../repositories/settlement_repository.dart';
class CreateSettlementUseCase {
  const CreateSettlementUseCase(this._repository);
  final SettlementRepository _repository;
  Future<void> call(String groupId, {required String fromUserId, required String toUserId, required int amount}) =>
      _repository.create(groupId, fromUserId: fromUserId, toUserId: toUserId, amount: amount);
}
