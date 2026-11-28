import '../../domain/entities/expense.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.label,
    required super.amount,
    required super.payerId,
    required super.category,
    required super.date,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
    id: json['id'] as String,
    label: json['label'] as String,
    amount: (json['amount'] as num).toInt(),
    payerId: json['payerId'] as String,
    category: json['category'] as String,
    date: DateTime.parse(json['date'] as String),
  );
}
