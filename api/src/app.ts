import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import { env } from './config/environment';
import { authRoutes } from './modules/auth/routes/auth.routes';
import { expenseRoutes } from './modules/expenses/routes/expense.routes';
import { groupRoutes, invitationRoutes } from './modules/groups/routes/group.routes';
import { userRoutes } from './modules/users/routes/user.routes';
import { errorHandler, notFoundHandler } from './shared/errors/error-handler';

export function createApp() {
  const app = express();

  app.set('trust proxy', 1);
  app.use(helmet());
  app.use(
    cors({
      origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN.split(',').map((o) => o.trim()),
    }),
  );
  app.use(express.json({ limit: '100kb' }));

  app.get('/health', (_req, res) => {
    res.status(200).json({ status: 'ok' });
  });

  const api = express.Router();
  api.use('/auth', authRoutes());
  api.use('/users', userRoutes());
  api.use('/groups/:groupId/expenses', expenseRoutes());
  api.use('/groups', groupRoutes());
  api.use('/invitations', invitationRoutes());
  app.use('/api/v1', api);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
