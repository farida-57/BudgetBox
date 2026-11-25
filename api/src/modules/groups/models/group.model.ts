import { Schema, model, type InferSchemaType, type HydratedDocument } from 'mongoose';

export const GROUP_ROLES = ['admin', 'membre'] as const;
export type GroupRole = (typeof GROUP_ROLES)[number];

const memberSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    role: { type: String, enum: GROUP_ROLES, default: 'membre' },
    joinedAt: { type: Date, default: Date.now },
  },
  { _id: false },
);

const invitationSchema = new Schema(
  {
    tokenHash: { type: String, required: true },
    expiresAt: { type: Date, required: true },
    usedAt: { type: Date, default: null },
  },
  { _id: false },
);

const groupSchema = new Schema(
  {
    name: { type: String, required: true, trim: true, minlength: 1, maxlength: 100 },
    currency: { type: String, default: 'XOF', enum: ['XOF'] },
    createdBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    members: { type: [memberSchema], default: [] },
    invitation: { type: invitationSchema, default: undefined },
  },
  { timestamps: true },
);

groupSchema.index({ 'members.userId': 1 });
groupSchema.index({ 'invitation.tokenHash': 1 }, { sparse: true });

export type GroupDocument = HydratedDocument<InferSchemaType<typeof groupSchema>>;
export const Group = model('Group', groupSchema);
