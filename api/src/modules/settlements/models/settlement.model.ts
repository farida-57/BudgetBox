import { model, Schema, type HydratedDocument, type InferSchemaType } from 'mongoose';

export const SETTLEMENT_STATUSES = ['pending', 'confirmed'] as const;
export type SettlementStatus = (typeof SETTLEMENT_STATUSES)[number];
const schema = new Schema({
  groupId: { type: Schema.Types.ObjectId, ref: 'Group', required: true, index: true },
  fromUserId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  toUserId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  amount: { type: Number, required: true, min: 1, validate: Number.isSafeInteger },
  currency: { type: String, required: true, default: 'XOF', enum: ['XOF'] },
  recordedBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  status: { type: String, enum: SETTLEMENT_STATUSES, required: true, default: 'pending' },
  confirmedAt: { type: Date, default: null },
}, { timestamps: true });
schema.index({ groupId: 1, createdAt: -1, _id: -1 });
schema.index({ groupId: 1, status: 1, fromUserId: 1, toUserId: 1 });
export type SettlementDocument = HydratedDocument<InferSchemaType<typeof schema>>;
export const Settlement = model('Settlement', schema);
