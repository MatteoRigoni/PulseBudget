import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/recurring_scheduler.dart';
import 'recurring_rules_provider.dart';
import 'transactions_provider.dart';

final recurringBootstrapProvider = Provider<void>((ref) {
  final rules = ref.read(recurringRulesProvider);
  final transactions = ref.read(transactionsProvider);

  final nuove = generateDueRecurringTransactions(
    rules: rules,
    existingTransactions: transactions,
    now: DateTime.now(),
  );

  final notifier = ref.read(transactionsProvider.notifier);
  for (final t in nuove) {
    notifier.add(t);
  }
});
