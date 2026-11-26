import type { NextFunction, Request, Response } from 'express';
import { ZodError } from 'zod';
import { AppError } from './app-error';

interface ErrorBody {
  error: { code: string; message: string; details: unknown[] };
}

function sendError(res: Response, status: number, body: ErrorBody) {
  res.status(status).json(body);
}

export function errorHandler(err: unknown, _req: Request, res: Response, _next: NextFunction) {
  if (err instanceof AppError) {
    return sendError(res, err.statusCode, {
      error: { code: err.code, message: err.message, details: err.details },
    });
  }

  if (err instanceof ZodError) {
    return sendError(res, 422, {
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Données invalides',
        details: err.issues.map((issue) => ({
          path: issue.path.join('.'),
          message: issue.message,
        })),
      },
    });
  }

  const maybe = err as { type?: string; status?: number; message?: string };
  if (maybe?.type === 'entity.parse.failed' || maybe?.type === 'entity.too.large') {
    return sendError(res, 400, {
      error: { code: 'BAD_REQUEST', message: 'Corps de requête invalide', details: [] },
    });
  }

  if (maybe?.type === 'entity.verify.failed' || maybe?.status === 400) {
    return sendError(res, 400, {
      error: { code: 'BAD_REQUEST', message: maybe.message ?? 'Requête invalide', details: [] },
    });
  }

  console.error('[error]', err);
  return sendError(res, 500, {
    error: { code: 'INTERNAL_ERROR', message: 'Erreur interne du serveur', details: [] },
  });
}

export function notFoundHandler(_req: Request, res: Response) {
  sendError(res, 404, {
    error: { code: 'NOT_FOUND', message: 'Route introuvable', details: [] },
  });
}
