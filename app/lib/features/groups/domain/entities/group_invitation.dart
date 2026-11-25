import 'package:equatable/equatable.dart';

/// Invitation à usage unique générée par un admin de groupe.
class GroupInvitation extends Equatable {
  const GroupInvitation({required this.token, required this.expiresAt});

  final String token;
  final DateTime expiresAt;

  /// Lien affiché à partager. Le format définitif dépendra du deep-linking.
  String get shareText => 'Rejoignez mon groupe BudgetBox avec ce code : $token';

  @override
  List<Object?> get props => [token, expiresAt];
}
