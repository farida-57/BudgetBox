import { Router, type Request, type Response, type NextFunction } from 'express';
import { z } from 'zod';
import { HttpError, SettlementService } from './settlement.service.js';

// The auth module must set req.user.id. Group/balance access is injected so this module
// can be wired to the team's actual Group and Balance models without trusting client IDs.
const bodySchema = z.object({ fromUserId: z.string(), toUserId: z.string(), amount: z.number().int().positive().safe() }).strict();
const querySchema = z.object({ page: z.coerce.number().int().positive().default(1), limit: z.coerce.number().int().positive().max(50).default(20), memberId: z.string().optional(), from: z.coerce.date().optional(), to: z.coerce.date().optional(), category: z.string().optional(), payerId: z.string().optional(), type: z.enum(['expense', 'settlement']).optional() }).strict();
type AuthRequest = Request & { user?: { id: string } };
export function settlementRouter(service: SettlementService) {
  const router = Router();
  const handler = (fn: (req: AuthRequest, res: Response) => Promise<unknown>) => (req: Request, res: Response, next: NextFunction) => { fn(req as AuthRequest, res).catch(next); };
  const actor = (req: AuthRequest) => { if (!req.user?.id) throw new HttpError(401, 'Authentification requise.'); return req.user.id; };
  const pathParam = (req: Request, name: string) => {
    const value = req.params[name];
    return (Array.isArray(value) ? value[0] : value) ?? '';
  };
  router.post('/groups/:groupId/settlements', handler(async (req, res) => { const body = bodySchema.parse(req.body); res.status(201).json({ data: await service.create(pathParam(req, 'groupId'), actor(req), body.fromUserId, body.toUserId, body.amount) }); }));
  router.post('/groups/:groupId/settlements/:id/confirm', handler(async (req, res) => { res.json({ data: await service.confirm(pathParam(req, 'groupId'), pathParam(req, 'id'), actor(req)) }); }));
  router.get('/groups/:groupId/settlements', handler(async (req, res) => { const query = querySchema.parse(req.query); res.json({ data: await service.list(pathParam(req, 'groupId'), actor(req), query) }); }));
  router.get('/groups/:groupId/activity', handler(async (req, res) => { const query = querySchema.parse(req.query); res.json({ data: await service.activity(pathParam(req, 'groupId'), actor(req), query) }); }));
  router.use((error: unknown, _req: Request, res: Response, _next: NextFunction) => {
    if (error instanceof z.ZodError) return res.status(422).json({ error: { code: 'VALIDATION_ERROR', message: 'Données invalides.', details: error.flatten() } });
    const e = error as Error & { status?: number };
    return res.status(e.status ?? 500).json({ error: { code: e.status ? 'SETTLEMENT_ERROR' : 'INTERNAL_ERROR', message: e.status ? e.message : 'Erreur interne.' } });
  });
  return router;
}
