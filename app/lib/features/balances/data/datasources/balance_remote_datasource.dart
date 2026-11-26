import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../models/group_balances_model.dart';
import '../models/settlement_suggestion_model.dart';

/// Contrat des appels API des soldes (lecture seule).
abstract class BalanceRemoteDataSource {
  Future<GroupBalancesModel> getBalances(String groupId);
  Future<List<SettlementSuggestionModel>> getSettlementSuggestions(
    String groupId,
  );
}

class BalanceApiDataSource implements BalanceRemoteDataSource {
  BalanceApiDataSource(this._dio);

  final Dio _dio;

  static const _invalidResponse = UnknownFailure(
    'Réponse inattendue du serveur pour les soldes.',
  );

  @override
  Future<GroupBalancesModel> getBalances(String groupId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/groups/${Uri.encodeComponent(groupId)}/balances',
      );
      return GroupBalancesModel.fromJson(_body(res));
    } on DioException catch (e) {
      throw mapDioException(e);
    } on FormatException {
      throw _invalidResponse;
    }
  }

  @override
  Future<List<SettlementSuggestionModel>> getSettlementSuggestions(
    String groupId,
  ) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/groups/${Uri.encodeComponent(groupId)}/settlement-suggestions',
      );
      return SettlementSuggestionModel.listFromResponse(_body(res));
    } on DioException catch (e) {
      throw mapDioException(e);
    } on FormatException {
      throw _invalidResponse;
    }
  }

  Map<String, dynamic> _body(Response<Map<String, dynamic>> res) {
    final data = res.data;
    if (data == null) {
      throw const FormatException('Réponse vide');
    }
    return data;
  }
}
