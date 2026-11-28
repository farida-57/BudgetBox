import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../balances/domain/usecases/get_group_balances_usecase.dart';
import '../../../balances/domain/usecases/get_settlement_suggestions_usecase.dart';
import '../../../balances/presentation/bloc/group_balances_cubit.dart';
import '../../../balances/presentation/widgets/group_balances_section.dart';
import '../../../balances/domain/entities/settlement_suggestion.dart';
import '../../../settlements/presentation/pages/settlement_history_page.dart';
import '../../domain/entities/group_invitation.dart';
import '../../domain/entities/group_member.dart';
import '../../domain/usecases/create_invitation_usecase.dart';
import '../../domain/usecases/get_group_members_usecase.dart';
import '../../domain/usecases/get_group_usecase.dart';
import '../../domain/usecases/remove_member_usecase.dart';
import '../bloc/group_detail_cubit.dart';
import '../bloc/group_detail_state.dart';
import '../bloc/groups_cubit.dart';

class GroupDetailPage extends StatelessWidget {
  const GroupDetailPage({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final currentUserId = authState is AuthAuthenticated ? authState.user.id : '';

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => GroupDetailCubit(
            groupId: groupId,
            getGroupUseCase: context.read<GetGroupUseCase>(),
            getGroupMembersUseCase: context.read<GetGroupMembersUseCase>(),
            createInvitationUseCase: context.read<CreateInvitationUseCase>(),
            removeMemberUseCase: context.read<RemoveMemberUseCase>(),
          )..load(),
        ),
        // Soldes et suggestions : chargés en parallèle du détail, calculés par l'API.
        BlocProvider(
          create: (_) => GroupBalancesCubit(
            groupId: groupId,
            getGroupBalancesUseCase: context.read<GetGroupBalancesUseCase>(),
            getSettlementSuggestionsUseCase: context.read<GetSettlementSuggestionsUseCase>(),
          )..load(),
        ),
      ],
      child: _GroupDetailView(currentUserId: currentUserId),
    );
  }
}

class _GroupDetailView extends StatelessWidget {
  const _GroupDetailView({required this.currentUserId});

  final String currentUserId;

  Future<void> _invite(BuildContext context) async {
    final cubit = context.read<GroupDetailCubit>();
    try {
      final invitation = await cubit.invite();
      if (!context.mounted) return;
      _showInvitationDialog(context, invitation);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _showInvitationDialog(BuildContext context, GroupInvitation invitation) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invitation créée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ce lien est à usage unique et expire dans quelques jours.'),
            const SizedBox(height: 12),
            SelectableText(invitation.token, style: const TextStyle(fontFamily: 'monospace')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: invitation.shareText));
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Code copié')),
              );
            },
            child: const Text('Copier'),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _removeMember(BuildContext context, GroupMember member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer le membre'),
        content: Text('Retirer ${member.displayName} du groupe ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Retirer')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      await context.read<GroupDetailCubit>().removeMember(member.userId);
      if (context.mounted) {
        context.read<GroupsCubit>().load();
        // Un membre retiré peut garder un solde (affiché comme « ancien membre »).
        context.read<GroupBalancesCubit>().load();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _openSettlements(BuildContext context, {required String groupId, required List<GroupMember> members, SettlementSuggestion? suggestion}) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SettlementHistoryPage(
      groupId: groupId, currentUserId: currentUserId, members: members, initialSuggestion: suggestion,
      onBalancesChanged: () => context.read<GroupBalancesCubit>().load(),
    )));
  }
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupDetailCubit, GroupDetailState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(switch (state) {
              GroupDetailLoaded(:final group) => group.name,
              _ => 'Groupe',
            }),
            actions: [
              if (state is GroupDetailLoaded && state.group.isAdmin)
                IconButton(
                  icon: const Icon(Icons.person_add_alt),
                  tooltip: 'Inviter un membre',
                  onPressed: () => _invite(context),
                ),
            ],
          ),
          body: switch (state) {
            GroupDetailLoading() => const Center(child: CircularProgressIndicator()),
            GroupDetailError(:final message) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.read<GroupDetailCubit>().load(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            GroupDetailLoaded(:final group, :final members) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${group.currency} · ${group.memberCount} membre(s)'),
                    subtitle: Text(group.isAdmin ? 'Vous êtes administrateur' : 'Vous êtes membre'),
                  ),
                  const Divider(height: 32),
                  GroupBalancesSection(currentUserId: currentUserId, onSuggestionSelected: (suggestion) =>
                    _openSettlements(context, groupId: group.id, members: members, suggestion: suggestion)),
                  OutlinedButton.icon(
                    onPressed: () => _openSettlements(context, groupId: group.id, members: members),
                    icon: const Icon(Icons.history), label: const Text('Historique et règlements'),
                  ),
                  const Divider(height: 32),
                  Text('Membres', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ...members.map(
                    (m) => ListTile(
                      leading: CircleAvatar(child: Text(m.displayName.isEmpty ? '?' : m.displayName[0].toUpperCase())),
                      title: Text(m.displayName),
                      subtitle: Text(m.email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (m.role.name == 'admin')
                            const Chip(label: Text('Admin'), visualDensity: VisualDensity.compact),
                          if (group.isAdmin && m.userId != currentUserId)
                            IconButton(
                              icon: const Icon(Icons.person_remove_outlined),
                              tooltip: 'Retirer',
                              onPressed: () => _removeMember(context, m),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (group.isAdmin) ...[
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => _invite(context),
                      icon: const Icon(Icons.link),
                      label: const Text('Générer un code d\'invitation'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Le code est à usage unique. Partagez-le avec la personne qui doit rejoindre le groupe.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
          },
        );
      },
    );
  }
}

