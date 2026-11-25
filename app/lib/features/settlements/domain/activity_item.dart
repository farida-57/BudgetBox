class ActivityItem {
  const ActivityItem({required this.id, required this.type, required this.title, required this.amount, required this.date, this.status, this.raw = const {}});
  final String id;
  final String type;
  final String title;
  final int amount;
  final DateTime date;
  final String? status;
  final Map<String, dynamic> raw;

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'settlement';
    final date = DateTime.tryParse('${json['occurredAt'] ?? json['createdAt'] ?? json['spentAt'] ?? ''}') ?? DateTime.now();
    final amount = (json['amount'] as num?)?.toInt() ?? 0;
    final title = type == 'expense'
        ? (json['title'] ?? json['label'] ?? 'Dépense').toString()
        : 'Règlement ${json['fromUserId'] ?? ''} → ${json['toUserId'] ?? ''}';
    return ActivityItem(id: '${json['_id'] ?? ''}', type: type, title: title, amount: amount, date: date, status: json['status'] as String?, raw: json);
  }
}
