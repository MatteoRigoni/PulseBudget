import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/recurring_rule.dart';
import '../model/payment_type.dart';
import '../repository/recurring_rule_repository.dart';
import 'repository_providers.dart';
import 'dart:math';

/// Provider per tutte le regole ricorrenti (StreamProvider)
final recurringRulesProvider = StreamProvider<List<RecurringRule>>((ref) {
  final repository = ref.watch(recurringRuleRepositoryProvider);
  return repository.watchAll();
});

/// Notifier per le operazioni CRUD delle regole ricorrenti
class RecurringRulesNotifier extends StateNotifier<AsyncValue<void>> {
  final RecurringRuleRepository _repository;

  RecurringRulesNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> addRule(RecurringRule rule) async {
    state = const AsyncValue.loading();
    try {
      await _repository.add(rule);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> removeRule(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.delete(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateRule(RecurringRule rule) async {
    state = const AsyncValue.loading();
    try {
      await _repository.update(rule);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addBatch(List<RecurringRule> rules) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addBatch(rules);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider per le operazioni CRUD delle regole ricorrenti
final recurringRulesNotifierProvider =
    StateNotifierProvider<RecurringRulesNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(recurringRuleRepositoryProvider);
  return RecurringRulesNotifier(repository);
});
