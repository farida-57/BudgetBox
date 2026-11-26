import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/usecases/get_group_balances_usecase.dart';
import '../../domain/usecases/get_settlement_suggestions_usecase.dart';
import 'group_balances_state.dart';

/// Charge les soldes et les suggestions d'un groupe depuis l'API.
///
/// Le Cubit ne calcule aucun solde : il transmet ce que le serveur renvoie
/// et choisit seulement l'état à afficher (chargement, vide, erreur, contenu).
class GroupBalancesCubit extends Cubit<GroupBalancesState> {
  GroupBalancesCubit({
    required String groupId,
    required GetGroupBalancesUseCase getGroupBalancesUseCase,
    required GetSettlementSuggestionsUseCase getSettlementSuggestionsUseCase,
  }) : _groupId = groupId,
       _getBalances = getGroupBalancesUseCase,
       _getSuggestions = getSettlementSuggestionsUseCase,
       super(const GroupBalancesLoading());

  final String _groupId;
  final GetGroupBalancesUseCase _getBalances;
  final GetSettlementSuggestionsUseCase _getSuggestions;

  /// Premier chargement et bouton « Réessayer ».
  Future<void> load() async {
    emit(const GroupBalancesLoading());
    try {
      // Les deux lectures partent en parallèle. `Future.wait` attend les deux
      // et, en cas d'échec, relance la première erreur telle quelle (une Failure).
      final balancesRequest = _getBalances(_groupId);
      final suggestionsRequest = _getSuggestions(_groupId);
      await Future.wait([balancesRequest, suggestionsRequest]);
      final balances = await balancesRequest;
      final suggestions = await suggestionsRequest;

      if (balances.isAllSettled && suggestions.isEmpty) {
        _emitIfOpen(const GroupBalancesEmpty());
      } else {
        _emitIfOpen(
          GroupBalancesLoaded(balances: balances, suggestions: suggestions),
        );
      }
    } on Failure catch (failure) {
      _emitIfOpen(GroupBalancesError(failure.message));
    } catch (_) {
      _emitIfOpen(
        const GroupBalancesError('Impossible de charger les soldes.'),
      );
    }
  }

  /// La page peut être quittée pendant le chargement : on n'émet plus après `close()`.
  void _emitIfOpen(GroupBalancesState state) {
    if (!isClosed) {
      emit(state);
    }
  }
}
