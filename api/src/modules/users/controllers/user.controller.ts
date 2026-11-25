import type { NextFunction, Request, Response } from 'express';
import { UserService, type updateMeSchema } from '../services/user.service';
import type { z } from 'zod';

const userService = new UserService();

export class UserController {
  async getMe(req: Request, res: Response, next: NextFunction) {
    try {
      const user = await userService.getMe(req.user!.id);
      res.status(200).json(user);
    } catch (err) {
      next(err);
    }
  }

  async updateMe(req: Request, res: Response, next: NextFunction) {
    try {
      const body = req.validated?.body as z.infer<typeof updateMeSchema>;
      const user = await userService.updateMe(req.user!.id, body);
      res.status(200).json(user);
    } catch (err) {
      next(err);
    }
  }
}
