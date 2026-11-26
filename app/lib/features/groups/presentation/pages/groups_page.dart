import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/group.dart';
import '../bloc/groups_cubit.dart';
import '../bloc/groups_state.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  @override
  void initState() {
    super.initState();
    context.read<GroupsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Groupes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/groups/new'),
        icon: const Icon(Icons.add),
        label: const Text('Créer un groupe'),
      ),
      body: BlocBuilder<GroupsCubit, GroupsState>(
        builder: (context, state) {
          return switch (state) {
            GroupsLoading() => const Center(child: CircularProgressIndicator()),
            GroupsError(:final message) => _ErrorView(
                message: message,
                onRetry: () => context.read<GroupsCubit>().load(),
              ),
            GroupsLoaded(:final groups) when groups.isEmpty => _EmptyView(
                onCreate: () => context.push('/groups/new'),
                onJoin: () => _showJoinDialog(context),
              ),
            GroupsLoaded(:final groups) => RefreshIndicator(
                onRefresh: () => context.read<GroupsCubit>().load(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: groups.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _GroupTile(group: groups[i]),
                ),
              ),
          };
        },
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejoindre un groupe'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Code d\'invitation',
            hintText: 'Collez le jeton reçu',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              final token = controller.text.trim();
              Navigator.pop(ctx);
              if (token.isNotEmpty) context.push('/invite/$token');
            },
            child: const Text('Rejoindre'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(group.name.isEmpty ? '?' : group.name[0].toUpperCase())),
        title: Text(group.name),
        subtitle: Text('${group.currency} · ${group.memberCount} membre(s)'),
        trailing: group.isAdmin
            ? const Chip(label: Text('Admin'), visualDensity: VisualDensity.compact)
            : null,
        onTap: () => context.push('/groups/${group.id}'),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onCreate, required this.onJoin});

  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_outlined, size: 64),
            const SizedBox(height: 16),
            Text('Aucun groupe pour le moment', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Créez un groupe ou rejoignez-en un avec un code d\'invitation.'),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Créer un groupe')),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onJoin, child: const Text('Rejoindre avec un code')),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
