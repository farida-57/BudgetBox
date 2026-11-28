import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/auth/domain/usecases/login_usecase.dart';
import '../features/auth/domain/usecases/logout_usecase.dart';
import '../features/auth/domain/usecases/register_usecase.dart';
import '../features/auth/domain/usecases/restore_session_usecase.dart';
import '../features/auth/domain/usecases/update_profile_usecase.dart';
import '../features/auth/presentation/bloc/auth_cubit.dart';
import '../features/balances/domain/usecases/get_group_balances_usecase.dart';
import '../features/balances/domain/usecases/get_settlement_suggestions_usecase.dart';
import '../features/groups/domain/usecases/accept_invitation_usecase.dart';
import '../features/groups/domain/usecases/add_member_usecase.dart';
import '../features/groups/domain/usecases/create_group_usecase.dart';
import '../features/groups/domain/usecases/create_invitation_usecase.dart';
import '../features/groups/domain/usecases/get_group_members_usecase.dart';
import '../features/groups/domain/usecases/get_group_usecase.dart';
import '../features/groups/domain/usecases/get_my_groups_usecase.dart';
import '../features/groups/domain/usecases/remove_member_usecase.dart';
import '../features/groups/presentation/bloc/groups_cubit.dart';
import '../features/settlements/domain/usecases/confirm_settlement_usecase.dart';
import '../features/settlements/domain/usecases/create_settlement_usecase.dart';
import '../features/settlements/domain/usecases/get_group_activity_usecase.dart';
import 'injection.dart';
import 'router.dart';

class BudgetBoxApp extends StatelessWidget {
  const BudgetBoxApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LoginUseCase>.value(value: dependencies.loginUseCase),
        RepositoryProvider<RegisterUseCase>.value(value: dependencies.registerUseCase),
        RepositoryProvider<LogoutUseCase>.value(value: dependencies.logoutUseCase),
        RepositoryProvider<RestoreSessionUseCase>.value(value: dependencies.restoreSessionUseCase),
        RepositoryProvider<UpdateProfileUseCase>.value(value: dependencies.updateProfileUseCase),
        RepositoryProvider<GetMyGroupsUseCase>.value(value: dependencies.getMyGroupsUseCase),
        RepositoryProvider<GetGroupUseCase>.value(value: dependencies.getGroupUseCase),
        RepositoryProvider<CreateGroupUseCase>.value(value: dependencies.createGroupUseCase),
        RepositoryProvider<GetGroupMembersUseCase>.value(value: dependencies.getGroupMembersUseCase),
        RepositoryProvider<CreateInvitationUseCase>.value(value: dependencies.createInvitationUseCase),
        RepositoryProvider<AcceptInvitationUseCase>.value(value: dependencies.acceptInvitationUseCase),
        RepositoryProvider<AddMemberUseCase>.value(value: dependencies.addMemberUseCase),
        RepositoryProvider<RemoveMemberUseCase>.value(value: dependencies.removeMemberUseCase),
        RepositoryProvider<GetGroupBalancesUseCase>.value(value: dependencies.getGroupBalancesUseCase),
        RepositoryProvider<GetSettlementSuggestionsUseCase>.value(
          value: dependencies.getSettlementSuggestionsUseCase,
        ),
        RepositoryProvider<GetGroupActivityUseCase>.value(value: dependencies.getGroupActivityUseCase),
        RepositoryProvider<CreateSettlementUseCase>.value(value: dependencies.createSettlementUseCase),
        RepositoryProvider<ConfirmSettlementUseCase>.value(value: dependencies.confirmSettlementUseCase),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: dependencies.authCubit),
          BlocProvider<GroupsCubit>.value(value: dependencies.groupsCubit),
        ],
        child: MaterialApp.router(
          title: 'BudgetBox',
          debugShowCheckedModeBanner: false,
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
            useMaterial3: true,
          ),
          routerConfig: buildRouter(dependencies.authCubit),
        ),
      ),
    );
  }
}

