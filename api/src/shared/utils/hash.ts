import { createHash } from 'node:crypto';

/** Hachage SHA-256 hexadécimal — utilisé pour les jetons de rafraîchissement et invitations. */
export function sha256(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}
