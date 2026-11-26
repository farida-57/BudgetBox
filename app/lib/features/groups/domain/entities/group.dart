import 'package:equatable/equatable.dart';

enum GroupRole { admin, membre }

GroupRole? groupRoleFromString(String? value) => switch (value) {
      'admin' => GroupRole.admin,
      'membre' => GroupRole.membre,
      _ => null,
    };

class Group extends Equatable {
  const Group({
    required this.id,
    required this.name,
    required this.currency,
    this.role,
    this.memberCount = 0,
    this.createdAt,
  });

  final String id;
  final String name;
  final String currency;
  final GroupRole? role;
  final int memberCount;
  final DateTime? createdAt;

  bool get isAdmin => role == GroupRole.admin;

  @override
  List<Object?> get props => [id, name, currency, role, memberCount, createdAt];
}
