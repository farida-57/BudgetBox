import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/activity_item.dart';

class SettlementRepository {
  SettlementRepository({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? const String.fromEnvironment('BUDGETBOX_API_URL', defaultValue: 'http://10.0.2.2:3000/api/v1');
  final http.Client _client;
  final String _baseUrl;
  // Temporary header until Membre 2 integrates JWT auth. Never use in production.
  String? userId;
  Map<String, String> get _headers => {'Content-Type': 'application/json', if (userId != null) 'X-User-Id': userId!};

  Future<List<ActivityItem>> getActivity(String groupId, {int page = 1, String? type, String? memberId, String? category, String? payerId, DateTime? from, DateTime? to}) async {
    final query = <String, String>{'page': '$page', 'limit': '20', if (type != null) 'type': type, if (memberId != null) 'memberId': memberId, if (category != null) 'category': category, if (payerId != null) 'payerId': payerId, if (from != null) 'from': from.toUtc().toIso8601String(), if (to != null) 'to': to.toUtc().toIso8601String()};
    final uri = Uri.parse('$_baseUrl/groups/$groupId/activity').replace(queryParameters: query);
    final response = await _client.get(uri, headers: _headers);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) throw Exception(decoded['error']?['message'] ?? 'Impossible de charger l’historique.');
    final payload = decoded['data'] as Map<String, dynamic>;
    return (payload['items'] as List).map((row) => ActivityItem.fromJson(Map<String, dynamic>.from(row as Map))).toList();
  }

  Future<void> createSettlement(String groupId, {required String fromUserId, required String toUserId, required int amount}) async {
    final uri = Uri.parse('$_baseUrl/groups/$groupId/settlements');
    final response = await _client.post(uri, headers: _headers, body: jsonEncode({'fromUserId': fromUserId, 'toUserId': toUserId, 'amount': amount}));
    if (response.statusCode >= 400) { final data = jsonDecode(response.body); throw Exception(data['error']?['message'] ?? 'Impossible d’enregistrer le règlement.'); }
  }

  Future<void> confirmSettlement(String groupId, String settlementId) async {
    final uri = Uri.parse('$_baseUrl/groups/$groupId/settlements/$settlementId/confirm');
    final response = await _client.post(uri, headers: _headers);
    if (response.statusCode >= 400) { final data = jsonDecode(response.body); throw Exception(data['error']?['message'] ?? 'Impossible de confirmer le règlement.'); }
  }
}
