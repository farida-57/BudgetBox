import mongoose, { Schema } from 'mongoose';
const schema = new Schema({ groupId: Schema.Types.ObjectId, payerId: Schema.Types.ObjectId, amount: Number, participants: [{ userId: Schema.Types.ObjectId, shareAmount: Number }], category: String, spentAt: Date }, { strict: false });
export const ExpenseAdapter = mongoose.models.Expense ?? mongoose.model('Expense', schema);
