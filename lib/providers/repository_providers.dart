import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../repository/sqlite_transaction_repository.dart';
import '../repository/sqlite_category_repository.dart';
import '../repository/sqlite_balance_repository.dart';
import '../repository/sqlite_recurring_rule_repository.dart';
import '../repository/transaction_repository.dart';
import '../repository/category_repository.dart';
import '../repository/balance_repository.dart';
import '../repository/recurring_rule_repository.dart';

// Provider per il database service
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Provider per i repository
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return SqliteTransactionRepository(databaseService);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return SqliteCategoryRepository(databaseService);
});

final balanceRepositoryProvider = Provider<BalanceRepository>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return SqliteBalanceRepository(databaseService);
});

final recurringRuleRepositoryProvider =
    Provider<RecurringRuleRepository>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return SqliteRecurringRuleRepository(databaseService);
});
