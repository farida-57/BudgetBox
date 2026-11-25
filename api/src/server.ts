import 'dotenv/config';
import mongoose from 'mongoose';
import { app } from './app.js';
const port = Number(process.env.PORT ?? 3000);
await mongoose.connect(process.env.MONGODB_URI ?? 'mongodb://127.0.0.1:27017/budgetbox');
app.listen(port, () => console.log(`BudgetBox API écoute sur :${port}`));
