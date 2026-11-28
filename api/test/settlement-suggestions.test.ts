import { describe, expect, it } from 'vitest';
import {
  suggestSettlements,
  type MemberBalance,
  type SettlementSuggestion,
} from '../src/modules/balances/domain/settlement-suggestions';
import { appErrorOf } from './money-helpers';

/** Applique les transferts proposés comme s'ils étaient des règlements confirmés. */
function applySuggestions(balances: readonly MemberBalance[], suggestions: readonly SettlementSuggestion[]) {
  const result = new Map(balances.map((b) => [b.userId, b.balance]));
  for (const s of suggestions) {
    result.set(s.fromUserId, (result.get(s.fromUserId) ?? 0) + s.amount);
    result.set(s.toUserId, (result.get(s.toUserId) ?? 0) - s.amount);
  }
  return result;
}

const member = (userId: string, displayName: string, balance: number): MemberBalance => ({
  userId,
  displayName,
  balance,
});

describe('Suggestions de règlement', () => {
  it('propose deux transferts vers Awa dans l\'exemple du cahier', () => {
    const balances = [member('a', 'Awa', 6_666), member('b', 'Binta', -3_333), member('c', 'Chérif', -3_333)];
    expect(suggestSettlements(balances)).toEqual([
      { fromUserId: 'b', toUserId: 'a', amount: 3_333 },
      { fromUserId: 'c', toUserId: 'a', amount: 3_333 },
    ]);
  });

  it('ne propose rien quand tous les soldes sont nuls', () => {
    expect(suggestSettlements([member('a', 'Awa', 0), member('b', 'Binta', 0)])).toEqual([]);
  });

  it('ramène tous les soldes à zéro avec au plus n − 1 transferts bornés par les soldes', () => {
    const balances = [
      member('a', 'Awa', 4_666),
      member('b', 'Binta', 1_667),
      member('c', 'Chérif', -6_333),
      member('d', 'Diane', 2_500),
      member('e', 'Ebou', -2_500),
    ];
    const suggestions = suggestSettlements(balances);

    expect([...applySuggestions(balances, suggestions).values()].every((v) => v === 0)).toBe(true);
    expect(suggestions.length).toBeLessThanOrEqual(balances.length - 1);
    for (const s of suggestions) {
      expect(Number.isSafeInteger(s.amount) && s.amount > 0).toBe(true);
      const from = balances.find((b) => b.userId === s.fromUserId)!;
      const to = balances.find((b) => b.userId === s.toUserId)!;
      expect(from.balance).toBeLessThan(0); // seul un débiteur paie
      expect(to.balance).toBeGreaterThan(0); // seul un créancier reçoit
      expect(s.amount).toBeLessThanOrEqual(-from.balance);
      expect(s.amount).toBeLessThanOrEqual(to.balance);
    }
  });

  it('associe directement deux montants égaux (un seul transfert par paire)', () => {
    const balances = [member('d', 'Diane', 2_500), member('e', 'Ebou', -2_500), member('a', 'Awa', 100), member('b', 'Binta', -100)];
    expect(suggestSettlements(balances)).toEqual([
      { fromUserId: 'e', toUserId: 'd', amount: 2_500 },
      { fromUserId: 'b', toUserId: 'a', amount: 100 },
    ]);
  });

  it('solde toujours le groupe sur des cas générés', () => {
    // Générateur pseudo-aléatoire déterministe (Park-Miller) : les cas sont reproductibles.
    let seed = 42;
    const random = () => {
      seed = (seed * 48_271) % 2_147_483_647;
      return seed;
    };
    for (let run = 0; run < 200; run += 1) {
      const size = 2 + (random() % 7);
      const values = Array.from({ length: size - 1 }, () => (random() % 200_001) - 100_000);
      values.push(-values.reduce((t, v) => t + v, 0)); // somme nulle
      const balances = values.map((v, i) => member(`u${i}`, `Personne ${i}`, v));

      const suggestions = suggestSettlements(balances);
      expect([...applySuggestions(balances, suggestions).values()].every((v) => v === 0)).toBe(true);
      expect(suggestions.length).toBeLessThanOrEqual(Math.max(0, balances.filter((b) => b.balance !== 0).length - 1));
    }
  });

  it('ne modifie pas les soldes reçus (lecture seule)', () => {
    const balances = [member('a', 'Awa', 6_666), member('b', 'Binta', -3_333), member('c', 'Chérif', -3_333)];
    const snapshot = structuredClone(balances);
    suggestSettlements(balances);
    expect(balances).toEqual(snapshot);
  });

  it('refuse des soldes dont la somme n\'est pas nulle', () => {
    const error = appErrorOf(() => suggestSettlements([member('a', 'Awa', 100), member('b', 'Binta', -50)]));
    expect(error.code).toBe('BALANCE_INTEGRITY_ERROR');
  });

  it('refuse un solde non entier', () => {
    const error = appErrorOf(() => suggestSettlements([member('a', 'Awa', 0.5), member('b', 'Binta', -0.5)]));
    expect(error.code).toBe('BALANCE_INTEGRITY_ERROR');
  });
});
