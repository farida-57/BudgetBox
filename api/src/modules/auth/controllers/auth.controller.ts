import type { NextFunction, Request, Response } from 'express';
import { AuthService } from '../services/auth.service';
import type { LoginInput, RefreshInput, RegisterInput } from '../validators/auth.validator';

const authService = new AuthService();

function body<T>(req: Request): T {
  return req.validated?.body as T;
}

export class AuthController {
  async register(req: Request, res: Response, next: NextFunction) {
    try {
      const payload = await authService.register(body<RegisterInput>(req));
      res.status(201).json(payload);
    } catch (err) {
      next(err);
    }
  }

  async login(req: Request, res: Response, next: NextFunction) {
    try {
      const payload = await authService.login(body<LoginInput>(req));
      res.status(200).json(payload);
    } catch (err) {
      next(err);
    }
  }

  async refresh(req: Request, res: Response, next: NextFunction) {
    try {
      const payload = await authService.refresh(body<RefreshInput>(req));
      res.status(200).json(payload);
    } catch (err) {
      next(err);
    }
  }

  async logout(req: Request, res: Response, next: NextFunction) {
    try {
      if (req.authSessionId) {
        await authService.logout(req.authSessionId);
      }
      res.status(204).end();
    } catch (err) {
      next(err);
    }
  }
}
