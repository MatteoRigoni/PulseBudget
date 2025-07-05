import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/recurring_scheduler.dart';
import 'recurring_rules_provider.dart';
import 'transactions_provider.dart';
import 'categories_provider.dart';

void executeRecurringBootstrap(ProviderRef ref) {
  print('[DEBUG] executeRecurringBootstrap chiamata');

  // Inizializza dati di esempio se necessario
  final categories = ref.read(categoriesProvider);
  if (categories.isEmpty) {
    print('[DEBUG] Inizializzazione categorie di esempio');
    final notifier = ref.read(categoriesProvider.notifier);
    notifier.state = CategoriesNotifier.getDefaultCategories();
  }

  final transactions = ref.read(transactionsProvider);
  if (transactions.isEmpty) {
    print('[DEBUG] Inizializzazione transazioni di esempio');
    ref.read(transactionsProvider.notifier).seedMockData();
  }

  final finalRules = ref.read(recurringRulesProvider);
  final finalTransactions = ref.read(transactionsProvider);

  print(
      '[DEBUG] Prima del bootstrap: rules=${finalRules.length}, transactions=${finalTransactions.length}');

  final nuove = generateDueRecurringTransactions(
    rules: finalRules,
    existingTransactions: finalTransactions,
    now: DateTime.now(),
  );

  print(
      '[DEBUG] Dopo generateDueRecurringTransactions: generate=${nuove.length} transazioni');

  final notifier = ref.read(transactionsProvider.notifier);
  for (final t in nuove) {
    notifier.add(t);
  }

  print('[DEBUG] Bootstrap completato: aggiunte ${nuove.length} transazioni');
}

void executeRecurringBootstrapFromWidget(WidgetRef ref) {
  print('[DEBUG] executeRecurringBootstrapFromWidget chiamata');

  // Inizializza dati di esempio se necessario
  final categories = ref.read(categoriesProvider);
  if (categories.isEmpty) {
    print('[DEBUG] Inizializzazione categorie di esempio');
    final notifier = ref.read(categoriesProvider.notifier);
    notifier.state = CategoriesNotifier.getDefaultCategories();
  }

  final transactions = ref.read(transactionsProvider);
  if (transactions.isEmpty) {
    print('[DEBUG] Inizializzazione transazioni di esempio');
    ref.read(transactionsProvider.notifier).seedMockData();
  }

  final finalRules = ref.read(recurringRulesProvider);
  final finalTransactions = ref.read(transactionsProvider);

  print(
      '[DEBUG] Prima del bootstrap: rules=${finalRules.length}, transactions=${finalTransactions.length}');

  final nuove = generateDueRecurringTransactions(
    rules: finalRules,
    existingTransactions: finalTransactions,
    now: DateTime.now(),
  );

  print(
      '[DEBUG] Dopo generateDueRecurringTransactions: generate=${nuove.length} transazioni');

  final notifier = ref.read(transactionsProvider.notifier);
  for (final t in nuove) {
    notifier.add(t);
  }

  print('[DEBUG] Bootstrap completato: aggiunte ${nuove.length} transazioni');
}

// Mantieni il provider per compatibilità con HomeScreen
final recurringBootstrapProvider = Provider<void>((ref) {
  executeRecurringBootstrap(ref);
});
