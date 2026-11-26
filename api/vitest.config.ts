import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    env: {
      NODE_ENV: 'test',
      PORT: '3100',
      MONGODB_URI: 'mongodb://localhost:27017/budgetbox-test',
      JWT_ACCESS_SECRET: 'test-secret-key-with-at-least-32-characters',
      ACCESS_TOKEN_TTL: '15m',
      REFRESH_TOKEN_TTL_DAYS: '30',
      INVITATION_TTL_HOURS: '168',
      CORS_ORIGIN: '*',
    },
  },
});
