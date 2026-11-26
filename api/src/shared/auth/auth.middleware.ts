import type { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../../config/environment';
import { unauthorized } from '../errors/app-error';
import { Session } from '../../modules/auth/models/session.model';

export interface AuthUser {
  id: string;
}

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: AuthUser;
      authSessionId?: string;
    }
  }
}

interface AccessTokenPayload {
  sub: string;
  sid: string;
}

/**
 * Vérifie le jeton d'accès Bearer et que la session associée
 * existe toujours et n'est pas révoquée ni expirée.
 */
export async function requireAuth(req: Request, _res: Response, next: NextFunction) {
  try {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      throw unauthorized('Jeton d\'accès manquant');
    }

    let payload: AccessTokenPayload;
    try {
      payload = jwt.verify(header.slice(7), env.JWT_ACCESS_SECRET) as AccessTokenPayload;
    } catch {
      throw unauthorized('Jeton d\'accès invalide ou expiré');
    }

    const session = await Session.findById(payload.sid).select('revokedAt expiresAt').lean();
    if (!session || session.revokedAt || session.expiresAt < new Date()) {
      throw unauthorized('Session révoquée ou expirée');
    }

    req.user = { id: payload.sub };
    req.authSessionId = payload.sid;
    next();
  } catch (err) {
    next(err);
  }
}
