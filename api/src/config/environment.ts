import { z } from 'zod';

try {
  process.loadEnvFile();
} catch {
  // .env absent : on utilise les variables d'environnement du système
}

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  MONGODB_URI: z.string().min(1, 'MONGODB_URI est requis'),
  JWT_ACCESS_SECRET: z.string().min(32, 'JWT_ACCESS_SECRET doit faire au moins 32 caractères'),
  ACCESS_TOKEN_TTL: z.string().default('15m'),
  REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().positive().default(30),
  INVITATION_TTL_HOURS: z.coerce.number().int().positive().default(168),
  CORS_ORIGIN: z.string().default('*'),
});

export const env = envSchema.parse(process.env);
export type Env = z.infer<typeof envSchema>;
