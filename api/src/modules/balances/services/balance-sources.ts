import mongoose from 'mongoose';
import type { BalanceExpense, BalanceSettlement } from '../domain/balance-calculator';

/**
 * Port de lecture des opérations d'un groupe.
 *
 * Le calcul des soldes ne dépend pas des modèles Mongoose des modules
 * dépenses (Membre 3) et règlements (Membre 4) : il lit seulement les champs
 * du contrat ci-dessous. Une autre implémentation peut être injectée en test.
 */
export interface BalanceSources {
  listExpenses(groupId: string): Promise<BalanceExpense[]>;
  /** Uniquement les règlements `confirmed` : un règlement en attente ne compte pas. */
  listConfirmedSettlements(groupId: string): Promise<BalanceSettlement[]>;
}

/**
 * Contrat de stockage partagé avec les membres 3 et 4
 * (noms de collections dérivés des modèles Mongoose `Expense` et `Settlement`) :
 *   expenses    : { groupId: ObjectId, payerId: ObjectId, amount: number,
 *                   participants: [{ userId: ObjectId, shareAmount: number }] }
 *   settlements : { groupId: ObjectId, fromUserId: ObjectId, toUserId: ObjectId,
 *                   amount: number, status: 'pending' | 'confirmed' }
 */
export const EXPENSES_COLLECTION = 'expenses';
export const SETTLEMENTS_COLLECTION = 'settlements';

interface ExpenseRow {
  groupId: unknown;
  payerId: unknown;
  amount: unknown;
  participants?: { userId: unknown; shareAmount: unknown }[];
}

interface SettlementRow {
  groupId: unknown;
  fromUserId: unknown;
  toUserId: unknown;
  amount: unknown;
  status: unknown;
}

function database() {
  const db = mongoose.connection.db;
  if (!db) {
    throw new Error('Connexion MongoDB indisponible');
  }
  return db;
}

export class MongoBalanceSources implements BalanceSources {
  async listExpenses(groupId: string): Promise<BalanceExpense[]> {
    const rows = await database()
      .collection<ExpenseRow>(EXPENSES_COLLECTION)
      .find(
        { groupId: new mongoose.Types.ObjectId(groupId) },
        { projection: { payerId: 1, amount: 1, participants: 1 } },
      )
      .toArray();

    // Les montants sont transmis tels quels : le calculateur vérifie qu'ils sont des entiers.
    return rows.map((row) => ({
      id: String(row._id),
      payerId: String(row.payerId),
      amount: row.amount as number,
      participants: (row.participants ?? []).map((share) => ({
        userId: String(share.userId),
        shareAmount: share.shareAmount as number,
      })),
    }));
  }

  async listConfirmedSettlements(groupId: string): Promise<BalanceSettlement[]> {
    const rows = await database()
      .collection<SettlementRow>(SETTLEMENTS_COLLECTION)
      .find(
        { groupId: new mongoose.Types.ObjectId(groupId), status: 'confirmed' },
        { projection: { fromUserId: 1, toUserId: 1, amount: 1, status: 1 } },
      )
      .toArray();

    return rows.map((row) => ({
      id: String(row._id),
      fromUserId: String(row.fromUserId),
      toUserId: String(row.toUserId),
      amount: row.amount as number,
      status: String(row.status),
    }));
  }
}
