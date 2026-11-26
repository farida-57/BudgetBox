import { randomBytes } from 'node:crypto';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { env } from '../../../config/environment';
import { conflict, unauthorized } from '../../../shared/errors/app-error';
import { sha256 } from '../../../shared/utils/hash';
import { User, type UserDocument } from '../../users/models/user.model';
import { Session } from '../models/session.model';
import type { LoginInput, RefreshInput, RegisterInput } from '../validators/auth.validator';

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  accessTokenExpiresIn: string;
}

export interface AuthPayload {
  user: {
    id: string;
    displayName: string;
    email: string;
    createdAt: Date;
  };
  tokens: AuthTokens;
}

function toPublicUser(user: UserDocument) {
  return {
    id: user._id.toString(),
    displayName: user.displayName,
    email: user.email,
    createdAt: user.createdAt,
  };
}

async function createSession(userId: string): Promise<AuthTokens> {
  const refreshToken = randomBytes(48).toString('base64url');
  const session = await Session.create({
    userId,
    tokenHash: sha256(refreshToken),
    expiresAt: new Date(Date.now() + env.REFRESH_TOKEN_TTL_DAYS * 24 * 60 * 60 * 1000),
  });

  const accessToken = jwt.sign({ sub: userId, sid: session._id.toString() }, env.JWT_ACCESS_SECRET, {
    expiresIn: env.ACCESS_TOKEN_TTL as jwt.SignOptions['expiresIn'],
  });

  return { accessToken, refreshToken, accessTokenExpiresIn: env.ACCESS_TOKEN_TTL };
}

export class AuthService {
  async register(input: RegisterInput): Promise<AuthPayload> {
    const existing = await User.findOne({ email: input.email }).select('_id').lean();
    if (existing) {
      throw conflict('Cette adresse courriel est déjà utilisée', 'EMAIL_TAKEN');
    }

    const passwordHash = await bcrypt.hash(input.password, 10);
    const user = await User.create({
      displayName: input.displayName,
      email: input.email,
      passwordHash,
    });

    const tokens = await createSession(user._id.toString());
    return { user: toPublicUser(user), tokens };
  }

  async login(input: LoginInput): Promise<AuthPayload> {
    const user = await User.findOne({ email: input.email }).select('+passwordHash');
    if (!user) {
      throw unauthorized('Identifiants invalides');
    }

    const ok = await bcrypt.compare(input.password, user.passwordHash);
    if (!ok) {
      throw unauthorized('Identifiants invalides');
    }

    const tokens = await createSession(user._id.toString());
    return { user: toPublicUser(user), tokens };
  }

  async refresh(input: RefreshInput): Promise<AuthPayload> {
    const tokenHash = sha256(input.refreshToken);
    const session = await Session.findOne({ tokenHash });

    if (!session) {
      throw unauthorized('Jeton de rafraîchissement invalide');
    }

    if (session.revokedAt) {
      // Réutilisation d'un jeton déjà renouvelé/révoqué : on révoque toutes les sessions de l'utilisateur.
      await Session.updateMany({ userId: session.userId, revokedAt: null }, { revokedAt: new Date() });
      throw unauthorized('Jeton de rafraîchissement réutilisé');
    }

    if (session.expiresAt < new Date()) {
      throw unauthorized('Jeton de rafraîchissement expiré');
    }

    const user = await User.findById(session.userId);
    if (!user) {
      throw unauthorized('Compte introuvable');
    }

    // Rotation : l'ancien jeton est révoqué, une nouvelle session est créée.
    session.revokedAt = new Date();
    await session.save();

    const tokens = await createSession(user._id.toString());
    return { user: toPublicUser(user), tokens };
  }

  async logout(sessionId: string): Promise<void> {
    await Session.updateOne({ _id: sessionId, revokedAt: null }, { revokedAt: new Date() });
  }

  async getMe(userId: string) {
    const user = await User.findById(userId);
    if (!user) {
      throw unauthorized('Compte introuvable');
    }
    return toPublicUser(user);
  }
}
