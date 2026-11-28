import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../bloc/expense_form_cubit.dart';
import '../bloc/expense_form_state.dart';

const _categories = [
  'alimentation',
  'logement',
  'transport',
  'activités',
  'factures',
  'autre',
];

class CreateExpensePage extends StatefulWidget {
  const CreateExpensePage({super.key, this.onExpenseCreated});

  final VoidCallback? onExpenseCreated;

  @override
  State<CreateExpensePage> createState() => _CreateExpensePageState();
}

class _CreateExpensePageState extends State<CreateExpensePage> {
  final _label = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _category = _categories.first;
  DateTime _date = _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void dispose() {
    _label.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: _today(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    final note = _note.text.trim();
    context.read<ExpenseFormCubit>().submit(
      label: _label.text,
      amountText: _amount.text,
      category: _category,
      date: _date,
      note: note.isEmpty ? null : note,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle dépense')),
      body: SafeArea(
        child: BlocConsumer<ExpenseFormCubit, ExpenseFormState>(
          listenWhen: (p, c) => p.status != c.status || p.message != c.message,
          listener: (context, state) {
            if (state.status == ExpenseFormStatus.success) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Dépense ajoutée')));
              context.pop();
            } else if (state.message != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message!)));
            }
          },
          builder: (context, state) {
            if (state.status == ExpenseFormStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == ExpenseFormStatus.loadError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message ?? 'Une erreur est survenue.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.read<ExpenseFormCubit>().load(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }
            return _buildForm(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, ExpenseFormState state) {
    final cubit = context.read<ExpenseFormCubit>();
    final errors = state.fieldErrors;
    final submitting = state.status == ExpenseFormStatus.submitting;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextFormField(
          controller: _label,
          decoration: InputDecoration(
            labelText: 'Libellé',
            errorText: errors['label'],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _amount,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Montant',
            suffixText: 'XOF',
            errorText: errors['amount'],
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: InputDecoration(
            labelText: 'Catégorie',
            errorText: errors['category'],
          ),
          items: [
            for (final c in _categories)
              DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: (v) => setState(() => _category = v ?? _category),
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Date'),
          subtitle: Text(DateFormat('dd/MM/yyyy').format(_date)),
          trailing: const Icon(Icons.calendar_today_outlined),
          onTap: _pickDate,
        ),
        DropdownButtonFormField<String>(
          initialValue: state.payerId,
          decoration: InputDecoration(
            labelText: 'Payé par',
            errorText: errors['payerId'],
          ),
          items: [
            for (final m in state.members)
              DropdownMenuItem(value: m.userId, child: Text(m.displayName)),
          ],
          onChanged: (v) {
            if (v != null) cubit.setPayer(v);
          },
        ),
        const SizedBox(height: 24),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Égal')),
            ButtonSegment(value: true, label: Text('Personnalisé')),
          ],
          selected: {state.isCustom},
          onSelectionChanged: (s) => cubit.setCustom(s.first),
        ),
        const SizedBox(height: 8),
        if (!state.isCustom)
          for (final m in state.members)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(m.displayName),
              value: state.selectedIds.contains(m.userId),
              onChanged: (_) => cubit.toggleParticipant(m.userId),
            )
        else ...[
          for (final m in state.members)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(m.displayName)),
                  SizedBox(
                    width: 130,
                    child: TextField(
                      key: ValueKey('share-${m.userId}'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(suffixText: 'XOF'),
                      onChanged: (v) =>
                          cubit.setCustomAmount(m.userId, int.tryParse(v) ?? 0),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text('Somme des parts : ${state.customTotal} XOF'),
        ],
        if (errors['split'] != null) ...[
          const SizedBox(height: 8),
          Text(
            errors['split']!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: _note,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Note (facultatif)'),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: submitting ? null : _submit,
          child: submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ajouter la dépense'),
        ),
      ],
    );
  }
}
