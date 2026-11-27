import { Router } from 'express';
import { requireAuth } from '../../../shared/auth/auth.middleware';
import { validate } from '../../../shared/validation/zod';
import { ExpenseController } from '../controllers/expense.controller';
import {
  createExpenseSchema,
  groupIdParamsSchema,
  listExpensesQuerySchema,
} from '../validators/expense.validator';

export function expenseRoutes() {
  const router = Router({ mergeParams: true });
  const controller = new ExpenseController();

  router.get(
    '/',
    requireAuth,
    validate({ params: groupIdParamsSchema, query: listExpensesQuerySchema }),
    controller.list,
  );
  router.post(
    '/',
    requireAuth,
    validate({ params: groupIdParamsSchema, body: createExpenseSchema }),
    controller.create,
  );

  return router;
}