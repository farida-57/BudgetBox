import type { NextFunction, Request, Response } from 'express';
import type { ZodTypeAny } from 'zod';

export interface ValidationSchemas {
  body?: ZodTypeAny;
  params?: ZodTypeAny;
  query?: ZodTypeAny;
}

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      validated?: {
        body?: unknown;
        params?: unknown;
        query?: unknown;
      };
    }
  }
}

/**
 * Valide body/params/query avec des schémas Zod stricts.
 * Les valeurs parsées sont exposées via `req.validated`.
 */
export function validate(schemas: ValidationSchemas) {
  return (req: Request, _res: Response, next: NextFunction) => {
    try {
      req.validated = {
        body: schemas.body ? schemas.body.parse(req.body ?? {}) : undefined,
        params: schemas.params ? schemas.params.parse(req.params) : undefined,
        query: schemas.query ? schemas.query.parse(req.query) : undefined,
      };
      next();
    } catch (err) {
      next(err);
    }
  };
}
