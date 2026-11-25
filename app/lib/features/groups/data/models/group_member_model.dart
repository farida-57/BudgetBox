import '../../domain/entities/group.dart';
import '../../domain/entities/group_member.dart';

class GroupMemberModel extends GroupMember {
  const GroupMemberModel({
    required super.userId,
    required super.displayName,
    required super.email,
    required super.role,
    super.joinedAt,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String? ?? 'Utilisateur',
      email: json['email'] as String? ?? '',
      role: groupRoleFromString(json['role'] as String?) ?? GroupRole.membre,
      joinedAt: DateTime.tryParse(json['joinedAt'] as String? ?? ''),
    );
  }
}
