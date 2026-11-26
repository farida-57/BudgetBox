import { z } from 'zod';

const emailSchema = z
  .string()
  .trim()
  .email('Adresse courriel invalide')
  .max(254)
  .transform((v) => v.toLowerCase());

const passwordSchema = z
  .string()
  .min(8, 'Le mot de passe doit contenir au moins 8 caractères')
  .max(128);

export const registerSchema = z
  .object({
    displayName: z.string().trim().min(1, 'Le nom d\'affichage est requis').max(100),
    email: emailSchema,
    password: passwordSchema,
  })
  .strict();

export const loginSchema = z
  .object({
    email: emailSchema,
    password: z.string().min(1, 'Le mot de passe est requis'),
  })
  .strict();

export const refreshSchema = z
  .object({
    refreshToken: z.string().min(1, 'Jeton de rafraîchissement requis'),
  })
  .strict();

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type RefreshInput = z.infer<typeof refreshSchema>;
