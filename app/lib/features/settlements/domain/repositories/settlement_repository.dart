import '../entities/activity_entry.dart';

abstract interface class SettlementRepository {
  Future<ActivityPage> getActivity(String groupId, {
    int page, String? memberId, String? payerId, String? category,
    String? type, DateTime? from, DateTime? to,
  });
  Future<void> create(String groupId, {required String fromUserId, required String toUserId, required int amount});
  Future<void> confirm(String groupId, String settlementId);
}
