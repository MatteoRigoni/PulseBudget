import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/transaction.dart';
import '../model/recurring_rule.dart';
import '../repository/recurring_scheduler.dart';
import '../services/database_service.dart';
import 'transactions_provider.dart';
import 'categories_provider.dart';

void executeRecurringBootstrap(ProviderRef ref) async {
  print('[DEBUG] ===== BOOTSTRAP PROVIDER CHIAMATO =====');

  try {
    final databaseService = DatabaseService();

    // Ottieni le regole ricorrenti
    final rules = await databaseService.getRecurringRules();
    print('[DEBUG] Regole ricorrenti trovate: ${rules.length}');

    // Ottieni le transazioni esistenti
    final existingTransactions = await databaseService.getTransactions();
    print('[DEBUG] Transazioni esistenti: ${existingTransactions.length}');

    // Genera le transazioni ricorrenti scadute
    final now = DateTime.now();
    final newTransactions = generateDueRecurringTransactions(
      rules: rules,
      existingTransactions: existingTransactions,
      now: now,
    );

    print(
        '[DEBUG] Transazioni ricorrenti da generare: ${newTransactions.length}');

    // Inserisci le nuove transazioni usando il notifier (come nella versione vecchia)
    if (newTransactions.isNotEmpty) {
      final notifier = ref.read(transactionsNotifierProvider.notifier);
      for (final transaction in newTransactions) {
        await notifier.add(transaction);
      }
      print(
          '[DEBUG] Transazioni ricorrenti inserite: ${newTransactions.length}');
    } else {
      print('[DEBUG] Nessuna nuova transazione ricorrente da generare');
    }
    print('[DEBUG] ===== BOOTSTRAP PROVIDER COMPLETATO =====');
  } catch (e) {
    print('[ERROR] Errore durante il bootstrap delle ricorrenti: $e');
  }
}

void executeRecurringBootstrapFromWidget(WidgetRef ref) async {
  print('[DEBUG] ===== BOOTSTRAP PROVIDER CHIAMATO =====');

  try {
    final databaseService = DatabaseService();

    // Ottieni le regole ricorrenti
    final rules = await databaseService.getRecurringRules();
    print('[DEBUG] Regole ricorrenti trovate: ${rules.length}');

    // Ottieni le transazioni esistenti
    final existingTransactions = await databaseService.getTransactions();
    print('[DEBUG] Transazioni esistenti: ${existingTransactions.length}');

    // Genera le transazioni ricorrenti scadute
    final now = DateTime.now();
    final newTransactions = generateDueRecurringTransactions(
      rules: rules,
      existingTransactions: existingTransactions,
      now: now,
    );

    print(
        '[DEBUG] Transazioni ricorrenti da generare: ${newTransactions.length}');

    // Inserisci le nuove transazioni usando il notifier (come nella versione vecchia)
    if (newTransactions.isNotEmpty) {
      final notifier = ref.read(transactionsNotifierProvider.notifier);
      for (final transaction in newTransactions) {
        await notifier.add(transaction);
      }
      print(
          '[DEBUG] Transazioni ricorrenti inserite: ${newTransactions.length}');
    } else {
      print('[DEBUG] Nessuna nuova transazione ricorrente da generare');
    }
    print('[DEBUG] ===== BOOTSTRAP PROVIDER COMPLETATO =====');
  } catch (e) {
    print('[ERROR] Errore durante il bootstrap delle ricorrenti: $e');
  }
}

// Versione senza ref per essere chiamata da qualsiasi contesto
void executeRecurringBootstrapSimple() async {
  print('[DEBUG] ===== BOOTSTRAP SIMPLE CHIAMATO =====');

  try {
    final databaseService = DatabaseService();

    // Ottieni le regole ricorrenti
    final rules = await databaseService.getRecurringRules();
    print('[DEBUG] Regole ricorrenti trovate: ${rules.length}');

    // Ottieni le transazioni esistenti
    final existingTransactions = await databaseService.getTransactions();
    print('[DEBUG] Transazioni esistenti: ${existingTransactions.length}');

    // Genera le transazioni ricorrenti scadute
    final now = DateTime.now();
    final newTransactions = generateDueRecurringTransactions(
      rules: rules,
      existingTransactions: existingTransactions,
      now: now,
    );

    print(
        '[DEBUG] Transazioni ricorrenti da generare: ${newTransactions.length}');

    // Inserisci le nuove transazioni direttamente nel database
    if (newTransactions.isNotEmpty) {
      for (final transaction in newTransactions) {
        await databaseService.insertTransaction(transaction);
      }
      print(
          '[DEBUG] Transazioni ricorrenti inserite: ${newTransactions.length}');
    } else {
      print('[DEBUG] Nessuna nuova transazione ricorrente da generare');
    }
    print('[DEBUG] ===== BOOTSTRAP SIMPLE COMPLETATO =====');
  } catch (e) {
    print('[ERROR] Errore durante il bootstrap delle ricorrenti: $e');
  }
}

// Mantieni il provider per compatibilità con HomeScreen
final recurringBootstrapProvider = Provider<void>((ref) {
  // Non eseguire automaticamente il bootstrap per evitare loop infiniti
  // Il bootstrap viene chiamato manualmente nell'initState dell'home screen
});
