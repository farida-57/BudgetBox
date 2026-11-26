import type { NextFunction, Request, Response } from 'express';
import { BalanceService } from '../services/balance.service';

const balanceService = new BalanceService();

function params<T>(req: Request): T {
  return req.validated?.params as T;
}

export class BalanceController {
  /** GET /groups/:groupId/balances */
  async getBalances(req: Request, res: Response, next: NextFunction) {
    try {
      const { groupId } = params<{ groupId: string }>(req);
      // L'identité vient du jeton vérifié par requireAuth, jamais du corps ou de la query.
      const balances = await balanceService.getBalances(groupId, req.user!.id);
      res.status(200).json(balances);
    } catch (err) {
      next(err);
    }
  }

  /** GET /groups/:groupId/settlement-suggestions (lecture seule) */
  async getSettlementSuggestions(req: Request, res: Response, next: NextFunction) {
    try {
      const { groupId } = params<{ groupId: string }>(req);
      const suggestions = await balanceService.getSettlementSuggestions(groupId, req.user!.id);
      res.status(200).json(suggestions);
    } catch (err) {
      next(err);
    }
  }
}
