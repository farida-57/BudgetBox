import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/format/xof_format.dart';
import '../../domain/entities/group_balances.dart';
import '../../domain/entities/member_balance.dart';
import '../../domain/entities/settlement_suggestion.dart';
import '../bloc/group_balances_cubit.dart';
import '../bloc/group_balances_state.dart';

/// Section « Soldes » du détail d'un groupe.
///
/// Affiche uniquement les valeurs reçues de l'API ; aucun calcul ici.
class GroupBalancesSection extends StatelessWidget {
  const GroupBalancesSection({super.key, required this.currentUserId});

  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupBalancesCubit, GroupBalancesState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Soldes',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualiser les soldes',
                  onPressed: state is GroupBalancesLoading
                      ? null
                      : () => context.read<GroupBalancesCubit>().load(),
                ),
              ],
            ),
            switch (state) {
              GroupBalancesLoading() => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              GroupBalancesEmpty() => const _EmptyBalances(),
              GroupBalancesError(:final message) => _BalancesError(
                message: message,
              ),
              GroupBalancesLoaded(:final balances, :final suggestions) =>
                _BalancesContent(
                  balances: balances,
                  suggestions: suggestions,
                  currentUserId: currentUserId,
                ),
            },
          ],
        );
      },
    );
  }
}

class _EmptyBalances extends StatelessWidget {
  const _EmptyBalances();

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.check_circle_outline),
      title: Text('Tous les comptes sont équilibrés'),
      subtitle: Text('Aucune somme à régler pour le moment.'),
    );
  }
}

class _BalancesError extends StatelessWidget {
  const _BalancesError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.read<GroupBalancesCubit>().load(),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _BalancesContent extends StatelessWidget {
  const _BalancesContent({
    required this.balances,
    required this.suggestions,
    required this.currentUserId,
  });

  final GroupBalances balances;
  final List<SettlementSuggestion> suggestions;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final mine = balances.balanceOf(currentUserId);
    final currency = balances.currency;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mine != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Votre solde'),
              subtitle: Text(_describeOwnBalance(mine, currency)),
            ),
          ),
        ...balances.balances.map(
          (entry) => _MemberBalanceTile(
            entry: entry,
            currency: currency,
            isCurrentUser: entry.userId == currentUserId,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Règlements suggérés',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        const Text(
          'Ce sont des propositions : le paiement se fait hors de BudgetBox, '
          'puis il est enregistré comme règlement.',
          style: TextStyle(fontSize: 12),
        ),
        if (suggestions.isEmpty)
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Aucun règlement à suggérer.'),
          )
        else
          ...suggestions.map(
            (suggestion) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.swap_horiz),
              title: Text(
                '${suggestion.fromDisplayName} → ${suggestion.toDisplayName}',
              ),
              trailing: Text(formatXof(suggestion.amount, currency: currency)),
            ),
          ),
      ],
    );
  }

  static String _describeOwnBalance(MemberBalance mine, String currency) {
    final amount = formatXof(mine.balance.abs(), currency: currency);
    if (mine.isCreditor) {
      return 'Le groupe vous doit $amount';
    }
    if (mine.isDebtor) {
      return 'Vous devez $amount au groupe';
    }
    return 'Vous êtes à jour';
  }
}

class _MemberBalanceTile extends StatelessWidget {
  const _MemberBalanceTile({
    required this.entry,
    required this.currency,
    required this.isCurrentUser,
  });

  final MemberBalance entry;
  final String currency;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = isCurrentUser
        ? '${entry.displayName} (vous)'
        : entry.displayName;

    final String status;
    final Color? color;
    if (entry.isCreditor) {
      status = 'À recevoir';
      color = colors.primary;
    } else if (entry.isDebtor) {
      status = 'Doit au groupe';
      color = colors.error;
    } else {
      status = 'À jour';
      color = null;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name),
      subtitle: Text(entry.isMember ? status : '$status · ancien membre'),
      trailing: Text(
        formatXof(entry.balance.abs(), currency: currency),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
