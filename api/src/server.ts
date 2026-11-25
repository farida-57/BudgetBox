import mongoose from 'mongoose';
import { createApp } from './app';
import { env } from './config/environment';

async function main() {
  await mongoose.connect(env.MONGODB_URI);
  console.log('[db] Connecté à MongoDB');

  const app = createApp();
  app.listen(env.PORT, () => {
    console.log(`[api] BudgetBox API à l'écoute sur http://localhost:${env.PORT}/api/v1`);
  });
}

main().catch((err) => {
  console.error('[api] Échec du démarrage', err);
  process.exit(1);
});
