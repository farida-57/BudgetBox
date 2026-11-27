import '../../domain/entities/activity_entry.dart';

class ActivityEntryModel extends ActivityEntry {
  const ActivityEntryModel({
    required super.id, required super.type, required super.title, required super.amount,
    required super.currency, required super.occurredAt, super.status,
    super.fromUserId, super.toUserId, super.payerId, super.category,
  });

  factory ActivityEntryModel.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'expense';
    final amount = json['amount'];
    final rawDate = json['occurredAt'] ?? json['createdAt'] ?? json['spentAt'];
    if (json['_id'] == null || amount is! int || rawDate == null) {
      throw const FormatException('Élément d’historique invalide.');
    }
    return ActivityEntryModel(
      id: json['_id'].toString(), type: type,
      title: (json['title'] ?? json['label'] ?? (type == 'expense' ? 'Dépense' : 'Règlement')).toString(),
      amount: amount, currency: (json['currency'] ?? 'XOF').toString(),
      occurredAt: DateTime.parse(rawDate.toString()), status: json['status'] as String?,
      fromUserId: json['fromUserId']?.toString(), toUserId: json['toUserId']?.toString(),
      payerId: json['payerId']?.toString(), category: json['category']?.toString(),
    );
  }
}
