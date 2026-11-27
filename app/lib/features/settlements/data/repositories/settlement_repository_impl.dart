import '../../domain/entities/activity_entry.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../datasources/settlement_remote_data_source.dart';

class SettlementRepositoryImpl implements SettlementRepository {
  const SettlementRepositoryImpl(this._remote);
  final SettlementRemoteDataSource _remote;
  @override
  Future<ActivityPage> getActivity(String groupId, {int page = 1, String? memberId, String? payerId, String? category, String? type, DateTime? from, DateTime? to}) =>
      _remote.getActivity(groupId, page: page, memberId: memberId, payerId: payerId, category: category, type: type, from: from, to: to);
  @override
  Future<void> create(String groupId, {required String fromUserId, required String toUserId, required int amount}) =>
      _remote.create(groupId, fromUserId: fromUserId, toUserId: toUserId, amount: amount);
  @override
  Future<void> confirm(String groupId, String settlementId) => _remote.confirm(groupId, settlementId);
}
