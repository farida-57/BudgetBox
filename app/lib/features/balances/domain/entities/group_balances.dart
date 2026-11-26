import 'package:equatable/equatable.dart';

import 'member_balance.dart';

/// Soldes de tous les membres d'un groupe, reçus du serveur.
class GroupBalances extends Equatable {
  const GroupBalances({
    required this.groupId,
    required this.currency,
    required this.balances,
  });

  final String groupId;
  final String currency;

  /// Triés par nom d'affichage par l'API.
  final List<MemberBalance> balances;

  /// Solde d'une personne, ou `null` si elle n'apparaît pas dans la liste.
  MemberBalance? balanceOf(String userId) {
    for (final entry in balances) {
      if (entry.userId == userId) {
        return entry;
      }
    }
    return null;
  }

  /// Vrai quand personne ne doit rien à personne.
  bool get isAllSettled => balances.every((entry) => entry.isSettled);

  @override
  List<Object?> get props => [groupId, currency, balances];
}
