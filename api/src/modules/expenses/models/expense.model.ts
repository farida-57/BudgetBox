import mongoose, { Schema } from 'mongoose';

const integer = {
  validator: Number.isInteger,
  message: 'Le montant doit être un entier',
};

const shareSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    amount: { type: Number, required: true, min: 0, validate: integer },
  },
  { _id: false },
);

const expenseSchema = new Schema(
  {
    groupId: { type: Schema.Types.ObjectId, ref: 'Group', required: true },
    label: { type: String, required: true, trim: true, maxlength: 100 },
    amount: { type: Number, required: true, min: 1, validate: integer },
    payerId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    shares: { type: [shareSchema], required: true },
    category: { type: String, required: true, trim: true, maxlength: 40 },
    date: { type: Date, required: true },
    note: { type: String, trim: true, maxlength: 500 },
    createdBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  },
  { timestamps: true },
);

expenseSchema.index({ groupId: 1, date: -1 });
expenseSchema.index({ groupId: 1, category: 1, date: -1 });

export const Expense = mongoose.model('Expense', expenseSchema);