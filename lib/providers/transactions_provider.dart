import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/transaction.dart';
import '../model/payment_type.dart';

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

  void seedMockData() {
    if (state.isNotEmpty) return; // Non inizializzare se ci sono già dati

    final now = DateTime.now();
    state = [
      Transaction(
        amount: -45.50,
        date: now.subtract(const Duration(days: 2)),
        description: 'Spesa supermercato',
        categoryId: 'expense-food',
        paymentType: PaymentType.creditCard,
      ),
      Transaction(
        amount: -15.00,
        date: now.subtract(const Duration(days: 1)),
        description: 'Benzina',
        categoryId: 'expense-transport',
        paymentType: PaymentType.bancomat,
      ),
      Transaction(
        amount: 1200.00,
        date: now.subtract(const Duration(days: 5)),
        description: 'Stipendio',
        categoryId: 'income-salary',
        paymentType: PaymentType.bankTransfer,
      ),
      Transaction(
        amount: -60.00,
        date: now.subtract(const Duration(days: 3)),
        description: 'Cena fuori',
        categoryId: 'expense-food',
        paymentType: PaymentType.creditCard,
      ),
      Transaction(
        amount: -80.00,
        date: now.subtract(const Duration(days: 4)),
        description: 'Shopping online',
        categoryId: 'expense-shopping',
        paymentType: PaymentType.creditCard,
      ),
      Transaction(
        amount: 200.00,
        date: now.subtract(const Duration(days: 10)),
        description: 'Regalo compleanno',
        categoryId: 'income-gift',
        paymentType: PaymentType.cash,
      ),
      Transaction(
        amount: -100.00,
        date: now.subtract(const Duration(days: 7)),
        description: 'Bollette luce',
        categoryId: 'expense-bills',
        paymentType: PaymentType.bankTransfer,
      ),
      Transaction(
        amount: -30.00,
        date: now.subtract(const Duration(days: 6)),
        description: 'Cinema',
        categoryId: 'expense-entertainment',
        paymentType: PaymentType.cash,
      ),
      Transaction(
        amount: 350.00,
        date: now.subtract(const Duration(days: 12)),
        description: 'Freelance',
        categoryId: 'income-freelance',
        paymentType: PaymentType.bankTransfer,
      ),
      // Nuove categorie spese mese corrente
      Transaction(
        amount: -22.00,
        date: now.subtract(const Duration(days: 2)),
        description: 'Farmacia',
        categoryId: 'expense-health',
        paymentType: PaymentType.cash,
      ),
      Transaction(
        amount: -75.00,
        date: now.subtract(const Duration(days: 5)),
        description: 'Materiale scolastico',
        categoryId: 'expense-education',
        paymentType: PaymentType.creditCard,
      ),
      Transaction(
        amount: -210.00,
        date: now.subtract(const Duration(days: 8)),
        description: 'Riparazione casa',
        categoryId: 'expense-home',
        paymentType: PaymentType.bankTransfer,
      ),
      Transaction(
        amount: -55.00,
        date: now.subtract(const Duration(days: 4)),
        description: 'Concerto',
        categoryId: 'expense-entertainment',
        paymentType: PaymentType.creditCard,
      ),
    ];
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
