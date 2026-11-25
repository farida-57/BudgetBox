import mongoose, { Schema } from 'mongoose';

export type SettlementStatus = 'pending' | 'confirmed';
const settlementSchema = new Schema({
  groupId: { type: Schema.Types.ObjectId, required: true, index: true },
  fromUserId: { type: Schema.Types.ObjectId, required: true },
  toUserId: { type: Schema.Types.ObjectId, required: true },
  amount: { type: Number, required: true, min: 1, validate: Number.isSafeInteger },
  currencyCode: { type: String, required: true, default: 'XOF' },
  recordedBy: { type: Schema.Types.ObjectId, required: true },
  status: { type: String, enum: ['pending', 'confirmed'], default: 'pending', required: true },
  confirmedAt: Date,
}, { timestamps: true });
settlementSchema.index({ groupId: 1, createdAt: -1 });
export const Settlement = mongoose.models.Settlement ?? mongoose.model('Settlement', settlementSchema);
