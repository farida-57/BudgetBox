import { describe, expect, it } from 'vitest';
import {
  computeExpenseShares,
  splitEqually,
  validateCustomShares,
  type GroupMemberRef,
} from '../src/modules/expenses/domain/expense-shares';
import { addXof, isXofAmount, xofAmountSchema } from '../src/shared/money/xof';
import { appErrorOf, sum } from './money-helpers';

const awa: GroupMemberRef = { userId: 'u-awa', displayName: 'Awa' };
const binta: GroupMemberRef = { userId: 'u-binta', displayName: 'Binta' };
const cherif: GroupMemberRef = { userId: 'u-cherif', displayName: 'Chérif' };
const members = [awa, binta, cherif];

describe('Montants XOF entiers', () => {
  it.each([
    ['décimal', 10.5],
    ['zéro', 0],
    ['négatif', -100],
    ['NaN', Number.NaN],
    ['infini', Number.POSITIVE_INFINITY],
    ['au-delà des entiers exacts', Number.MAX_SAFE_INTEGER + 1],
    ['chaîne', '1000'],
  ])('refuse un montant %s', (_label, value) => {
    expect(isXofAmount(value)).toBe(false);
    expect(xofAmountSchema.safeParse(value).success).toBe(false);
  });

  it('accepte un entier positif', () => {
    expect(isXofAmount(10_000)).toBe(true);
    expect(xofAmountSchema.parse(10_000)).toBe(10_000);
  });

  it('refuse une addition qui dépasserait la limite des entiers exacts', () => {
    expect(appErrorOf(() => addXof(Number.MAX_SAFE_INTEGER, 1)).code).toBe('AMOUNT_OUT_OF_RANGE');
  });
});

describe('Partage égal', () => {
  it('répartit exactement un montant divisible', () => {
    const shares = splitEqually(9_000, members);
    expect(shares.map((s) => s.shareAmount)).toEqual([3_000, 3_000, 3_000]);
  });

  it('donne le reste à Awa, première par ordre alphabétique (exemple du cahier)', () => {
    // Ordre d'entrée volontairement mélangé : seul l'ordre des noms compte.
    const shares = splitEqually(10_000, [cherif, awa, binta]);
    expect(shares).toEqual([
      { userId: 'u-awa', shareAmount: 3_334 },
      { userId: 'u-binta', shareAmount: 3_333 },
      { userId: 'u-cherif', shareAmount: 3_333 },
    ]);
    expect(sum(shares.map((s) => s.shareAmount))).toBe(10_000);
  });

  it('distribue un reste de 2 XOF aux deux premiers noms', () => {
    const shares = splitEqually(10_001, members);
    expect(shares.map((s) => s.shareAmount)).toEqual([3_334, 3_334, 3_333]);
  });

  it('applique l\'ordre alphabétique français (accents et majuscules)', () => {
    const emile = { userId: 'u-emile', displayName: 'Émile' };
    const eric = { userId: 'u-eric', displayName: 'Eric' };
    const zoe = { userId: 'u-zoe', displayName: 'zoé' };
    // Une comparaison brute des codes Unicode placerait « Émile » après « zoé ».
    const shares = splitEqually(5, [zoe, eric, emile]);
    expect(shares).toEqual([
      { userId: 'u-emile', shareAmount: 2 },
      { userId: 'u-eric', shareAmount: 2 },
      { userId: 'u-zoe', shareAmount: 1 },
    ]);
  });

  it('garde l\'ordre reçu pour deux noms identiques (aucun départage inventé)', () => {
    const first = { userId: 'u-1', displayName: 'Awa' };
    const second = { userId: 'u-2', displayName: 'Awa' };
    expect(splitEqually(3, [first, second]).map((s) => s.userId)).toEqual(['u-1', 'u-2']);
    expect(splitEqually(3, [second, first]).map((s) => s.userId)).toEqual(['u-2', 'u-1']);
  });

  it('conserve toujours la somme exacte du montant', () => {
    for (let count = 1; count <= 7; count += 1) {
      const participants = Array.from({ length: count }, (_, i) => ({ userId: `u${i}`, displayName: `P${i}` }));
      for (const amount of [1, 2, 99, 1_000, 10_001, 123_457, 9_999_999]) {
        const shares = splitEqually(amount, participants);
        expect(sum(shares.map((s) => s.shareAmount))).toBe(amount);
        const values = shares.map((s) => s.shareAmount);
        expect(Math.max(...values) - Math.min(...values)).toBeLessThanOrEqual(1);
        expect(values.every(Number.isInteger)).toBe(true);
      }
    }
  });

  it('refuse une liste de participants vide', () => {
    expect(appErrorOf(() => splitEqually(1_000, [])).code).toBe('EMPTY_PARTICIPANTS');
  });

  it.each([10.5, 0, -5, Number.NaN])('refuse le montant invalide %s', (amount) => {
    const error = appErrorOf(() => splitEqually(amount, members));
    expect(error.statusCode).toBe(422);
    expect(error.code).toBe('INVALID_AMOUNT');
  });

  it('refuse un participant répété', () => {
    expect(appErrorOf(() => splitEqually(1_000, [awa, awa])).code).toBe('DUPLICATE_PARTICIPANT');
  });
});

describe('Partage personnalisé', () => {
  it('accepte des parts dont la somme égale le montant (une part nulle est permise)', () => {
    const shares = validateCustomShares(9_000, [
      { userId: 'u-awa', shareAmount: 5_000 },
      { userId: 'u-binta', shareAmount: 4_000 },
      { userId: 'u-cherif', shareAmount: 0 },
    ]);
    expect(sum(shares.map((s) => s.shareAmount))).toBe(9_000);
  });

  it('refuse une somme trop basse', () => {
    const error = appErrorOf(() =>
      validateCustomShares(9_000, [
        { userId: 'u-awa', shareAmount: 4_000 },
        { userId: 'u-binta', shareAmount: 4_000 },
      ]),
    );
    expect(error.code).toBe('SHARES_SUM_MISMATCH');
    expect(error.details).toEqual([{ path: 'shares', expected: 9_000, actual: 8_000 }]);
  });

  it('refuse une somme trop haute', () => {
    const error = appErrorOf(() =>
      validateCustomShares(9_000, [
        { userId: 'u-awa', shareAmount: 5_000 },
        { userId: 'u-binta', shareAmount: 5_000 },
      ]),
    );
    expect(error.code).toBe('SHARES_SUM_MISMATCH');
  });

  it.each([-1, 2.5, Number.NaN])('refuse la part invalide %s', (shareAmount) => {
    const error = appErrorOf(() =>
      validateCustomShares(1_000, [
        { userId: 'u-awa', shareAmount: 1_000 },
        { userId: 'u-binta', shareAmount },
      ]),
    );
    expect(error.code).toBe('INVALID_SHARE');
  });

  it('refuse un participant répété', () => {
    const error = appErrorOf(() =>
      validateCustomShares(1_000, [
        { userId: 'u-awa', shareAmount: 500 },
        { userId: 'u-awa', shareAmount: 500 },
      ]),
    );
    expect(error.code).toBe('DUPLICATE_PARTICIPANT');
  });
});

describe('Dépense complète : périmètre du groupe et payeur', () => {
  it('calcule les parts quand le payeur participe', () => {
    const shares = computeExpenseShares({
      amount: 10_000,
      payerId: 'u-awa',
      split: { mode: 'equal', participantIds: ['u-cherif', 'u-binta', 'u-awa'] },
      members,
    });
    expect(shares).toEqual([
      { userId: 'u-awa', shareAmount: 3_334 },
      { userId: 'u-binta', shareAmount: 3_333 },
      { userId: 'u-cherif', shareAmount: 3_333 },
    ]);
  });

  it('accepte un sous-groupe de membres', () => {
    const shares = computeExpenseShares({
      amount: 5_001,
      payerId: 'u-binta',
      split: { mode: 'equal', participantIds: ['u-binta', 'u-cherif'] },
      members,
    });
    expect(shares).toEqual([
      { userId: 'u-binta', shareAmount: 2_501 },
      { userId: 'u-cherif', shareAmount: 2_500 },
    ]);
  });

  it('valide un partage personnalisé', () => {
    const shares = computeExpenseShares({
      amount: 9_000,
      payerId: 'u-binta',
      split: {
        mode: 'custom',
        shares: [
          { userId: 'u-awa', shareAmount: 2_000 },
          { userId: 'u-binta', shareAmount: 4_000 },
          { userId: 'u-cherif', shareAmount: 3_000 },
        ],
      },
      members,
    });
    expect(sum(shares.map((s) => s.shareAmount))).toBe(9_000);
  });

  it('départage des homonymes par l\'ordre du groupe, pas par l\'ordre envoyé', () => {
    const first = { userId: 'u-1', displayName: 'Awa' };
    const second = { userId: 'u-2', displayName: 'Awa' };
    const shares = computeExpenseShares({
      amount: 3,
      payerId: 'u-1',
      split: { mode: 'equal', participantIds: ['u-2', 'u-1'] },
      members: [first, second],
    });
    expect(shares).toEqual([
      { userId: 'u-1', shareAmount: 2 },
      { userId: 'u-2', shareAmount: 1 },
    ]);
  });

  it('refuse un payeur qui n\'est pas membre du groupe', () => {
    const error = appErrorOf(() =>
      computeExpenseShares({
        amount: 1_000,
        payerId: 'u-intrus',
        split: { mode: 'equal', participantIds: ['u-awa', 'u-intrus'] },
        members,
      }),
    );
    expect(error.statusCode).toBe(422);
    expect(error.code).toBe('PAYER_NOT_MEMBER');
  });

  it('refuse un participant qui n\'est pas membre du groupe', () => {
    const error = appErrorOf(() =>
      computeExpenseShares({
        amount: 1_000,
        payerId: 'u-awa',
        split: { mode: 'equal', participantIds: ['u-awa', 'u-intrus'] },
        members,
      }),
    );
    expect(error.code).toBe('PARTICIPANT_NOT_MEMBER');
    expect(error.details).toEqual([{ path: 'participants', userId: 'u-intrus' }]);
  });

  it('refuse une dépense dont le payeur ne participe pas (réponse Q28)', () => {
    const error = appErrorOf(() =>
      computeExpenseShares({
        amount: 1_000,
        payerId: 'u-awa',
        split: { mode: 'equal', participantIds: ['u-binta', 'u-cherif'] },
        members,
      }),
    );
    expect(error.code).toBe('PAYER_NOT_PARTICIPANT');
  });

  it('refuse une liste de participants vide', () => {
    const error = appErrorOf(() =>
      computeExpenseShares({ amount: 1_000, payerId: 'u-awa', split: { mode: 'equal', participantIds: [] }, members }),
    );
    expect(error.code).toBe('EMPTY_PARTICIPANTS');
  });

  it('refuse un montant décimal avant tout autre contrôle', () => {
    const error = appErrorOf(() =>
      computeExpenseShares({
        amount: 1_000.5,
        payerId: 'u-awa',
        split: { mode: 'equal', participantIds: ['u-awa'] },
        members,
      }),
    );
    expect(error.code).toBe('INVALID_AMOUNT');
  });
});
