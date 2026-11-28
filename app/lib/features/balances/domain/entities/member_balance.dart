import 'package:equatable/equatable.dart';

/// Solde net d'une personne dans un groupe, tel que calculé par l'API.
///
/// - [balance] > 0 : le groupe doit ce montant à la personne ;
/// - [balance] < 0 : la personne doit ce montant au groupe ;
/// - [balance] == 0 : la personne est à jour.
///
/// L'application affiche ce solde mais ne le recalcule jamais.
class MemberBalance extends Equatable {
  const MemberBalance({
    required this.userId,
    required this.displayName,
    required this.balance,
    this.isMember = true,
  });

  final String userId;
  final String displayName;

  /// Montant entier en XOF (aucune décimale).
  final int balance;

  /// `false` pour une personne retirée du groupe qui garde un solde non nul.
  final bool isMember;

  bool get isCreditor => balance > 0;
  bool get isDebtor => balance < 0;
  bool get isSettled => balance == 0;

  @override
  List<Object?> get props => [userId, displayName, balance, isMember];
}
