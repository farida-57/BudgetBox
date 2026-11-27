import type { NextFunction, Request, Response } from 'express';
import { ExpenseService } from '../services/expense.service';
import type { CreateExpenseInput, ListExpensesQuery } from '../validators/expense.validator';

export class ExpenseController {
  private readonly service = new ExpenseService();

  create = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { groupId } = req.validated!.params as { groupId: string };
      const expense = await this.service.createExpense(
        groupId,
        req.user!.id,
        req.validated!.body as CreateExpenseInput,
      );
      res.status(201).json(expense);
    } catch (err) {
      next(err);
    }
  };

  list = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { groupId } = req.validated!.params as { groupId: string };
      const result = await this.service.listExpenses(
        groupId,
        req.user!.id,
        req.validated!.query as ListExpensesQuery,
      );
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  };
}