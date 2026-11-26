import '../../domain/entities/member_balance.dart';
import 'json_readers.dart';

class MemberBalanceModel extends MemberBalance {
  const MemberBalanceModel({
    required super.userId,
    required super.displayName,
    required super.balance,
    super.isMember,
  });

  factory MemberBalanceModel.fromJson(Map<String, dynamic> json) {
    final displayName = json['displayName'];
    final isMember = json['isMember'];
    return MemberBalanceModel(
      userId: readString(json, 'userId'),
      displayName: displayName is String ? displayName : 'Utilisateur',
      balance: readInt(json, 'balance'),
      isMember: isMember is bool ? isMember : true,
    );
  }
}
