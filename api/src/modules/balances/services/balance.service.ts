import mongoose from 'mongoose';
import { compareDisplayNames } from '../../../shared/display-name-order';
import { GroupService } from '../../groups/services/group.service';
import { User } from '../../users/models/user.model';
import { computeNetBalances } from '../domain/balance-calculator';
import { suggestSettlements, type MemberBalance } from '../domain/settlement-suggestions';
import { MongoBalanceSources, type BalanceSources } from './balance-sources';

export interface MemberBalanceView extends MemberBalance {
  /** `false` pour une personne retirée du groupe qui garde un solde non nul. */
  isMember: boolean;
}

export interface GroupBalancesView {
  groupId: string;
  currency: string;
  balances: MemberBalanceView[];
}

export interface SettlementSuggestionView {
  fromUserId: string;
  fromDisplayName: string;
  toUserId: string;
  toDisplayName: string;
  amount: number;
}

export interface SettlementSuggestionsView {
  groupId: string;
  currency: string;
  suggestions: SettlementSuggestionView[];
}

/**
 * Soldes et suggestions, toujours recalculés à la demande sur le serveur.
 * Aucun solde n'est stocké ni accepté depuis l'application.
 */
export class BalanceService {
  constructor(
    private readonly groupService: GroupService = new GroupService(),
    private readonly sources: BalanceSources = new MongoBalanceSources(),
  ) {}

  async getBalances(groupId: string, actorId: string): Promise<GroupBalancesView> {
    // Contrôle d'accès du module groupes, avec l'identité issue du jeton :
    // 404 si le groupe n'existe pas, 403 si l'utilisateur n'en est pas membre.
    const group = await this.groupService.getGroup(groupId, actorId);
    const members = await this.groupService.listMembers(groupId, actorId);

    const [expenses, settlements] = await Promise.all([
      this.sources.listExpenses(groupId),
      this.sources.listConfirmedSettlements(groupId),
    ]);

    const net = computeNetBalances({
      memberIds: members.map((member) => member.userId),
      expenses,
      settlements,
    });

    // `listMembers` renvoie déjà les membres triés par nom (ordre français).
    const memberViews: MemberBalanceView[] = members.map((member) => ({
      userId: member.userId,
      displayName: member.displayName,
      balance: net.get(member.userId) ?? 0,
      isMember: true,
    }));
    const formerViews = await this.formerMemberBalances(net, new Set(members.map((m) => m.userId)));

    return {
      groupId: group.id,
      currency: group.currency ?? 'XOF',
      balances: [...memberViews, ...formerViews],
    };
  }

  async getSettlementSuggestions(groupId: string, actorId: string): Promise<SettlementSuggestionsView> {
    const { groupId: id, currency, balances } = await this.getBalances(groupId, actorId);
    const names = new Map(balances.map((entry) => [entry.userId, entry.displayName]));

    const suggestions = suggestSettlements(balances).map((suggestion) => ({
      fromUserId: suggestion.fromUserId,
      fromDisplayName: names.get(suggestion.fromUserId) ?? '',
      toUserId: suggestion.toUserId,
      toDisplayName: names.get(suggestion.toUserId) ?? '',
      amount: suggestion.amount,
    }));

    return { groupId: id, currency, suggestions };
  }

  /**
   * Une personne retirée du groupe peut encore devoir ou recevoir de l'argent :
   * l'ignorer casserait la somme nulle. On l'affiche donc, marquée `isMember: false`.
   */
  private async formerMemberBalances(
    net: Map<string, number>,
    memberIds: Set<string>,
  ): Promise<MemberBalanceView[]> {
    const formerIds = [...net.entries()]
      .filter(([userId, balance]) => !memberIds.has(userId) && balance !== 0)
      .map(([userId]) => userId);
    if (formerIds.length === 0) {
      return [];
    }

    const users = await User.find({ _id: { $in: formerIds.filter((id) => mongoose.isValidObjectId(id)) } })
      .select('displayName')
      .lean();
    const names = new Map(users.map((user) => [user._id.toString(), user.displayName]));

    return formerIds
      .map((userId) => ({
        userId,
        displayName: names.get(userId) ?? 'Ancien membre',
        balance: net.get(userId) ?? 0,
        isMember: false,
      }))
      .sort((a, b) => compareDisplayNames(a.displayName, b.displayName));
  }
}
