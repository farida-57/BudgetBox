import 'package:equatable/equatable.dart';

/// Données saisies pour créer une dépense.
class ExpenseDraft extends Equatable {
  const ExpenseDraft({
    required this.label,
    required this.amount,
    required this.payerId,
    required this.category,
    required this.date,
    this.note,
    this.participantIds,
    this.customShares,
  });

  final String label;
  final int amount;
  final String payerId;
  final String category;
  final DateTime date;
  final String? note;

  /// Partage égal : identifiants des participants.
  final List<String>? participantIds;

  /// Partage personnalisé : montant entier par membre.
  final Map<String, int>? customShares;

  @override
  List<Object?> get props => [
    label,
    amount,
    payerId,
    category,
    date,
    note,
    participantIds,
    customShares,
  ];
}
