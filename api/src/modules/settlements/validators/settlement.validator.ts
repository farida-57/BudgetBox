import { z } from 'zod';

const objectIdLike = z.string().min(1);

export const settlementGroupParamsSchema = z.object({ groupId: objectIdLike }).strict();

export const settlementParamsSchema = z
  .object({ groupId: objectIdLike, settlementId: objectIdLike })
  .strict();

export const createSettlementSchema = z
  .object({
    toUserId: objectIdLike,
    amount: z
      .number({ invalid_type_error: 'Le montant doit être un nombre' })
      .int('Le montant doit être un entier (XOF)')
      .positive('Le montant doit être supérieur à 0')
      .max(1_000_000_000, 'Montant trop élevé'),
  })
  .strict();

export type CreateSettlementInput = z.infer<typeof createSettlementSchema>;
