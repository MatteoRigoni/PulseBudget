import 'dart:async';
import 'recurring_rule_repository.dart';
import '../model/recurring_rule.dart';
import '../services/database_service.dart';

class SqliteRecurringRuleRepository implements RecurringRuleRepository {
  final DatabaseService _databaseService;
  final StreamController<List<RecurringRule>> _rulesController =
      StreamController<List<RecurringRule>>.broadcast();

  SqliteRecurringRuleRepository(this._databaseService) {
    _loadRules();
  }

  Future<void> _loadRules() async {
    try {
      final rules = await _databaseService.getRecurringRules();
      _rulesController.add(rules);
    } catch (e) {
      _rulesController.addError(e);
    }
  }

  @override
  Stream<List<RecurringRule>> watchAll() {
    return _rulesController.stream;
  }

  @override
  Future<RecurringRule?> getById(String id) async {
    final rules = await _databaseService.getRecurringRules();
    try {
      return rules.firstWhere((rule) => rule.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> add(RecurringRule rule) async {
    await _databaseService.insertRecurringRule(rule);
    await _loadRules();
  }

  @override
  Future<void> update(RecurringRule rule) async {
    await _databaseService.updateRecurringRule(rule);
    await _loadRules();
  }

  @override
  Future<void> delete(String id) async {
    await _databaseService.deleteRecurringRule(id);
    await _loadRules();
  }

  @override
  Future<void> addBatch(List<RecurringRule> rules) async {
    for (final rule in rules) {
      await _databaseService.insertRecurringRule(rule);
    }
    await _loadRules();
  }

  void dispose() {
    _rulesController.close();
  }
}
