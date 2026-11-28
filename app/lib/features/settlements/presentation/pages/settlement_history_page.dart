import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/format/xof_format.dart';
import '../../../balances/domain/entities/settlement_suggestion.dart';
import '../../../groups/domain/entities/group_member.dart';
import '../../domain/entities/activity_entry.dart';
import '../../domain/usecases/confirm_settlement_usecase.dart';
import '../../domain/usecases/create_settlement_usecase.dart';
import '../../domain/usecases/get_group_activity_usecase.dart';
import '../bloc/settlement_history_cubit.dart';

class SettlementHistoryPage extends StatelessWidget {
  const SettlementHistoryPage({super.key, required this.groupId, required this.currentUserId,
    required this.members, this.initialSuggestion, this.onBalancesChanged});
  final String groupId;
  final String currentUserId;
  final List<GroupMember> members;
  final SettlementSuggestion? initialSuggestion;
  final VoidCallback? onBalancesChanged;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => SettlementHistoryCubit(groupId: groupId,
      getActivity: context.read<GetGroupActivityUseCase>(),
      createSettlement: context.read<CreateSettlementUseCase>(),
      confirmSettlement: context.read<ConfirmSettlementUseCase>())..load(),
    child: _SettlementHistoryView(groupId: groupId, currentUserId: currentUserId, members: members,
      initialSuggestion: initialSuggestion, onBalancesChanged: onBalancesChanged),
  );
}

class _SettlementHistoryView extends StatefulWidget {
  const _SettlementHistoryView({required this.groupId, required this.currentUserId, required this.members,
    this.initialSuggestion, this.onBalancesChanged});
  final String groupId;
  final String currentUserId;
  final List<GroupMember> members;
  final SettlementSuggestion? initialSuggestion;
  final VoidCallback? onBalancesChanged;
  @override
  State<_SettlementHistoryView> createState() => _SettlementHistoryViewState();
}

class _SettlementHistoryViewState extends State<_SettlementHistoryView> {
  String? _type;
  String? _memberId;
  String? _payerId;
  String? _category;
  DateTimeRange? _range;
  int _page = 1;
  final _categories = const ['alimentation', 'logement', 'transport', 'activités', 'factures', 'autre'];

  void _load() => context.read<SettlementHistoryCubit>().load(page: _page, memberId: _memberId,
    payerId: _payerId, category: _category, type: _type, from: _range?.start, to: _range?.end);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Historique et règlements'), actions: [
      IconButton(tooltip: 'Actualiser', onPressed: _load, icon: const Icon(Icons.refresh)),
    ]),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _openCreateDialog(context), icon: const Icon(Icons.payments_outlined), label: const Text('Règlement'),
    ),
    body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 88), children: [
      const Text('Enregistrez uniquement un paiement déjà effectué hors de BudgetBox.'),
      const SizedBox(height: 12),
      DropdownButtonFormField<String?>(initialValue: _type, decoration: const InputDecoration(labelText: 'Type'),
        items: const [DropdownMenuItem<String?>(value: null, child: Text('Tout')), DropdownMenuItem(value: 'expense', child: Text('Dépenses')), DropdownMenuItem(value: 'settlement', child: Text('Règlements'))],
        onChanged: (v) { setState(() { _type = v; _page = 1; }); _load(); }),
      DropdownButtonFormField<String?>(initialValue: _memberId, decoration: const InputDecoration(labelText: 'Membre'),
        items: [const DropdownMenuItem<String?>(value: null, child: Text('Tous')), ...widget.members.map((m) => DropdownMenuItem(value: m.userId, child: Text(m.displayName)))],
        onChanged: (v) { setState(() { _memberId = v; _page = 1; }); _load(); }),
      DropdownButtonFormField<String?>(initialValue: _payerId, decoration: const InputDecoration(labelText: 'Payeur (dépenses)'),
        items: [const DropdownMenuItem<String?>(value: null, child: Text('Tous')), ...widget.members.map((m) => DropdownMenuItem(value: m.userId, child: Text(m.displayName)))],
        onChanged: (v) { setState(() { _payerId = v; _page = 1; }); _load(); }),
      DropdownButtonFormField<String?>(initialValue: _category, decoration: const InputDecoration(labelText: 'Catégorie'),
        items: [const DropdownMenuItem<String?>(value: null, child: Text('Toutes')), ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c)))],
        onChanged: (v) { setState(() { _category = v; _page = 1; }); _load(); }),
      Row(children: [Expanded(child: Text(_range == null ? 'Toutes les dates' : '${_date(_range!.start)} – ${_date(_range!.end)}')),
        TextButton(onPressed: _pickDates, child: const Text('Période')), if (_range != null) IconButton(onPressed: () { setState(() => _range = null); _load(); }, icon: const Icon(Icons.clear))]),
      const Divider(),
      BlocBuilder<SettlementHistoryCubit, SettlementHistoryState>(builder: (context, state) {
        if (state is SettlementHistoryLoading) return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
        if (state is SettlementHistoryError) return Column(children: [Text(state.message), TextButton(onPressed: _load, child: const Text('Réessayer'))]);
        if (state is! SettlementHistoryLoaded) return const SizedBox.shrink();
        final result = state.result;
        if (result.items.isEmpty) return const Padding(padding: EdgeInsets.all(24), child: Text('Aucune activité pour ces filtres.'));
        return Column(children: [
          ...result.items.map((entry) => _activityTile(context, entry)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(onPressed: _page > 1 ? () { setState(() => _page--); _load(); } : null, icon: const Icon(Icons.chevron_left)),
            Text('Page ${result.page} / ${result.pages} · ${result.total} éléments'),
            IconButton(onPressed: _page < result.pages ? () { setState(() => _page++); _load(); } : null, icon: const Icon(Icons.chevron_right)),
          ]),
        ]);
      }),
    ]),
  );

  Widget _activityTile(BuildContext context, ActivityEntry entry) {
    final isSettlement = entry.type == 'settlement';
    final canConfirm = isSettlement && entry.status == 'pending' && entry.toUserId == widget.currentUserId;
    final names = {for (final m in widget.members) m.userId: m.displayName};
    final title = isSettlement
      ? '${names[entry.fromUserId] ?? 'Membre'} → ${names[entry.toUserId] ?? 'ancien membre'}'
      : entry.title;
    return Card(child: ListTile(
      leading: Icon(isSettlement ? Icons.swap_horiz : Icons.receipt_long),
      title: Text(title),
      subtitle: Text('${_date(entry.occurredAt)} · ${isSettlement ? (entry.status == 'confirmed' ? 'Confirmé' : 'En attente') : (entry.category ?? 'Dépense')}'),
      trailing: Text(formatXof(entry.amount, currency: entry.currency)),
      onTap: canConfirm ? () => _confirm(context, entry) : null,
    ));
  }

  Future<void> _confirm(BuildContext context, ActivityEntry entry) async {
    final cubit = context.read<SettlementHistoryCubit>();
    try {
      await cubit.confirm(entry.id);
      if (!context.mounted) return;
      widget.onBalancesChanged?.call();
      cubit.load(page: _page, memberId: _memberId, payerId: _payerId, category: _category,
        type: _type, from: _range?.start, to: _range?.end);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Règlement confirmé.')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _openCreateDialog(BuildContext context) async {
    final suggestion = widget.initialSuggestion;
    final usable = widget.members.any((m) => m.userId == suggestion?.fromUserId) && widget.members.any((m) => m.userId == suggestion?.toUserId);
    if (suggestion != null && !usable) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cette suggestion concerne un ancien membre du groupe.')));
      return;
    }
    if (widget.members.length < 2) return;
    final form = GlobalKey<FormState>();
    final amount = TextEditingController(text: suggestion?.amount.toString() ?? '');
    var fromId = suggestion?.fromUserId ?? widget.currentUserId;
    if (!widget.members.any((m) => m.userId == fromId)) fromId = widget.members.first.userId;
    var toId = suggestion?.toUserId ?? widget.members.firstWhere((m) => m.userId != fromId).userId;
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: const Text('Enregistrer un règlement'),
      content: Form(key: form, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Le paiement doit déjà avoir été fait hors de BudgetBox.'),
        DropdownButtonFormField<String>(initialValue: fromId, decoration: const InputDecoration(labelText: 'La personne qui a payé'),
          items: widget.members.map((m) => DropdownMenuItem(value: m.userId, child: Text(m.displayName))).toList(),
          onChanged: (v) => setDialogState(() { fromId = v!; if (fromId == toId) toId = widget.members.firstWhere((m) => m.userId != fromId).userId; })),
        DropdownButtonFormField<String>(initialValue: toId, decoration: const InputDecoration(labelText: 'Destinataire'),
          items: widget.members.where((m) => m.userId != fromId).map((m) => DropdownMenuItem(value: m.userId, child: Text(m.displayName))).toList(),
          onChanged: (v) => setDialogState(() => toId = v!)),
        TextFormField(controller: amount, decoration: const InputDecoration(labelText: 'Montant en XOF'), keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => int.tryParse(v ?? '') == null || int.parse(v!) < 1 ? 'Entrez un montant entier positif.' : null),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
        FilledButton(onPressed: () async {
          if (!form.currentState!.validate()) return;
          try {
            await context.read<SettlementHistoryCubit>().create(fromUserId: fromId, toUserId: toId, amount: int.parse(amount.text));
            if (dialogContext.mounted) Navigator.pop(dialogContext);
            _load();
          } catch (e) { if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(e.toString()))); }
        }, child: const Text('Enregistrer'))],
    )));
    amount.dispose();
  }

  Future<void> _pickDates() async {
    final range = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now(), initialDateRange: _range);
    if (range != null) { setState(() { _range = range; _page = 1; }); _load(); }
  }
  String _date(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

