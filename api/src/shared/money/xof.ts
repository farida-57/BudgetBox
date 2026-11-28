import { z } from 'zod';
import { AppError, unprocessable } from '../errors/app-error';

/**
 * Règles communes aux montants en francs CFA (XOF).
 *
 * Le XOF n'a pas de sous-unité : un montant est TOUJOURS un entier.
 * On n'utilise jamais de virgule flottante pour l'argent : chaque valeur
 * est vérifiée avec `Number.isSafeInteger`, ce qui refuse NaN, Infinity,
 * les décimales et les entiers trop grands pour être représentés exactement.
 */

/** Plus grand montant représentable exactement par un `number` JavaScript. */
export const MAX_XOF_AMOUNT = Number.MAX_SAFE_INTEGER;

/** Montant de dépense ou de règlement : entier sûr strictement positif. */
export function isXofAmount(value: unknown): value is number {
  return typeof value === 'number' && Number.isSafeInteger(value) && value > 0;
}

/** Part d'un participant : entier sûr positif ou nul. */
export function isXofShare(value: unknown): value is number {
  return typeof value === 'number' && Number.isSafeInteger(value) && value >= 0;
}

export function assertXofAmount(value: unknown, field = 'amount'): number {
  if (!isXofAmount(value)) {
    throw unprocessable('Le montant doit être un entier XOF strictement positif', 'INVALID_AMOUNT', [
      { path: field, message: 'Entier positif sans décimales attendu' },
    ]);
  }
  return value;
}

export function assertXofShare(value: unknown, field = 'shareAmount'): number {
  if (!isXofShare(value)) {
    throw unprocessable('Chaque part doit être un entier XOF positif ou nul', 'INVALID_SHARE', [
      { path: field, message: 'Entier positif ou nul sans décimales attendu' },
    ]);
  }
  return value;
}

/** Erreur levée si une opération sort de la plage des entiers exacts. */
export function amountOutOfRange() {
  return new AppError(422, 'AMOUNT_OUT_OF_RANGE', 'Montant hors de la limite autorisée');
}

/**
 * Addition contrôlée : a et b sont des entiers sûrs ; si le résultat ne l'est plus,
 * il aurait pu être arrondi par le moteur JavaScript, donc on le refuse.
 */
export function addXof(a: number, b: number): number {
  const result = a + b;
  if (!Number.isSafeInteger(a) || !Number.isSafeInteger(b) || !Number.isSafeInteger(result)) {
    throw amountOutOfRange();
  }
  return result;
}

export function subtractXof(a: number, b: number): number {
  return addXof(a, -b);
}

/** Somme contrôlée d'une liste d'entiers XOF. */
export function sumXof(values: readonly number[]): number {
  return values.reduce((total, value) => addXof(total, value), 0);
}

/**
 * Schémas Zod réutilisables par les validateurs des modules (dépenses, règlements).
 * `z.number()` refuse les chaînes ("1000") : aucune conversion implicite.
 */
export const xofAmountSchema = z
  .number({ invalid_type_error: 'Le montant doit être un nombre entier' })
  .int('Le montant doit être un entier (XOF sans décimales)')
  .positive('Le montant doit être strictement positif')
  .max(MAX_XOF_AMOUNT, 'Montant hors de la limite autorisée');

export const xofShareSchema = z
  .number({ invalid_type_error: 'La part doit être un nombre entier' })
  .int('La part doit être un entier (XOF sans décimales)')
  .nonnegative('La part ne peut pas être négative')
  .max(MAX_XOF_AMOUNT, 'Part hors de la limite autorisée');
