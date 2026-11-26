import { Schema, model, type InferSchemaType, type HydratedDocument } from 'mongoose';

export const SETTLEMENT_STATUSES = ['en_attente', 'confirme'] as const;
export type SettlementStatus = (typeof SETTLEMENT_STATUSES)[number];

const settlementSchema = new Schema(
  {
    groupId: { type: Schema.Types.ObjectId, ref: 'Group', required: true },
    // Celui qui a payé (débiteur)
    fromUserId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    // Celui qui reçoit (créancier) : c'est lui qui confirme
    toUserId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    amount: {
      type: Number,
      required: true,
      min: 1,
      validate: {
        validator: Number.isInteger,
        message: 'Le montant doit être un entier (XOF)',
      },
    },
    status: { type: String, enum: SETTLEMENT_STATUSES, default: 'en_attente' },
    createdBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    confirmedAt: { type: Date, default: null },
  },
  { timestamps: true },
);

settlementSchema.index({ groupId: 1, createdAt: -1 });
settlementSchema.index({ groupId: 1, status: 1 });

export type SettlementDocument = HydratedDocument<InferSchemaType<typeof settlementSchema>>;
export const Settlement = model('Settlement', settlementSchema);
