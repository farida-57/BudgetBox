import { Schema, model, type InferSchemaType, type HydratedDocument } from 'mongoose';

const sessionSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    tokenHash: { type: String, required: true, unique: true },
    expiresAt: { type: Date, required: true },
    revokedAt: { type: Date, default: null },
  },
  { timestamps: true },
);

sessionSchema.index({ userId: 1, revokedAt: 1 });

export type SessionDocument = HydratedDocument<InferSchemaType<typeof sessionSchema>>;
export const Session = model('Session', sessionSchema);
