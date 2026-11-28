import '../entities/activity_entry.dart';
import '../repositories/settlement_repository.dart';
class GetGroupActivityUseCase {
  const GetGroupActivityUseCase(this._repository);
  final SettlementRepository _repository;
  Future<ActivityPage> call(String groupId, {int page = 1, String? memberId, String? payerId, String? category, String? type, DateTime? from, DateTime? to}) =>
      _repository.getActivity(groupId, page: page, memberId: memberId, payerId: payerId, category: category, type: type, from: from, to: to);
}
