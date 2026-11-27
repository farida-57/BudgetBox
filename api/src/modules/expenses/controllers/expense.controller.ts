import type { NextFunction, Request, Response } from 'express';
import { ExpenseService } from '../services/expense.service';
import type { CreateExpenseInput } from '../validators/expense.validator';

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
}