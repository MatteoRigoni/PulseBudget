import '../model/recurring_rule.dart';

/// Interfaccia astratta per il repository delle regole ricorrenti
abstract class RecurringRuleRepository {
  /// Ottiene tutte le regole ricorrenti
  Stream<List<RecurringRule>> watchAll();

  /// Ottiene una regola ricorrente specifica per ID
  Future<RecurringRule?> getById(String id);

  /// Aggiunge una nuova regola ricorrente
  Future<void> add(RecurringRule rule);

  /// Aggiorna una regola ricorrente esistente
  Future<void> update(RecurringRule rule);

  /// Elimina una regola ricorrente
  Future<void> delete(String id);

  /// Aggiunge multiple regole ricorrenti in batch
  Future<void> addBatch(List<RecurringRule> rules);
}
