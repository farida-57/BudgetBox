export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly code: string,
    message: string,
    public readonly details: unknown[] = [],
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export const badRequest = (message: string, details: unknown[] = []) =>
  new AppError(400, 'BAD_REQUEST', message, details);

export const unauthorized = (message = 'Authentification requise') =>
  new AppError(401, 'UNAUTHORIZED', message);

export const forbidden = (message = 'Accès refusé') =>
  new AppError(403, 'FORBIDDEN', message);

export const notFound = (message = 'Ressource introuvable', code = 'NOT_FOUND') =>
  new AppError(404, code, message);

export const conflict = (message: string, code = 'CONFLICT') =>
  new AppError(409, code, message);

export const unprocessable = (message: string, code = 'UNPROCESSABLE_ENTITY', details: unknown[] = []) =>
  new AppError(422, code, message, details);

export const tooManyRequests = (message = 'Trop de tentatives, réessayez plus tard') =>
  new AppError(429, 'TOO_MANY_REQUESTS', message);
