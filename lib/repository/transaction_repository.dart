import '../model/transaction.dart';
import '../model/payment_type.dart';

/// Interfaccia astratta per il repository delle transazioni
abstract class TransactionRepository {
  /// Ottiene tutte le transazioni
  Stream<List<Transaction>> watchAll();

  /// Ottiene le transazioni per un periodo specifico
  Stream<List<Transaction>> watchByPeriod(DateTime start, DateTime end);

  /// Ottiene una transazione specifica per ID
  Future<Transaction?> getById(String id);

  /// Aggiunge una nuova transazione
  Future<void> add(Transaction transaction);

  /// Aggiorna una transazione esistente
  Future<void> update(Transaction transaction);

  /// Elimina una transazione
  Future<void> delete(String id);

  /// Aggiunge multiple transazioni in batch
  Future<void> addBatch(List<Transaction> transactions);

  /// Cerca transazioni per descrizione (ricerca case-insensitive)
  Stream<List<Transaction>> searchByDescription(String query);

  /// Elimina transazioni per data e tipo di pagamento (per importazione PDF)
  Future<void> deleteByDateAndPaymentType(
      DateTime from, DateTime to, PaymentType type);
}
