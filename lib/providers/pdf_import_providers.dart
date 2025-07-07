import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../model/imported_transaction.dart';
import '../model/payment_type.dart';
import '../model/statement_info.dart';
import '../services/pdf_parser_service.dart';
import '../services/category_classifier.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

class PdfImportProviders {
  /// Provider per il file PDF selezionato
  static final selectedFileProvider = StateProvider<File?>((ref) => null);

  /// Provider per il tipo di pagamento selezionato
  static final selectedPaymentTypeProvider =
      StateProvider<PaymentType?>((ref) => null);

  /// Provider per l'opzione di sovrascrittura
  static final overwriteOptionProvider = StateProvider<bool>((ref) => false);

  /// Provider per il parsing del PDF
  static final pdfParserProvider =
      FutureProvider.family<List<ImportedTransaction>, File>((ref, file) async {
    return await PdfParserService.parsePdfFile(file);
  });

  /// Provider per le transazioni importate con classificazione
  static final classifiedTransactionsProvider =
      FutureProvider.family<List<ImportedTransaction>, File>((ref, file) async {
    final transactions = await PdfParserService.parsePdfFile(file);
    // Ottieni tutte le categorie disponibili
    final db = DatabaseService();
    await db.initialize();
    final categories = await db.getCategories();

    // Classifica ogni transazione
    for (final transaction in transactions) {
      try {
        final classifications = await CategoryClassifier.classifyTransaction(
            transaction.description);
        if (classifications.isNotEmpty) {
          final bestCategory = classifications.entries
              .reduce((a, b) => a.value > b.value ? a : b);
          final suggestedCategoryId = bestCategory.key;
          final confidence = bestCategory.value;
          final categoryExists =
              categories.any((cat) => cat.id == suggestedCategoryId);
          if (categoryExists) {
            transaction.suggestedCategoryId = suggestedCategoryId;
            transaction.categoryId = suggestedCategoryId;
            transaction.confidence = confidence;
          } else {
            print(
                '[IMPORT][WARNING] Categoria suggerita "$suggestedCategoryId" non trovata tra quelle disponibili! Forzo Non classificata.');
            transaction.suggestedCategoryId = '';
            transaction.categoryId = '';
            transaction.confidence = 0.0;
          }
        } else {
          transaction.suggestedCategoryId = '';
          transaction.categoryId = '';
          transaction.confidence = 0.0;
        }
      } catch (e) {
        print('Errore nella classificazione Naive Bayes: $e');
        transaction.suggestedCategoryId = '';
        transaction.categoryId = '';
        transaction.confidence = 0.0;
      }
    }

    return transactions;
  });

  /// Provider per le statistiche dell'ultimo import
  static final lastImportStatsProvider =
      StateProvider<Map<String, dynamic>?>((ref) => null);

  /// Provider per l'ultimo estratto conto processato
  static final lastStatementInfoProvider =
      FutureProvider<StatementInfo?>((ref) async {
    final db = DatabaseService();
    await db.initialize();
    return await db.getLastStatementInfo();
  });

  /// Provider per tutti gli estratti conto processati
  static final allStatementInfosProvider =
      FutureProvider<List<StatementInfo>>((ref) async {
    final db = DatabaseService();
    await db.initialize();
    return await db.getAllStatementInfos();
  });

  /// Provider per il parsing completo del PDF con info
  static final pdfParserWithInfoProvider =
      FutureProvider.family<Map<String, dynamic>, File>((ref, file) async {
    return await PdfParserService.parsePdfFileWithInfo(file);
  });

  /// Provider per lo stato di caricamento
  static final isLoadingProvider = StateProvider<bool>((ref) => false);

  /// Provider per gli errori
  static final errorProvider = StateProvider<String?>((ref) => null);
}
