import { Router } from 'express';
import { requireAuth } from '../../../shared/auth/auth.middleware';
import { validate } from '../../../shared/validation/zod';
import { SettlementController } from '../controllers/settlement.controller';
import {
  createSettlementSchema, historyQuerySchema, settlementGroupParamsSchema, settlementParamsSchema,
} from '../validators/settlement.validator';

export function settlementRoutes() {
  const router = Router();
  const controller = new SettlementController();
  router.post('/:groupId/settlements', requireAuth, validate({ params: settlementGroupParamsSchema, body: createSettlementSchema }), controller.create);
  router.post('/:groupId/settlements/:settlementId/confirm', requireAuth, validate({ params: settlementParamsSchema }), controller.confirm);
  router.get('/:groupId/settlements', requireAuth, validate({ params: settlementGroupParamsSchema, query: historyQuerySchema }), controller.list);
  router.get('/:groupId/activity', requireAuth, validate({ params: settlementGroupParamsSchema, query: historyQuerySchema }), controller.activity);
  return router;
}
