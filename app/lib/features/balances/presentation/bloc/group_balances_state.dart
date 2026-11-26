import 'package:equatable/equatable.dart';

import '../../domain/entities/group_balances.dart';
import '../../domain/entities/settlement_suggestion.dart';

sealed class GroupBalancesState extends Equatable {
  const GroupBalancesState();

  @override
  List<Object?> get props => [];
}

class GroupBalancesLoading extends GroupBalancesState {
  const GroupBalancesLoading();
}

/// Tous les soldes reçus valent 0 : rien à régler.
class GroupBalancesEmpty extends GroupBalancesState {
  const GroupBalancesEmpty();
}

class GroupBalancesLoaded extends GroupBalancesState {
  const GroupBalancesLoaded({
    required this.balances,
    required this.suggestions,
  });

  /// Soldes tels que renvoyés par l'API, sans modification.
  final GroupBalances balances;
  final List<SettlementSuggestion> suggestions;

  @override
  List<Object?> get props => [balances, suggestions];
}

class GroupBalancesError extends GroupBalancesState {
  const GroupBalancesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
