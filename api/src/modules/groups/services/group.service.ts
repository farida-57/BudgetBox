import { randomBytes } from 'node:crypto';
import mongoose from 'mongoose';
import { env } from '../../../config/environment';
import { conflict, forbidden, notFound } from '../../../shared/errors/app-error';
import { sha256 } from '../../../shared/utils/hash';
import { User } from '../../users/models/user.model';
import { Group, type GroupDocument, type GroupRole } from '../models/group.model';
import type { CreateGroupInput, UpdateGroupInput } from '../validators/group.validator';

interface MemberInfo {
  userId: string;
  displayName: string;
  email: string;
  role: GroupRole;
  joinedAt: Date;
}

function isValidObjectId(id: string): boolean {
  return mongoose.isValidObjectId(id);
}

async function findGroupOr404(groupId: string): Promise<GroupDocument> {
  if (!isValidObjectId(groupId)) {
    throw notFound('Groupe introuvable', 'GROUP_NOT_FOUND');
  }
  const group = await Group.findById(groupId);
  if (!group) {
    throw notFound('Groupe introuvable', 'GROUP_NOT_FOUND');
  }
  return group;
}

function findMembership(group: GroupDocument, userId: string) {
  return group.members.find((m) => m.userId.toString() === userId);
}

function assertMember(group: GroupDocument, userId: string) {
  const member = findMembership(group, userId);
  if (!member) {
    throw forbidden('Vous n\'êtes pas membre de ce groupe');
  }
  return member;
}

function assertAdmin(group: GroupDocument, userId: string) {
  const member = assertMember(group, userId);
  if (member.role !== 'admin') {
    throw forbidden('Réservé à l\'administrateur du groupe');
  }
  return member;
}

function toGroupSummary(group: GroupDocument, userId: string) {
  const me = findMembership(group, userId);
  return {
    id: group._id.toString(),
    name: group.name,
    currency: group.currency,
    role: me?.role ?? null,
    memberCount: group.members.length,
    createdAt: group.createdAt,
  };
}

export class GroupService {
  async createGroup(userId: string, input: CreateGroupInput) {
    const group = await Group.create({
      name: input.name,
      currency: input.currency,
      createdBy: userId,
      members: [{ userId, role: 'admin' }],
    });
    return toGroupSummary(group, userId);
  }

  async listGroups(userId: string) {
    const groups = await Group.find({ 'members.userId': userId }).sort({ createdAt: -1 });
    return groups.map((g) => toGroupSummary(g, userId));
  }

  async getGroup(groupId: string, userId: string) {
    const group = await findGroupOr404(groupId);
    assertMember(group, userId);
    return toGroupSummary(group, userId);
  }

  async updateGroup(groupId: string, userId: string, input: UpdateGroupInput) {
    const group = await findGroupOr404(groupId);
    assertAdmin(group, userId);
    if (input.name !== undefined) {
      group.name = input.name;
    }
    await group.save();
    return toGroupSummary(group, userId);
  }

  async listMembers(groupId: string, userId: string): Promise<MemberInfo[]> {
    const group = await findGroupOr404(groupId);
    assertMember(group, userId);

    const userIds = group.members.map((m) => m.userId);
    const users = await User.find({ _id: { $in: userIds } }).select('displayName email').lean();
    const byId = new Map(users.map((u) => [u._id.toString(), u]));

    return group.members
      .map((m) => {
        const u = byId.get(m.userId.toString());
        return {
          userId: m.userId.toString(),
          displayName: u?.displayName ?? 'Utilisateur',
          email: u?.email ?? '',
          role: m.role as GroupRole,
          joinedAt: m.joinedAt,
        };
      })
      .sort((a, b) => a.displayName.localeCompare(b.displayName, 'fr'));
  }

  async removeMember(groupId: string, actorId: string, targetUserId: string) {
    const group = await findGroupOr404(groupId);
    assertAdmin(group, actorId);

    const target = findMembership(group, targetUserId);
    if (!target) {
      throw notFound('Membre introuvable dans ce groupe', 'MEMBER_NOT_FOUND');
    }

    const adminCount = group.members.filter((m) => m.role === 'admin').length;
    if (target.role === 'admin' && adminCount <= 1) {
      throw conflict('Impossible de retirer le dernier administrateur du groupe', 'LAST_ADMIN');
    }

    group.members.pull({ userId: target.userId });
    await group.save();
    return { removed: true };
  }

  async createInvitation(groupId: string, actorId: string) {
    const group = await findGroupOr404(groupId);
    assertAdmin(group, actorId);

    const token = randomBytes(32).toString('base64url');
    group.invitation = {
      tokenHash: sha256(token),
      expiresAt: new Date(Date.now() + env.INVITATION_TTL_HOURS * 60 * 60 * 1000),
      usedAt: null,
    };
    await group.save();

    return {
      token,
      expiresAt: group.invitation.expiresAt,
    };
  }

  async acceptInvitation(token: string, userId: string) {
    if (!isValidObjectId(userId)) {
      throw notFound('Groupe introuvable', 'GROUP_NOT_FOUND');
    }

    const group = await Group.findOne({ 'invitation.tokenHash': sha256(token) });
    const invitation = group?.invitation;

    if (!group || !invitation) {
      throw notFound('Invitation invalide', 'INVITATION_INVALID');
    }
    if (invitation.usedAt || invitation.expiresAt < new Date()) {
      throw notFound('Invitation invalide, expirée ou déjà utilisée', 'INVITATION_INVALID');
    }

    const existing = findMembership(group, userId);
    if (existing) {
      throw conflict('Vous êtes déjà membre de ce groupe', 'ALREADY_MEMBER');
    }

    group.members.push({ userId: new mongoose.Types.ObjectId(userId), role: 'membre' });
    invitation.usedAt = new Date();
    await group.save();

    return toGroupSummary(group, userId);
  }
}
