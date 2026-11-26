import '../../domain/entities/group_balances.dart';
import 'json_readers.dart';
import 'member_balance_model.dart';

/// Réponse de `GET /groups/:groupId/balances`.
class GroupBalancesModel extends GroupBalances {
  const GroupBalancesModel({
    required super.groupId,
    required super.currency,
    required super.balances,
  });

  factory GroupBalancesModel.fromJson(Map<String, dynamic> json) {
    final currency = json['currency'];
    return GroupBalancesModel(
      groupId: readString(json, 'groupId'),
      currency: currency is String ? currency : 'XOF',
      balances: readObjectList(
        json,
        'balances',
      ).map(MemberBalanceModel.fromJson).toList(),
    );
  }
}
