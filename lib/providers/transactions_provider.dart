import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/transaction.dart';
import '../model/payment_type.dart';
import '../repository/transaction_repository.dart';
import 'repository_providers.dart';

/// Provider per tutte le transazioni (StreamProvider)
final transactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchAll();
});

/// Provider per le transazioni filtrate per periodo
final transactionsByPeriodProvider =
    StreamProvider.family<List<Transaction>, ({DateTime start, DateTime end})>(
        (ref, period) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchByPeriod(period.start, period.end);
});

/// Provider per la ricerca transazioni per descrizione
final transactionsSearchProvider =
    StreamProvider.family<List<Transaction>, String>((ref, query) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.searchByDescription(query);
});

/// Provider per il saldo totale
final balanceProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  return transactions.fold(0.0, (sum, transaction) => sum + transaction.amount);
});

/// Provider per le entrate totali
final incomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  return transactions
      .where((t) => t.amount > 0)
      .fold(0.0, (sum, transaction) => sum + transaction.amount);
});

/// Provider per le uscite totali
final expensesProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  return transactions
      .where((t) => t.amount < 0)
      .fold(0.0, (sum, transaction) => sum + transaction.amount.abs());
});

/// Provider per le transazioni del mese corrente
final currentMonthTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final now = DateTime.now();
  return transactions.where((transaction) {
    return transaction.date.month == now.month &&
        transaction.date.year == now.year;
  }).toList();
});

/// Provider per le transazioni del mese precedente
final previousMonthTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final now = DateTime.now();
  final previousMonth = DateTime(now.year, now.month - 1);
  return transactions.where((transaction) {
    return transaction.date.month == previousMonth.month &&
        transaction.date.year == previousMonth.year;
  }).toList();
});

/// Notifier per le operazioni CRUD delle transazioni
class TransactionsNotifier extends StateNotifier<AsyncValue<void>> {
  final TransactionRepository _repository;

  TransactionsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> add(Transaction transaction) async {
    state = const AsyncValue.loading();
    try {
      await _repository.add(transaction);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> update(Transaction transaction) async {
    state = const AsyncValue.loading();
    try {
      await _repository.update(transaction);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> delete(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.delete(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addBatch(List<Transaction> transactions) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addBatch(transactions);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider per le operazioni CRUD delle transazioni
final transactionsNotifierProvider =
    StateNotifierProvider<TransactionsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionsNotifier(repository);
});
