import 'package:flutter/material.dart';
import 'features/settlements/data/settlement_repository.dart';
import 'features/settlements/presentation/activity_page.dart';

void main() => runApp(const BudgetBoxApp());

class BudgetBoxApp extends StatelessWidget {
  const BudgetBoxApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'BudgetBox',
        theme: ThemeData(colorSchemeSeed: const Color(0xff276749), useMaterial3: true),
        home: ActivityPage(repository: SettlementRepository()),
      );
}
