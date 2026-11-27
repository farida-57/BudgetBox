import type { NextFunction, Request, Response } from 'express';
import { SettlementService } from '../services/settlement.service';
import type { CreateSettlementInput, HistoryQuery } from '../validators/settlement.validator';

const service = new SettlementService();
const params = <T>(req: Request) => req.validated?.params as T;
const body = <T>(req: Request) => req.validated?.body as T;
const query = (req: Request) => req.validated?.query as HistoryQuery;

export class SettlementController {
  async create(req: Request, res: Response, next: NextFunction) {
    try {
      const { groupId } = params<{ groupId: string }>(req);
      res.status(201).json(await service.create(groupId, req.user!.id, body<CreateSettlementInput>(req)));
    } catch (err) { next(err); }
  }
  async confirm(req: Request, res: Response, next: NextFunction) {
    try {
      const { groupId, settlementId } = params<{ groupId: string; settlementId: string }>(req);
      res.status(200).json(await service.confirm(groupId, settlementId, req.user!.id));
    } catch (err) { next(err); }
  }
  async list(req: Request, res: Response, next: NextFunction) {
    try {
      const { groupId } = params<{ groupId: string }>(req);
      res.status(200).json(await service.listSettlements(groupId, req.user!.id, query(req)));
    } catch (err) { next(err); }
  }
  async activity(req: Request, res: Response, next: NextFunction) {
    try {
      const { groupId } = params<{ groupId: string }>(req);
      res.status(200).json(await service.activity(groupId, req.user!.id, query(req)));
    } catch (err) { next(err); }
  }
}
