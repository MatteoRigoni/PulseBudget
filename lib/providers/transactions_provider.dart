import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/transaction.dart';

class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  TransactionsNotifier() : super([]);

  void add(Transaction transaction) {
    state = [...state, transaction];
  }

  void remove(String id) {
    state = state.where((t) => t.id != id).toList();
  }

  void updateTransaction(Transaction transaction) {
    state = state.map((t) => t.id == transaction.id ? transaction : t).toList();
  }

  void clear() {
    state = [];
  }

  // Metodi di utilità per calcoli
  double get totalIncome {
    return state
        .where((t) => t.amount > 0)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double get totalExpenses {
    return state
        .where((t) => t.amount < 0)
        .fold(0.0, (sum, transaction) => sum + transaction.amount.abs());
  }

  double get balance {
    return state.fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  // Filtra per periodo
  List<Transaction> getTransactionsForPeriod(DateTime start, DateTime end) {
    return state.where((transaction) {
      return transaction.date
              .isAfter(start.subtract(const Duration(days: 1))) &&
          transaction.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Filtra per mese e anno
  List<Transaction> getTransactionsForMonth(int month, int year) {
    return state.where((transaction) {
      return transaction.date.month == month && transaction.date.year == year;
    }).toList();
  }
}

// Provider principale per le transazioni
final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<Transaction>>(
  (ref) => TransactionsNotifier(),
);

// Provider per il saldo totale
final balanceProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  return transactions.fold(0.0, (sum, transaction) => sum + transaction.amount);
});

// Provider per le entrate totali
final incomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  return transactions
      .where((t) => t.amount > 0)
      .fold(0.0, (sum, transaction) => sum + transaction.amount);
});

// Provider per le uscite totali
final expensesProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  return transactions
      .where((t) => t.amount < 0)
      .fold(0.0, (sum, transaction) => sum + transaction.amount.abs());
});
