import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/bloc/auth_cubit.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/profile_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/groups/domain/usecases/accept_invitation_usecase.dart';
import '../features/groups/presentation/bloc/invitation_cubit.dart';
import '../features/groups/presentation/pages/accept_invitation_page.dart';
import '../features/groups/presentation/pages/create_group_page.dart';
import '../features/groups/presentation/pages/group_detail_page.dart';
import '../features/groups/presentation/pages/groups_page.dart';

/// Adapte le stream de l'AuthCubit à un Listenable pour go_router.
class _AuthRouterListenable extends ChangeNotifier {
  _AuthRouterListenable(AuthCubit cubit) {
    _subscription = cubit.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter buildRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthRouterListenable(authCubit),
    redirect: (context, state) {
      final authState = authCubit.state;
      final location = state.matchedLocation;
      final isAuthPage = location == '/login' || location == '/register';
      final isSplash = location == '/splash';

      if (authState is AuthUnknown) {
        return isSplash ? null : '/splash';
      }
      if (authState is AuthUnauthenticated) {
        return isAuthPage || isSplash ? null : '/login';
      }
      if (authState is AuthAuthenticated) {
        if (isAuthPage || isSplash) return '/groups';
        return null;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const _SplashPage()),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
      GoRoute(
        path: '/invite/:token',
        builder: (context, state) => BlocProvider(
          create: (_) => InvitationCubit(
            acceptInvitationUseCase: context.read<AcceptInvitationUseCase>(),
          ),
          child: AcceptInvitationPage(token: state.pathParameters['token']!),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/groups',
                builder: (_, _) => const GroupsPage(),
                routes: [
                  GoRoute(path: 'new', builder: (_, _) => const CreateGroupPage()),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => GroupDetailPage(groupId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profil', builder: (_, _) => const ProfilePage()),
            ],
          ),
        ],
      ),
    ],
  );
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'Groupes'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
