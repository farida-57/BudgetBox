import { Schema, model, type InferSchemaType, type HydratedDocument } from 'mongoose';

const userSchema = new Schema(
  {
    displayName: { type: String, required: true, trim: true, minlength: 1, maxlength: 100 },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    passwordHash: { type: String, required: true, select: false },
  },
  { timestamps: true },
);

export type UserDocument = HydratedDocument<InferSchemaType<typeof userSchema>>;
export const User = model('User', userSchema);
