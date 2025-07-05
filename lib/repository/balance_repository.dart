import '../model/snapshot.dart';

/// Interfaccia astratta per il repository del patrimonio
abstract class BalanceRepository {
  /// Ottiene tutti gli snapshot del patrimonio
  Stream<List<Snapshot>> watchAll();

  /// Ottiene gli snapshot per un periodo specifico
  Stream<List<Snapshot>> watchByPeriod(DateTime start, DateTime end);

  /// Ottiene uno snapshot specifico per ID
  Future<Snapshot?> getById(String id);

  /// Aggiunge un nuovo snapshot
  Future<void> add(Snapshot snapshot);

  /// Aggiorna uno snapshot esistente
  Future<void> update(Snapshot snapshot);

  /// Elimina uno snapshot
  Future<void> delete(String id);

  /// Aggiunge multiple snapshot in batch
  Future<void> addBatch(List<Snapshot> snapshots);
}
