import { Router } from 'express';
import { requireAuth } from '../../../shared/auth/auth.middleware';
import { validate } from '../../../shared/validation/zod';
import { groupIdParamsSchema } from '../../groups/validators/group.validator';
import { BalanceController } from '../controllers/balance.controller';

/**
 * Routes montées sous `/api/v1/groups`, après celles du module groupes.
 * Uniquement des lectures (GET) : aucun solde n'est reçu de l'application.
 */
export function balanceRoutes() {
  const router = Router();
  const controller = new BalanceController();

  router.get('/:groupId/balances', requireAuth, validate({ params: groupIdParamsSchema }), controller.getBalances);
  router.get(
    '/:groupId/settlement-suggestions',
    requireAuth,
    validate({ params: groupIdParamsSchema }),
    controller.getSettlementSuggestions,
  );

  return router;
}
