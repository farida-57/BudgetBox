import '../features/auth/domain/usecases/login_usecase.dart';
import '../features/auth/domain/usecases/logout_usecase.dart';
import '../features/auth/domain/usecases/register_usecase.dart';
import '../features/auth/domain/usecases/restore_session_usecase.dart';
import '../features/auth/domain/usecases/update_profile_usecase.dart';
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/bloc/auth_cubit.dart';
import '../features/balances/data/datasources/balance_remote_datasource.dart';
import '../features/balances/data/repositories/balance_repository_impl.dart';
import '../features/balances/domain/repositories/balance_repository.dart';
import '../features/balances/domain/usecases/get_group_balances_usecase.dart';
import '../features/balances/domain/usecases/get_settlement_suggestions_usecase.dart';
import '../features/groups/data/datasources/group_remote_datasource.dart';
import '../features/groups/data/repositories/group_repository_impl.dart';
import '../features/groups/domain/repositories/group_repository.dart';
import '../features/groups/domain/usecases/accept_invitation_usecase.dart';
import '../features/groups/domain/usecases/create_group_usecase.dart';
import '../features/groups/domain/usecases/create_invitation_usecase.dart';
import '../features/groups/domain/usecases/get_group_members_usecase.dart';
import '../features/groups/domain/usecases/get_group_usecase.dart';
import '../features/groups/domain/usecases/get_my_groups_usecase.dart';
import '../features/groups/domain/usecases/remove_member_usecase.dart';
import '../features/groups/presentation/bloc/groups_cubit.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';

/// Graphe de dépendances de l'application ( injection manuelle ).
class AppDependencies {
  const AppDependencies({
    required this.authCubit,
    required this.groupsCubit,
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.restoreSessionUseCase,
    required this.updateProfileUseCase,
    required this.getMyGroupsUseCase,
    required this.getGroupUseCase,
    required this.createGroupUseCase,
    required this.getGroupMembersUseCase,
    required this.createInvitationUseCase,
    required this.acceptInvitationUseCase,
    required this.removeMemberUseCase,
    required this.getGroupBalancesUseCase,
    required this.getSettlementSuggestionsUseCase,
  });

  final AuthCubit authCubit;
  final GroupsCubit groupsCubit;

  // Auth usecases
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final RestoreSessionUseCase restoreSessionUseCase;
  final UpdateProfileUseCase updateProfileUseCase;

  // Groups usecases
  final GetMyGroupsUseCase getMyGroupsUseCase;
  final GetGroupUseCase getGroupUseCase;
  final CreateGroupUseCase createGroupUseCase;
  final GetGroupMembersUseCase getGroupMembersUseCase;
  final CreateInvitationUseCase createInvitationUseCase;
  final AcceptInvitationUseCase acceptInvitationUseCase;
  final RemoveMemberUseCase removeMemberUseCase;

  // Balances usecases (lecture seule, calcul côté API)
  final GetGroupBalancesUseCase getGroupBalancesUseCase;
  final GetSettlementSuggestionsUseCase getSettlementSuggestionsUseCase;
}

AppDependencies createDependencies() {
  final TokenStorage tokenStorage = SecureTokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);

  final AuthRemoteDataSource authDataSource = AuthApiDataSource(apiClient.dio);
  final AuthRepository authRepository = AuthRepositoryImpl(authDataSource, tokenStorage);

  final GroupRemoteDataSource groupDataSource = GroupApiDataSource(apiClient.dio);
  final GroupRepository groupRepository = GroupRepositoryImpl(groupDataSource);

  final BalanceRemoteDataSource balanceDataSource = BalanceApiDataSource(apiClient.dio);
  final BalanceRepository balanceRepository = BalanceRepositoryImpl(balanceDataSource);

  final loginUseCase = LoginUseCase(authRepository);
  final registerUseCase = RegisterUseCase(authRepository);
  final logoutUseCase = LogoutUseCase(authRepository);
  final restoreSessionUseCase = RestoreSessionUseCase(authRepository);
  final updateProfileUseCase = UpdateProfileUseCase(authRepository);

  final getMyGroupsUseCase = GetMyGroupsUseCase(groupRepository);
  final getGroupUseCase = GetGroupUseCase(groupRepository);
  final createGroupUseCase = CreateGroupUseCase(groupRepository);
  final getGroupMembersUseCase = GetGroupMembersUseCase(groupRepository);
  final createInvitationUseCase = CreateInvitationUseCase(groupRepository);
  final acceptInvitationUseCase = AcceptInvitationUseCase(groupRepository);
  final removeMemberUseCase = RemoveMemberUseCase(groupRepository);

  final getGroupBalancesUseCase = GetGroupBalancesUseCase(balanceRepository);
  final getSettlementSuggestionsUseCase = GetSettlementSuggestionsUseCase(balanceRepository);

  return AppDependencies(
    authCubit: AuthCubit(
      loginUseCase: loginUseCase,
      registerUseCase: registerUseCase,
      logoutUseCase: logoutUseCase,
      restoreSessionUseCase: restoreSessionUseCase,
      updateProfileUseCase: updateProfileUseCase,
    ),
    groupsCubit: GroupsCubit(
      getMyGroupsUseCase: getMyGroupsUseCase,
      createGroupUseCase: createGroupUseCase,
    ),
    loginUseCase: loginUseCase,
    registerUseCase: registerUseCase,
    logoutUseCase: logoutUseCase,
    restoreSessionUseCase: restoreSessionUseCase,
    updateProfileUseCase: updateProfileUseCase,
    getMyGroupsUseCase: getMyGroupsUseCase,
    getGroupUseCase: getGroupUseCase,
    createGroupUseCase: createGroupUseCase,
    getGroupMembersUseCase: getGroupMembersUseCase,
    createInvitationUseCase: createInvitationUseCase,
    acceptInvitationUseCase: acceptInvitationUseCase,
    removeMemberUseCase: removeMemberUseCase,
    getGroupBalancesUseCase: getGroupBalancesUseCase,
    getSettlementSuggestionsUseCase: getSettlementSuggestionsUseCase,
  );
}
