import { describe, expect, it } from 'vitest';
import {
  computeNetBalances,
  type BalanceExpense,
  type BalanceSettlement,
} from '../src/modules/balances/domain/balance-calculator';
import { splitEqually } from '../src/modules/expenses/domain/expense-shares';
import { appErrorOf, sum } from './money-helpers';

const AWA = 'u-awa';
const BINTA = 'u-binta';
const CHERIF = 'u-cherif';
const memberIds = [AWA, BINTA, CHERIF];

/** Exemple du cahier §4.7 : 10 000 XOF payés par Awa, partagés également à trois. */
const courses: BalanceExpense = {
  id: 'e1',
  payerId: AWA,
  amount: 10_000,
  participants: splitEqually(10_000, [
    { userId: AWA, displayName: 'Awa' },
    { userId: BINTA, displayName: 'Binta' },
    { userId: CHERIF, displayName: 'Chérif' },
  ]),
};

function settlement(status: string, amount = 2_000): BalanceSettlement {
  return { id: `s-${status}`, fromUserId: BINTA, toUserId: AWA, amount, status };
}

describe('Soldes nets', () => {
  it('donne un solde nul à chaque membre sans opération', () => {
    const balances = computeNetBalances({ memberIds, expenses: [], settlements: [] });
    expect(Object.fromEntries(balances)).toEqual({ [AWA]: 0, [BINTA]: 0, [CHERIF]: 0 });
  });

  it('crédite le payeur du total et débite chaque participant de sa part (exemple du cahier)', () => {
    const balances = computeNetBalances({ memberIds, expenses: [courses], settlements: [] });
    expect(balances.get(AWA)).toBe(6_666); // 10 000 avancés − 3 334 de sa propre part
    expect(balances.get(BINTA)).toBe(-3_333);
    expect(balances.get(CHERIF)).toBe(-3_333);
    expect(sum([...balances.values()])).toBe(0);
  });

  it('cumule plusieurs dépenses égales et personnalisées avec une somme toujours nulle', () => {
    const loyer: BalanceExpense = {
      id: 'e2',
      payerId: BINTA,
      amount: 9_000,
      participants: [
        { userId: AWA, shareAmount: 2_000 },
        { userId: BINTA, shareAmount: 4_000 },
        { userId: CHERIF, shareAmount: 3_000 },
      ],
    };
    const balances = computeNetBalances({ memberIds, expenses: [courses, loyer], settlements: [] });
    expect(balances.get(AWA)).toBe(4_666); // +10 000 − 3 334 − 2 000
    expect(balances.get(BINTA)).toBe(1_667); // −3 333 + 9 000 − 4 000
    expect(balances.get(CHERIF)).toBe(-6_333); // −3 333 − 3 000
    expect(sum([...balances.values()])).toBe(0);
  });

  it('applique un règlement confirmé : la dette de Binta et le crédit d\'Awa baissent ensemble', () => {
    const balances = computeNetBalances({ memberIds, expenses: [courses], settlements: [settlement('confirmed')] });
    expect(balances.get(BINTA)).toBe(-1_333); // Binta doit encore 1 333 XOF
    expect(balances.get(AWA)).toBe(4_666);
    expect(balances.get(CHERIF)).toBe(-3_333);
    expect(sum([...balances.values()])).toBe(0);
  });

  it('ignore un règlement en attente', () => {
    const before = computeNetBalances({ memberIds, expenses: [courses], settlements: [] });
    const after = computeNetBalances({ memberIds, expenses: [courses], settlements: [settlement('pending')] });
    expect(Object.fromEntries(after)).toEqual(Object.fromEntries(before));
  });

  it('garde le solde d\'une personne qui n\'est plus membre pour conserver la somme nulle', () => {
    const balances = computeNetBalances({ memberIds: [AWA, BINTA], expenses: [courses], settlements: [] });
    expect(balances.get(CHERIF)).toBe(-3_333);
    expect(sum([...balances.values()])).toBe(0);
  });

  it('refuse une dépense enregistrée dont les parts ne totalisent pas le montant', () => {
    const corrupted: BalanceExpense = {
      id: 'e-bad',
      payerId: AWA,
      amount: 10_000,
      participants: [{ userId: AWA, shareAmount: 9_999 }],
    };
    const error = appErrorOf(() => computeNetBalances({ memberIds, expenses: [corrupted], settlements: [] }));
    expect(error.code).toBe('BALANCE_INTEGRITY_ERROR');
  });

  it('refuse un montant enregistré décimal', () => {
    const decimal: BalanceExpense = {
      id: 'e-dec',
      payerId: AWA,
      amount: 100.5,
      participants: [{ userId: AWA, shareAmount: 100.5 }],
    };
    const error = appErrorOf(() => computeNetBalances({ memberIds, expenses: [decimal], settlements: [] }));
    expect(error.code).toBe('BALANCE_INTEGRITY_ERROR');
  });

  it('refuse un règlement confirmé invalide (montant décimal)', () => {
    const error = appErrorOf(() =>
      computeNetBalances({ memberIds, expenses: [courses], settlements: [settlement('confirmed', 10.5)] }),
    );
    expect(error.code).toBe('BALANCE_INTEGRITY_ERROR');
  });
});
