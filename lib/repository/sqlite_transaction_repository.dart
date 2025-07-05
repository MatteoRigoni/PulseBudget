import 'dart:async';
import 'transaction_repository.dart';
import '../model/transaction.dart';
import '../services/database_service.dart';

class SqliteTransactionRepository implements TransactionRepository {
  final DatabaseService _databaseService;
  final StreamController<List<Transaction>> _transactionsController =
      StreamController<List<Transaction>>.broadcast();

  SqliteTransactionRepository(this._databaseService) {
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await _databaseService.getTransactions();
      _transactionsController.add(transactions);
    } catch (e) {
      _transactionsController.addError(e);
    }
  }

  @override
  Stream<List<Transaction>> watchAll() {
    return _transactionsController.stream;
  }

  @override
  Stream<List<Transaction>> watchByPeriod(DateTime start, DateTime end) {
    return _transactionsController.stream.map((transactions) {
      return transactions.where((transaction) {
        return transaction.date
                .isAfter(start.subtract(const Duration(days: 1))) &&
            transaction.date.isBefore(end.add(const Duration(days: 1)));
      }).toList();
    });
  }

  @override
  Future<Transaction?> getById(String id) async {
    final transactions = await _databaseService.getTransactions();
    try {
      return transactions.firstWhere((transaction) => transaction.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> add(Transaction transaction) async {
    await _databaseService.insertTransaction(transaction);
    await _loadTransactions();
  }

  @override
  Future<void> update(Transaction transaction) async {
    await _databaseService.updateTransaction(transaction);
    await _loadTransactions();
  }

  @override
  Future<void> delete(String id) async {
    await _databaseService.deleteTransaction(id);
    await _loadTransactions();
  }

  @override
  Future<void> addBatch(List<Transaction> transactions) async {
    for (final transaction in transactions) {
      await _databaseService.insertTransaction(transaction);
    }
    await _loadTransactions();
  }

  @override
  Stream<List<Transaction>> searchByDescription(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _transactionsController.stream.map((transactions) {
      return transactions.where((transaction) {
        return transaction.descriptionLowercase.contains(lowercaseQuery);
      }).toList();
    });
  }

  void dispose() {
    _transactionsController.close();
  }
}
