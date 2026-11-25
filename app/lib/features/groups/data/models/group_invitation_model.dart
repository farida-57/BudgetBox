import '../../domain/entities/group_invitation.dart';

class GroupInvitationModel extends GroupInvitation {
  const GroupInvitationModel({required super.token, required super.expiresAt});

  factory GroupInvitationModel.fromJson(Map<String, dynamic> json) {
    return GroupInvitationModel(
      token: json['token'] as String,
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 7)),
    );
  }
}
