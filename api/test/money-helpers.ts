import { AppError } from '../src/shared/errors/app-error';

/** Exécute `fn` et renvoie l'AppError levée (échoue si aucune erreur métier n'est levée). */
export function appErrorOf(fn: () => unknown): AppError {
  try {
    fn();
  } catch (err) {
    if (err instanceof AppError) {
      return err;
    }
    throw err;
  }
  throw new Error('Une AppError était attendue');
}

export function sum(values: readonly number[]): number {
  return values.reduce((total, value) => total + value, 0);
}
