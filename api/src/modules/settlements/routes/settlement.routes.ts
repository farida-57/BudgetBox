import { Router } from 'express';
import { requireAuth } from '../../../shared/auth/auth.middleware';
import { validate } from '../../../shared/validation/zod';
import { SettlementController } from '../controllers/settlement.controller';
import {
  createSettlementSchema,
  settlementGroupParamsSchema,
  settlementParamsSchema,
} from '../validators/settlement.validator';

export function settlementRoutes() {
  // mergeParams : récupère :groupId défini dans app.ts
  const router = Router({ mergeParams: true });
  const controller = new SettlementController();

  router.post(
    '/',
    requireAuth,
    validate({ params: settlementGroupParamsSchema, body: createSettlementSchema }),
    controller.create,
  );
  router.get('/', requireAuth, validate({ params: settlementGroupParamsSchema }), controller.list);
  router.post(
    '/:settlementId/confirm',
    requireAuth,
    validate({ params: settlementParamsSchema }),
    controller.confirm,
  );

  return router;
}
