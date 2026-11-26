import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { requireAuth } from '../../../shared/auth/auth.middleware';
import { validate } from '../../../shared/validation/zod';
import { AuthController } from '../controllers/auth.controller';
import { loginSchema, refreshSchema, registerSchema } from '../validators/auth.validator';

const authRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 30,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { error: { code: 'TOO_MANY_REQUESTS', message: 'Trop de tentatives, réessayez plus tard', details: [] } },
});

export function authRoutes() {
  const router = Router();
  const controller = new AuthController();

  router.post('/register', authRateLimit, validate({ body: registerSchema }), controller.register);
  router.post('/login', authRateLimit, validate({ body: loginSchema }), controller.login);
  router.post('/refresh', authRateLimit, validate({ body: refreshSchema }), controller.refresh);
  router.post('/logout', requireAuth, controller.logout);

  return router;
}
