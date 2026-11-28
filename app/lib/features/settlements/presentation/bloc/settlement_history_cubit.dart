import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/activity_entry.dart';
import '../../domain/usecases/confirm_settlement_usecase.dart';
import '../../domain/usecases/create_settlement_usecase.dart';
import '../../domain/usecases/get_group_activity_usecase.dart';

sealed class SettlementHistoryState {}
class SettlementHistoryLoading extends SettlementHistoryState {}
class SettlementHistoryLoaded extends SettlementHistoryState {
  SettlementHistoryLoaded(this.result);
  final ActivityPage result;
}
class SettlementHistoryError extends SettlementHistoryState {
  SettlementHistoryError(this.message);
  final String message;
}

class SettlementHistoryCubit extends Cubit<SettlementHistoryState> {
  SettlementHistoryCubit({required this.groupId, required GetGroupActivityUseCase getActivity,
    required CreateSettlementUseCase createSettlement, required ConfirmSettlementUseCase confirmSettlement})
      : _getActivity = getActivity, _create = createSettlement, _confirm = confirmSettlement,
        super(SettlementHistoryLoading());
  final String groupId;
  final GetGroupActivityUseCase _getActivity;
  final CreateSettlementUseCase _create;
  final ConfirmSettlementUseCase _confirm;

  Future<void> load({int page = 1, String? memberId, String? payerId, String? category, String? type, DateTime? from, DateTime? to}) async {
    emit(SettlementHistoryLoading());
    try {
      final result = await _getActivity(groupId, page: page, memberId: memberId, payerId: payerId,
        category: category, type: type, from: from, to: to);
      if (!isClosed) emit(SettlementHistoryLoaded(result));
    } on Failure catch (error) {
      if (!isClosed) emit(SettlementHistoryError(error.message));
    } catch (error) {
      if (!isClosed) emit(SettlementHistoryError(error.toString()));
    }
  }

  Future<void> create({required String fromUserId, required String toUserId, required int amount}) =>
      _create(groupId, fromUserId: fromUserId, toUserId: toUserId, amount: amount);

  Future<void> confirm(String settlementId) => _confirm(groupId, settlementId);
}
