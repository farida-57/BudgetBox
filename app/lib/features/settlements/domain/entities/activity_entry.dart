import 'package:equatable/equatable.dart';

class ActivityEntry extends Equatable {
  const ActivityEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.currency,
    required this.occurredAt,
    this.status,
    this.fromUserId,
    this.toUserId,
    this.payerId,
    this.category,
  });

  final String id;
  final String type;
  final String title;
  final int amount;
  final String currency;
  final DateTime occurredAt;
  final String? status;
  final String? fromUserId;
  final String? toUserId;
  final String? payerId;
  final String? category;

  @override
  List<Object?> get props => [id, type, title, amount, currency, occurredAt, status, fromUserId, toUserId, payerId, category];
}

class ActivityPage {
  const ActivityPage({required this.items, required this.page, required this.pages, required this.total});
  final List<ActivityEntry> items;
  final int page;
  final int pages;
  final int total;
}
