import 'package:dio/dio.dart';
import '../models/activity_entry_model.dart';
import '../../domain/entities/activity_entry.dart';

abstract interface class SettlementRemoteDataSource {
  Future<ActivityPage> getActivity(String groupId, {
    int page, String? memberId, String? payerId, String? category,
    String? type, DateTime? from, DateTime? to,
  });
  Future<void> create(String groupId, {required String fromUserId, required String toUserId, required int amount});
  Future<void> confirm(String groupId, String settlementId);
}

class SettlementApiDataSource implements SettlementRemoteDataSource {
  SettlementApiDataSource(this._dio);
  final Dio _dio;

  @override
  Future<ActivityPage> getActivity(String groupId, {
    int page = 1, String? memberId, String? payerId, String? category,
    String? type, DateTime? from, DateTime? to,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/${Uri.encodeComponent(groupId)}/activity',
      queryParameters: {
        'page': page, 'limit': 20,
        if (memberId != null) 'memberId': memberId,
        if (payerId != null) 'payerId': payerId,
        if (category != null) 'category': category,
        if (type != null) 'type': type,
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      },
    );
    final data = response.data;
    if (data == null || data['items'] is! List) throw const FormatException('Réponse d’historique invalide.');
    final items = (data['items'] as List)
        .map((item) => ActivityEntryModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    return ActivityPage(
      items: items, page: data['page'] as int? ?? page,
      pages: data['pages'] as int? ?? 0, total: data['total'] as int? ?? items.length,
    );
  }

  @override
  Future<void> create(String groupId, {required String fromUserId, required String toUserId, required int amount}) async {
    await _dio.post('/groups/${Uri.encodeComponent(groupId)}/settlements', data: {
      'fromUserId': fromUserId, 'toUserId': toUserId, 'amount': amount,
    });
  }

  @override
  Future<void> confirm(String groupId, String settlementId) async {
    await _dio.post('/groups/${Uri.encodeComponent(groupId)}/settlements/${Uri.encodeComponent(settlementId)}/confirm');
  }
}

