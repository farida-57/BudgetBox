import 'package:equatable/equatable.dart';

import 'group.dart';

class GroupMember extends Equatable {
  const GroupMember({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.role,
    this.joinedAt,
  });

  final String userId;
  final String displayName;
  final String email;
  final GroupRole role;
  final DateTime? joinedAt;

  @override
  List<Object?> get props => [userId, displayName, email, role, joinedAt];
}
