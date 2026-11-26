import '../../domain/entities/settlement_suggestion.dart';
import 'json_readers.dart';

/// Élément de `suggestions` dans `GET /groups/:groupId/settlement-suggestions`.
class SettlementSuggestionModel extends SettlementSuggestion {
  const SettlementSuggestionModel({
    required super.fromUserId,
    required super.fromDisplayName,
    required super.toUserId,
    required super.toDisplayName,
    required super.amount,
  });

  factory SettlementSuggestionModel.fromJson(Map<String, dynamic> json) {
    return SettlementSuggestionModel(
      fromUserId: readString(json, 'fromUserId'),
      fromDisplayName: readString(json, 'fromDisplayName'),
      toUserId: readString(json, 'toUserId'),
      toDisplayName: readString(json, 'toDisplayName'),
      amount: readInt(json, 'amount'),
    );
  }

  /// Lit la réponse complète `{ groupId, currency, suggestions: [...] }`.
  static List<SettlementSuggestionModel> listFromResponse(
    Map<String, dynamic> json,
  ) {
    return readObjectList(
      json,
      'suggestions',
    ).map(SettlementSuggestionModel.fromJson).toList();
  }
}
