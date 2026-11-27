import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  const Expense({
    required this.id,
    required this.label,
    required this.amount,
    required this.payerId,
    required this.category,
    required this.date,
  });

  final String id;
  final String label;
  final int amount;
  final String payerId;
  final String category;
  final DateTime date;

  @override
  List<Object?> get props => [id, label, amount, payerId, category, date];
}
