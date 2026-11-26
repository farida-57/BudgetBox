import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dependencies = createDependencies();
  // Restauration de session en arrière-plan ; le routeur affiche /splash
  // tant que l'état est AuthUnknown.
  dependencies.authCubit.checkSession();

  runApp(BudgetBoxApp(dependencies: dependencies));
}
