import 'package:equatable/equatable.dart';

import '../../../groups/domain/entities/group_member.dart';

enum ExpenseFormStatus { loading, ready, submitting, success, loadError }

class ExpenseFormState extends Equatable {
  const ExpenseFormState({
    this.status = ExpenseFormStatus.loading,
    this.members = const [],
    this.payerId,
    this.isCustom = false,
    this.selectedIds = const {},
    this.customAmounts = const {},
    this.fieldErrors = const {},
    this.message,
  });

  final ExpenseFormStatus status;
  final List<GroupMember> members;
  final String? payerId;
  final bool isCustom;

  /// Partage égal : membres cochés.
  final Set<String> selectedIds;

  /// Partage personnalisé : montant saisi par membre.
  final Map<String, int> customAmounts;

  /// Erreurs par champ (clés : label, amount, category, payerId, split).
  final Map<String, String> fieldErrors;
  final String? message;

  int get customTotal => customAmounts.values.fold(0, (a, b) => a + b);

  /// Les erreurs et le message sont effacés à chaque modification.
  ExpenseFormState copyWith({
    ExpenseFormStatus? status,
    List<GroupMember>? members,
    String? payerId,
    bool? isCustom,
    Set<String>? selectedIds,
    Map<String, int>? customAmounts,
    Map<String, String> fieldErrors = const {},
    String? message,
  }) => ExpenseFormState(
    status: status ?? this.status,
    members: members ?? this.members,
    payerId: payerId ?? this.payerId,
    isCustom: isCustom ?? this.isCustom,
    selectedIds: selectedIds ?? this.selectedIds,
    customAmounts: customAmounts ?? this.customAmounts,
    fieldErrors: fieldErrors,
    message: message,
  );

  @override
  List<Object?> get props => [
    status,
    members,
    payerId,
    isCustom,
    selectedIds,
    customAmounts,
    fieldErrors,
    message,
  ];
}
