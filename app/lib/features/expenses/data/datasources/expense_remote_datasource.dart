import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/expense_draft.dart';
import '../../domain/entities/expense_validation_exception.dart';
import '../models/expense_model.dart';

abstract class ExpenseRemoteDataSource {
  Future<ExpenseModel> createExpense(String groupId, ExpenseDraft draft);
}

class ExpenseApiDataSource implements ExpenseRemoteDataSource {
  ExpenseApiDataSource(this._dio);

  final Dio _dio;

  @override
  Future<ExpenseModel> createExpense(String groupId, ExpenseDraft draft) async {
    try {
      final shares = draft.customShares;
      final res = await _dio.post<Map<String, dynamic>>(
        '/groups/$groupId/expenses',
        data: {
          'label': draft.label,
          'amount': draft.amount,
          'payerId': draft.payerId,
          'category': draft.category,
          'date': draft.date.toUtc().toIso8601String(),
          if (draft.note != null) 'note': draft.note,
          'split': shares != null
              ? {
                  'type': 'custom',
                  'shares': [
                    for (final e in shares.entries)
                      {'userId': e.key, 'amount': e.value},
                  ],
                }
              : {'type': 'equal', 'participantIds': draft.participantIds},
        },
      );
      return ExpenseModel.fromJson(res.data!);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 422 &&
          data is Map<String, dynamic> &&
          data['error'] is Map<String, dynamic>) {
        final error = data['error'] as Map<String, dynamic>;
        final fields = <String, String>{};
        final details = error['details'];
        if (details is List) {
          for (final d in details) {
            if (d is Map<String, dynamic> &&
                d['path'] is String &&
                d['message'] is String) {
              fields.putIfAbsent(
                d['path'] as String,
                () => d['message'] as String,
              );
            }
          }
        }
        throw ExpenseValidationException(
          error['message'] as String? ?? 'Données invalides',
          code: error['code'] as String?,
          fieldErrors: fields,
        );
      }
      throw mapDioException(e);
    }
  }
}
