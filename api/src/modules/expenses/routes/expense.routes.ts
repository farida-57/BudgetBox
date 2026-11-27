import { Router } from 'express';
import { requireAuth } from '../../../shared/auth/auth.middleware';
import { validate } from '../../../shared/validation/zod';
import { ExpenseController } from '../controllers/expense.controller';
import { createExpenseSchema, groupIdParamsSchema } from '../validators/expense.validator';

export function expenseRoutes() {
  const router = Router({ mergeParams: true });
  const controller = new ExpenseController();

  router.post(
    '/',
    requireAuth,
    validate({ params: groupIdParamsSchema, body: createExpenseSchema }),
    controller.create,
  );

  return router;
}