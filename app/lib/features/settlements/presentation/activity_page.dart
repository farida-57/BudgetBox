import 'package:flutter/material.dart';
import '../data/settlement_repository.dart';
import '../domain/activity_item.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key, required this.repository});
  final SettlementRepository repository;
  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final _group = TextEditingController();
  final _user = TextEditingController();
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _member = TextEditingController();
  final _category = TextEditingController();
  final _payer = TextEditingController();
  String? _type;
  Future<List<ActivityItem>>? _future;
  void _load() {
    widget.repository.userId = _user.text.trim().isEmpty ? null : _user.text.trim();
    setState(() => _future = widget.repository.getActivity(_group.text.trim(), type: _type, memberId: _member.text.trim().isEmpty ? null : _member.text.trim(), category: _category.text.trim().isEmpty ? null : _category.text.trim(), payerId: _payer.text.trim().isEmpty ? null : _payer.text.trim(), from: DateTime.tryParse(_from.text.trim()), to: DateTime.tryParse(_to.text.trim())));
  }
  @override
  void dispose() { _group.dispose(); _user.dispose(); _from.dispose(); _to.dispose(); _member.dispose(); _category.dispose(); _payer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Activité du groupe')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(controller: _group, decoration: const InputDecoration(labelText: 'Identifiant du groupe')),
          TextField(controller: _user, decoration: const InputDecoration(labelText: 'Identifiant utilisateur (provisoire)')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(value: _type, decoration: const InputDecoration(labelText: 'Type d’activité'), items: const [DropdownMenuItem(value: null, child: Text('Tout')), DropdownMenuItem(value: 'expense', child: Text('Dépenses')), DropdownMenuItem(value: 'settlement', child: Text('Règlements'))], onChanged: (value) => setState(() => _type = value)),
          TextField(controller: _member, decoration: const InputDecoration(labelText: 'Filtrer par identifiant de membre')),
          TextField(controller: _category, decoration: const InputDecoration(labelText: 'Catégorie de dépense')),
          TextField(controller: _payer, decoration: const InputDecoration(labelText: 'Identifiant du payeur')),
          TextField(controller: _from, decoration: const InputDecoration(labelText: 'Depuis (AAAA-MM-JJ)')),
          TextField(controller: _to, decoration: const InputDecoration(labelText: 'Jusqu’au (AAAA-MM-JJ)')),
          const SizedBox(height: 12),
          FilledButton(onPressed: _load, child: const Text('Charger l’historique')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () => _newSettlement(context), icon: const Icon(Icons.payments_outlined), label: const Text('Enregistrer un paiement déjà effectué')),
          if (_future != null) FutureBuilder<List<ActivityItem>>(future: _future, builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
            if (snapshot.hasError) return Column(children: [Text('Erreur : ${snapshot.error}'), TextButton(onPressed: _load, child: const Text('Réessayer'))]);
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) return const Padding(padding: EdgeInsets.all(24), child: Text('Aucune activité pour le moment.'));
            return Column(children: rows.map((item) => Card(child: ListTile(leading: Icon(item.type == 'expense' ? Icons.receipt_long : Icons.swap_horiz), title: Text(item.title), subtitle: Text('${item.date.toLocal().toString().substring(0, 10)} · ${item.status ?? item.type}'), trailing: Text('${item.amount} XOF'), onTap: item.type == 'settlement' && item.status == 'pending' ? () => _confirm(item) : null))).toList());
          }),
        ]),
      );

  Future<void> _confirm(ActivityItem item) async {
    try { await widget.repository.confirmSettlement(_group.text.trim(), item.id); _load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
  }
  Future<void> _newSettlement(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final from = TextEditingController(); final to = TextEditingController(); final amount = TextEditingController();
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Enregistrer un règlement'), content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Le paiement doit déjà avoir été effectué hors de BudgetBox.'), TextFormField(controller: from, decoration: const InputDecoration(labelText: 'Identifiant du payeur'), validator: _required), TextFormField(controller: to, decoration: const InputDecoration(labelText: 'Identifiant du destinataire'), validator: _required), TextFormField(controller: amount, decoration: const InputDecoration(labelText: 'Montant entier en XOF'), keyboardType: TextInputType.number, validator: (v) => int.tryParse(v ?? '') == null || int.parse(v!) <= 0 ? 'Entrez un montant entier positif.' : null)])), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')), FilledButton(onPressed: () async { if (!formKey.currentState!.validate()) return; try { await widget.repository.createSettlement(_group.text.trim(), fromUserId: from.text.trim(), toUserId: to.text.trim(), amount: int.parse(amount.text)); if (dialogContext.mounted) Navigator.pop(dialogContext); _load(); } catch (e) { if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('$e'))); } }, child: const Text('Enregistrer'))]));
    from.dispose(); to.dispose(); amount.dispose();
  }
  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Champ obligatoire.' : null;
}
