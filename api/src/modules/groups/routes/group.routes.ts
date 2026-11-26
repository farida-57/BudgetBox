import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { requireAuth } from '../../../shared/auth/auth.middleware';
import { validate } from '../../../shared/validation/zod';
import { GroupController } from '../controllers/group.controller';
import {
  createGroupSchema,
  groupIdParamsSchema,
  invitationParamsSchema,
  memberParamsSchema,
  updateGroupSchema,
} from '../validators/group.validator';

const invitationRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { error: { code: 'TOO_MANY_REQUESTS', message: 'Trop de tentatives, réessayez plus tard', details: [] } },
});

export function groupRoutes() {
  const router = Router();
  const controller = new GroupController();

  router.get('/', requireAuth, controller.list);
  router.post('/', requireAuth, validate({ body: createGroupSchema }), controller.create);
  router.get('/:groupId', requireAuth, validate({ params: groupIdParamsSchema }), controller.get);
  router.patch('/:groupId', requireAuth, validate({ params: groupIdParamsSchema, body: updateGroupSchema }), controller.update);
  router.get('/:groupId/members', requireAuth, validate({ params: groupIdParamsSchema }), controller.listMembers);
  router.delete(
    '/:groupId/members/:userId',
    requireAuth,
    validate({ params: memberParamsSchema }),
    controller.removeMember,
  );
  router.post(
    '/:groupId/invitations',
    requireAuth,
    invitationRateLimit,
    validate({ params: groupIdParamsSchema }),
    controller.createInvitation,
  );

  return router;
}

export function invitationRoutes() {
  const router = Router();
  const controller = new GroupController();

  router.post(
    '/:token/accept',
    requireAuth,
    invitationRateLimit,
    validate({ params: invitationParamsSchema }),
    controller.acceptInvitation,
  );

  return router;
}
