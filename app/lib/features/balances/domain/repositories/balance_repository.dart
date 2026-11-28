import '../entities/group_balances.dart';
import '../entities/settlement_suggestion.dart';

/// Contrat de lecture des soldes. Lecture seule : l'application
/// n'envoie jamais de solde au serveur.
abstract class BalanceRepository {
  /// Soldes nets du groupe (accès réservé aux membres).
  Future<GroupBalances> getBalances(String groupId);

  /// Transferts proposés pour équilibrer le groupe.
  Future<List<SettlementSuggestion>> getSettlementSuggestions(String groupId);
}
