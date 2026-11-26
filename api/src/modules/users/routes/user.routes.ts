import { Router } from 'express';
import { requireAuth } from '../../../shared/auth/auth.middleware';
import { validate } from '../../../shared/validation/zod';
import { UserController } from '../controllers/user.controller';
import { updateMeSchema } from '../services/user.service';

export function userRoutes() {
  const router = Router();
  const controller = new UserController();

  router.get('/me', requireAuth, controller.getMe);
  router.patch('/me', requireAuth, validate({ body: updateMeSchema }), controller.updateMe);

  return router;
}
