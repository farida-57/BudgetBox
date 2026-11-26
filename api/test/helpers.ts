import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose from 'mongoose';
import request from 'supertest';
import { createApp } from '../src/app';

let mongo: MongoMemoryServer | undefined;

export const api = request(createApp());

export async function startMemoryDb() {
  mongo = await MongoMemoryServer.create();
  await mongoose.connect(mongo.getUri());
}

export async function stopMemoryDb() {
  await mongoose.disconnect();
  await mongo?.stop();
}

export async function cleanDb() {
  const collections = await mongoose.connection.db?.collections() ?? [];
  await Promise.all(collections.map((c) => c.deleteMany({})));
}

export interface TestUser {
  accessToken: string;
  refreshToken: string;
  user: { id: string; displayName: string; email: string };
}

let counter = 0;

export async function registerUser(overrides: Partial<{ displayName: string; email: string; password: string }> = {}): Promise<TestUser> {
  counter += 1;
  const email = overrides.email ?? `user${counter}-${Date.now()}@example.com`;
  const res = await api.post('/api/v1/auth/register').send({
    displayName: overrides.displayName ?? `Utilisateur ${counter}`,
    email,
    password: overrides.password ?? 'motdepasse123',
  });
  if (res.status !== 201) {
    throw new Error(`registerUser a échoué: ${res.status} ${JSON.stringify(res.body)}`);
  }
  return {
    accessToken: res.body.tokens.accessToken,
    refreshToken: res.body.tokens.refreshToken,
    user: res.body.user,
  };
}

export function authHeader(token: string) {
  return { Authorization: `Bearer ${token}` };
}
