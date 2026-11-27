import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../groups/domain/usecases/get_group_members_usecase.dart';
import '../../domain/entities/expense_draft.dart';
import '../../domain/entities/expense_validation_exception.dart';
import '../../domain/usecases/create_expense_usecase.dart';
import 'expense_form_state.dart';

/// Formulaire de nouvelle dépense. Le serveur reste l'autorité finale :
/// les contrôles locaux évitent seulement des allers-retours inutiles.
class ExpenseFormCubit extends Cubit<ExpenseFormState> {
  ExpenseFormCubit({
    required String groupId,
    required GetGroupMembersUseCase getMembersUseCase,
    required CreateExpenseUseCase createExpenseUseCase,
  }) : _groupId = groupId,
       _getMembers = getMembersUseCase,
       _createExpense = createExpenseUseCase,
       super(const ExpenseFormState());

  final String _groupId;
  final GetGroupMembersUseCase _getMembers;
  final CreateExpenseUseCase _createExpense;

  Future<void> load() async {
    emit(const ExpenseFormState());
    try {
      final members = await _getMembers(_groupId);
      emit(
        state.copyWith(
          status: ExpenseFormStatus.ready,
          members: members,
          payerId: members.isEmpty ? null : members.first.userId,
          selectedIds: {for (final m in members) m.userId},
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ExpenseFormStatus.loadError,
          message: e.toString(),
        ),
      );
    }
  }

  void setPayer(String id) => emit(state.copyWith(payerId: id));

  void setCustom(bool value) => emit(state.copyWith(isCustom: value));

  void toggleParticipant(String id) {
    final next = {...state.selectedIds};
    if (!next.remove(id)) next.add(id);
    emit(state.copyWith(selectedIds: next));
  }

  void setCustomAmount(String id, int amount) =>
      emit(state.copyWith(customAmounts: {...state.customAmounts, id: amount}));

  Future<void> submit({
    required String label,
    required String amountText,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    final amount = int.tryParse(amountText.trim());
    final errors = <String, String>{};

    if (label.trim().isEmpty) errors['label'] = 'Libellé requis';
    if (category.trim().isEmpty) errors['category'] = 'Catégorie requise';
    if (amount == null || amount <= 0) errors['amount'] = 'Entrez un montant entier positif';
    if (state.payerId == null) errors['payerId'] = 'Payeur requis';

    final shares = {...state.customAmounts}..removeWhere((_, v) => v <= 0);
    if (state.isCustom) {
      if (shares.isEmpty) {
        errors['split'] = 'Saisissez au moins une part';
      } else if (amount != null && state.customTotal != amount) {
        errors['split'] =
            'La somme des parts (${state.customTotal}) doit être égale au montant ($amount)';
      }
    } else if (state.selectedIds.isEmpty) {
      errors['split'] = 'Choisissez au moins un participant';
    }

    if (errors.isNotEmpty) {
      emit(state.copyWith(fieldErrors: errors));
      return;
    }

    emit(state.copyWith(status: ExpenseFormStatus.submitting));
    try {
      await _createExpense(
        _groupId,
        ExpenseDraft(
          label: label.trim(),
          amount: amount!,
          payerId: state.payerId!,
          category: category.trim(),
          date: date,
          note: note,
          participantIds: state.isCustom ? null : state.selectedIds.toList(),
          customShares: state.isCustom ? shares : null,
        ),
      );
      emit(state.copyWith(status: ExpenseFormStatus.success));
    } on ExpenseValidationException catch (e) {
      emit(
        state.copyWith(
          status: ExpenseFormStatus.ready,
          fieldErrors: _serverErrors(e),
          message: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: ExpenseFormStatus.ready, message: e.toString()),
      );
    }
  }

  /// Rattache les erreurs 422 du serveur aux champs du formulaire.
  Map<String, String> _serverErrors(ExpenseValidationException e) {
    final result = <String, String>{};
    e.fieldErrors.forEach((path, text) {
      result.putIfAbsent(path.startsWith('split') ? 'split' : path, () => text);
    });
    switch (e.code) {
      case 'SHARES_MISMATCH' ||
          'INVALID_PARTICIPANT' ||
          'DUPLICATE_PARTICIPANT':
        result['split'] = e.message;
      case 'INVALID_PAYER':
        result['payerId'] = e.message;
    }
    return result;
  }
}
