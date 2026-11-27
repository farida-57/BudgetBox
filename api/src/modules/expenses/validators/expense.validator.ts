import { z } from 'zod';

const objectId = z.string().regex(/^[a-f\d]{24}$/i, 'Identifiant invalide');

export const groupIdParamsSchema = z.object({ groupId: objectId }).strict();

export const createExpenseSchema = z
  .object({
    label: z.string().trim().min(1, 'Le libellé est requis').max(100),
    amount: z.number().int('Le montant doit être un entier').positive('Le montant doit être positif'),
    payerId: objectId,
    category: z.string().trim().min(1, 'La catégorie est requise').max(40),
    date: z.coerce
      .date()
      .refine((d) => d.getTime() <= Date.now(), 'La date ne peut pas être dans le futur')
      .optional(),
    note: z.string().trim().max(500).optional(),
    split: z.discriminatedUnion('type', [
      z
        .object({
          type: z.literal('equal'),
          participantIds: z.array(objectId).min(1, 'Au moins un participant'),
        })
        .strict(),
      z
        .object({
          type: z.literal('custom'),
          shares: z
            .array(
              z
                .object({
                  userId: objectId,
                  amount: z.number().int('Part entière requise').min(0, 'Part négative interdite'),
                })
                .strict(),
            )
            .min(1, 'Au moins un participant'),
        })
        .strict(),
    ]),
  })
  .strict();

export type CreateExpenseInput = z.infer<typeof createExpenseSchema>;