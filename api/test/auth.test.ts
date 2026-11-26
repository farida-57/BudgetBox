import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { api, authHeader, cleanDb, registerUser, startMemoryDb, stopMemoryDb } from './helpers';

beforeAll(startMemoryDb);
afterAll(stopMemoryDb);
beforeEach(cleanDb);

describe('POST /auth/register', () => {
  it('crée un utilisateur et retourne les jetons (201)', async () => {
    const res = await api.post('/api/v1/auth/register').send({
      displayName: 'Awa Diallo',
      email: 'awa@example.com',
      password: 'motdepasse123',
    });

    expect(res.status).toBe(201);
    expect(res.body.user.email).toBe('awa@example.com');
    expect(res.body.user.passwordHash).toBeUndefined();
    expect(res.body.tokens.accessToken).toBeTruthy();
    expect(res.body.tokens.refreshToken).toBeTruthy();
  });

  it('refuse un courriel déjà utilisé (409)', async () => {
    await api.post('/api/v1/auth/register').send({
      displayName: 'Awa',
      email: 'awa@example.com',
      password: 'motdepasse123',
    });

    const res = await api.post('/api/v1/auth/register').send({
      displayName: 'Awa Bis',
      email: 'awa@example.com',
      password: 'autrepass456',
    });

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('EMAIL_TAKEN');
  });

  it('refuse des champs invalides (422)', async () => {
    const res = await api.post('/api/v1/auth/register').send({
      displayName: '',
      email: 'pas-un-courriel',
      password: 'court',
    });
    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });
});

describe('POST /auth/login', () => {
  it('connecte avec les bons identifiants (200)', async () => {
    await api.post('/api/v1/auth/register').send({
      displayName: 'Binta',
      email: 'binta@example.com',
      password: 'motdepasse123',
    });

    const res = await api.post('/api/v1/auth/login').send({
      email: 'binta@example.com',
      password: 'motdepasse123',
    });

    expect(res.status).toBe(200);
    expect(res.body.tokens.accessToken).toBeTruthy();
  });

  it('refuse un mauvais mot de passe (401)', async () => {
    await api.post('/api/v1/auth/register').send({
      displayName: 'Binta',
      email: 'binta@example.com',
      password: 'motdepasse123',
    });

    const res = await api.post('/api/v1/auth/login').send({
      email: 'binta@example.com',
      password: 'mauvaismdp',
    });
    expect(res.status).toBe(401);
  });

  it('refuse un courriel inconnu (401)', async () => {
    const res = await api.post('/api/v1/auth/login').send({
      email: 'inconnu@example.com',
      password: 'motdepasse123',
    });
    expect(res.status).toBe(401);
  });
});

describe('POST /auth/refresh — rotation', () => {
  it('renouvelle les jetons et révoque l\'ancien refresh token', async () => {
    const user = await registerUser();

    const res = await api.post('/api/v1/auth/refresh').send({ refreshToken: user.refreshToken });
    expect(res.status).toBe(200);
    expect(res.body.tokens.refreshToken).not.toBe(user.refreshToken);

    // Réutilisation de l'ancien jeton → 401
    const reuse = await api.post('/api/v1/auth/refresh').send({ refreshToken: user.refreshToken });
    expect(reuse.status).toBe(401);
  });

  it('refuse un refresh token inconnu (401)', async () => {
    const res = await api.post('/api/v1/auth/refresh').send({ refreshToken: 'inconnu' });
    expect(res.status).toBe(401);
  });
});

describe('POST /auth/logout', () => {
  it('révoque la session : le refresh token devient inutilisable', async () => {
    const user = await registerUser();

    const logout = await api.post('/api/v1/auth/logout').set(authHeader(user.accessToken));
    expect(logout.status).toBe(204);

    const refresh = await api.post('/api/v1/auth/refresh').send({ refreshToken: user.refreshToken });
    expect(refresh.status).toBe(401);
  });

  it('refuse sans jeton (401)', async () => {
    const res = await api.post('/api/v1/auth/logout');
    expect(res.status).toBe(401);
  });
});

describe('GET /users/me', () => {
  it('retourne le profil de l\'utilisateur connecté', async () => {
    const user = await registerUser({ displayName: 'Chérif' });

    const res = await api.get('/api/v1/users/me').set(authHeader(user.accessToken));
    expect(res.status).toBe(200);
    expect(res.body.displayName).toBe('Chérif');
    expect(res.body.passwordHash).toBeUndefined();
  });

  it('refuse sans jeton (401)', async () => {
    const res = await api.get('/api/v1/users/me');
    expect(res.status).toBe(401);
  });
});
