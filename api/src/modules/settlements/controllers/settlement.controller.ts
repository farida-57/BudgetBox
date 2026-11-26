import type { NextFunction, Request, Response } from 'express';
import { SettlementService } from '../services/settlement.service';
import type { CreateSettlementInput } from '../validators/settlement.validator';

const settlementService = new SettlementService();

function body<T>(req: Request): T {
  return req.validated?.body as T;
}

function params<T>(req: Request): T {
  return req.validated?.params as T;
}

export class SettlementController {
  async create(req: Request, res: Response, next: NextFunction) {
    try {
      const { groupId } = params<{ groupId: string }>(req);
      const settlement = await settlementService.createSettlement(
        groupId,
        req.user!.id,
        body<CreateSettlementInput>(req),
      );
      res.status(201).json(settlement);
    } catch (err) {
      next(err);
    }
  }

  async list(req: Request, res: Response, next: NextFunction) {
    try {
      const { groupId } = params<{ groupId: string }>(req);
      const status = typeof req.query.status === 'string' ? req.query.status : undefined;
      const settlements = await settlementService.listSettlements(groupId, req.user!.id, status);
      res.status(200).json(settlements);
    } catch (err) {
      next(err);
    }
  }

  async confirm(req: Request, res: Response, next: NextFunction) {
    try {
      const { groupId, settlementId } = params<{ groupId: string; settlementId: string }>(req);
      const settlement = await settlementService.confirmSettlement(groupId, settlementId, req.user!.id);
      res.status(200).json(settlement);
    } catch (err) {
      next(err);
    }
  }
}
