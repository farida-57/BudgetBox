import { z } from 'zod';

const objectIdLike = z.string().min(1);

export const groupIdParamsSchema = z.object({ groupId: objectIdLike }).strict();
export const memberParamsSchema = z
  .object({ groupId: objectIdLike, userId: objectIdLike })
  .strict();
export const invitationParamsSchema = z.object({ token: z.string().min(1) }).strict();

export const createGroupSchema = z
  .object({
    name: z.string().trim().min(1, 'Le nom du groupe est requis').max(100),
    currency: z.enum(['XOF']).default('XOF'),
  })
  .strict();

export const updateGroupSchema = z
  .object({
    name: z.string().trim().min(1).max(100).optional(),
  })
  .strict();

export type CreateGroupInput = z.infer<typeof createGroupSchema>;
export type UpdateGroupInput = z.infer<typeof updateGroupSchema>;
