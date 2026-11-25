import express from 'express';
import { settlementRouter } from './modules/settlements/settlement.routes.js';
import { SettlementService } from './modules/settlements/settlement.service.js';
import { settlementContext } from './modules/settlements/settlement.context.js';

export const app = express();
app.use(express.json({ limit: '1mb' }));
// TODO Membre 2: replace this development auth adapter with the real JWT middleware.
app.use('/api/v1', (req: any, _res, next) => {
  const id = req.header('x-user-id');
  if (id) req.user = { id };
  next();
});
app.use('/api/v1', settlementRouter(new SettlementService(settlementContext)));
app.use((_req, res) => res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Route introuvable.' } }));
