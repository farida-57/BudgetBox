import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/invitation_cubit.dart';
import '../bloc/invitation_state.dart';

/// Écran d'acceptation d'une invitation (route /invite/:token).
class AcceptInvitationPage extends StatefulWidget {
  const AcceptInvitationPage({super.key, required this.token});

  final String token;

  @override
  State<AcceptInvitationPage> createState() => _AcceptInvitationPageState();
}

class _AcceptInvitationPageState extends State<AcceptInvitationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvitationCubit>().accept(widget.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invitation')),
      body: BlocBuilder<InvitationCubit, InvitationState>(
        builder: (context, state) {
          return switch (state) {
            InvitationIdle() || InvitationLoading() => const Center(child: CircularProgressIndicator()),
            InvitationSuccess(:final group) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                      const SizedBox(height: 16),
                      Text('Vous avez rejoint « ${group.name} »',
                          style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => context.go('/groups'),
                        child: const Text('Voir mes groupes'),
                      ),
                    ],
                  ),
                ),
              ),
            InvitationError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height:12),
                      Text(message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.read<InvitationCubit>().accept(widget.token),
                        child: const Text('Réessayer'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.go('/groups'),
                        child: const Text('Retour aux groupes'),
                      ),
                    ],
                  ),
                ),
              ),
          };
        },
      ),
    );
  }
}
