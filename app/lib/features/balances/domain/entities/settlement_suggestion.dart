import 'package:equatable/equatable.dart';

/// Transfert proposé par l'API pour équilibrer le groupe.
///
/// Ce n'est PAS un règlement : rien n'est payé ni enregistré tant que
/// la personne n'a pas payé hors de BudgetBox puis saisi le règlement.
class SettlementSuggestion extends Equatable {
  const SettlementSuggestion({
    required this.fromUserId,
    required this.fromDisplayName,
    required this.toUserId,
    required this.toDisplayName,
    required this.amount,
  });

  /// Personne qui doit payer.
  final String fromUserId;
  final String fromDisplayName;

  /// Personne qui doit recevoir.
  final String toUserId;
  final String toDisplayName;

  /// Montant entier en XOF, strictement positif.
  final int amount;

  @override
  List<Object?> get props => [
    fromUserId,
    fromDisplayName,
    toUserId,
    toDisplayName,
    amount,
  ];
}
