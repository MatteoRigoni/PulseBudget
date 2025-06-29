import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/recurring_rule.dart';
import 'dart:math';

class RecurringRulesNotifier extends StateNotifier<List<RecurringRule>> {
  RecurringRulesNotifier() : super([]);

  void addRule(RecurringRule rule) {
    state = [...state, rule];
  }

  void removeRule(String id) {
    state = state.where((r) => r.id != id).toList();
  }

  void updateRule(RecurringRule updated) {
    state = [
      for (final r in state)
        if (r.id == updated.id) updated else r
    ];
  }
}

final recurringRulesProvider =
    StateNotifierProvider<RecurringRulesNotifier, List<RecurringRule>>(
  (ref) => RecurringRulesNotifier(),
);
