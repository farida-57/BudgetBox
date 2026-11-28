import '../entities/group.dart';
import '../entities/group_invitation.dart';
import '../entities/group_member.dart';

/// Contrat du repository de groupes.
abstract class GroupRepository {
  /// Groupes auxquels l'utilisateur connecté appartient.
  Future<List<Group>> getMyGroups();

  /// Détail d'un groupe (accès réservé aux membres).
  Future<Group> getGroup(String groupId);

  /// Crée un groupe ; l'utilisateur devient administrateur.
  Future<Group> createGroup({required String name, String currency = 'XOF'});

  /// Membres du groupe.
  Future<List<GroupMember>> getMembers(String groupId);

  /// Génère une invitation à usage unique (admin uniquement).
  Future<GroupInvitation> createInvitation(String groupId);

  /// Accepte une invitation via son jeton.
  Future<Group> acceptInvitation(String token);

  /// Ajoute directement un membre par son courriel (admin uniquement).
  Future<GroupMember> addMember(String groupId, String email);

  /// Retire un membre (admin uniquement).
  Future<void> removeMember(String groupId, String userId);
}
