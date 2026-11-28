import { z } from 'zod';
import { xofAmountSchema } from '../../../shared/money/xof';

const id = z.string().min(1);
export const settlementGroupParamsSchema = z.object({ groupId: id }).strict();
export const settlementParamsSchema = z.object({ groupId: id, settlementId: id }).strict();
export const createSettlementSchema = z.object({ fromUserId: id, toUserId: id, amount: xofAmountSchema }).strict().refine(
  (value) => value.fromUserId !== value.toUserId,
  { message: 'Le payeur et le destinataire doivent être différents', path: ['toUserId'] },
);
export const historyQuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(50).default(20),
  memberId: id.optional(), payerId: id.optional(), category: z.string().trim().min(1).optional(),
  type: z.enum(['expense', 'settlement']).optional(), from: z.coerce.date().optional(), to: z.coerce.date().optional(),
}).strict().refine((q) => !q.from || !q.to || q.from <= q.to, {
  message: 'La date de début doit précéder la date de fin', path: ['from'],
}).refine((q) => !(q.type === 'settlement' && (q.payerId || q.category)), {
  message: 'Payeur et catégorie filtrent uniquement les dépenses', path: ['type'],
});
export type CreateSettlementInput = z.infer<typeof createSettlementSchema>;
export type HistoryQuery = z.infer<typeof historyQuerySchema>;
