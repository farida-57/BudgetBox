import { z } from 'zod';
import { unauthorized } from '../../../shared/errors/app-error';
import { AuthService } from '../../auth/services/auth.service';
import { User } from '../models/user.model';

const authService = new AuthService();

export const updateMeSchema = z
  .object({
    displayName: z.string().trim().min(1, 'Le nom d\'affichage est requis').max(100),
  })
  .strict();

export class UserService {
  async getMe(userId: string) {
    return authService.getMe(userId);
  }

  async updateMe(userId: string, input: z.infer<typeof updateMeSchema>) {
    const user = await User.findByIdAndUpdate(
      userId,
      { displayName: input.displayName },
      { new: true, runValidators: true },
    );
    if (!user) {
      throw unauthorized('Compte introuvable');
    }
    return {
      id: user._id.toString(),
      displayName: user.displayName,
      email: user.email,
      createdAt: user.createdAt,
    };
  }
}
