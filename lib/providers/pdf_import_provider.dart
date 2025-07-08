import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/imported_transaction.dart';
import '../model/payment_type.dart';
import '../model/category.dart';
import '../services/pdf_parser_service.dart';
import '../services/category_classifier.dart';
import 'categories_provider.dart';
import 'transactions_provider.dart';
import 'pdf_import_providers.dart';

/// Provider per le transazioni importate
final importedTransactionsProvider = StateNotifierProvider<
    ImportedTransactionsNotifier, List<ImportedTransaction>>((ref) {
  return ImportedTransactionsNotifier();
});

/// Provider per l'opzione di sovrascrittura
final overwriteTransactionsProvider = StateProvider<bool>((ref) {
  return false;
});

/// Provider per lo stato di caricamento
final importLoadingProvider = StateProvider<bool>((ref) {
  return false;
});

/// Provider per i filtri di confidenza
final confidenceFilterProvider = StateProvider<Set<String>>((ref) {
  return {'high', 'medium', 'low'}; // Di default mostra tutto
});

/// Notifier per gestire le transazioni importate
class ImportedTransactionsNotifier
    extends StateNotifier<List<ImportedTransaction>> {
  ImportedTransactionsNotifier() : super([]);

  /// Carica e classifica le transazioni da un file PDF
  Future<void> loadFromPdf(
      File pdfFile, PaymentType paymentType, List<Category> categories) async {
    try {
      // Estrai il testo dal PDF
      final text = await PdfParserService.extractTextFromPdf(pdfFile);

      // Parsa le transazioni
      final transactions = PdfParserService.parseTransactions(text);

      // Classifica ogni transazione
      final classifiedTransactions = <ImportedTransaction>[];
      for (final transaction in transactions) {
        final classifications = await CategoryClassifier.classifyTransaction(
            transaction.description);
        if (classifications.isNotEmpty) {
          final bestCategory = classifications.entries
              .reduce((a, b) => a.value > b.value ? a : b);
          classifiedTransactions.add(transaction.copyWith(
            categoryId: bestCategory.key,
            confidence: bestCategory.value,
          ));
        } else {
          classifiedTransactions.add(transaction);
        }
      }

      state = classifiedTransactions;

      // Seleziona di default le transazioni ad alta confidenza
      _selectHighConfidenceByDefault();
    } catch (e) {
      print('[IMPORT][ERROR] Errore nel caricamento del PDF: $e');
      throw Exception('Errore nel caricamento del PDF.');
    }
  }

  /// Seleziona di default le transazioni ad alta confidenza
  void _selectHighConfidenceByDefault() {
    state = state.map((transaction) {
      if (transaction.confidence > 0.85) {
        return transaction.copyWith(isCorrected: true);
      }
      return transaction;
    }).toList();
  }

  /// Aggiorna la categoria di una transazione
  void updateCategory(String transactionId, String categoryId) {
    state = state.map((transaction) {
      if (transaction.id == transactionId) {
        return transaction.copyWith(
          categoryId: categoryId,
          confidence: 1.0, // Confidenza massima per correzioni manuali
          isCorrected: true,
          isManuallyCorrected: true,
        );
      }
      return transaction;
    }).toList();
  }

  /// Seleziona tutte le transazioni
  void selectAll() {
    state = state.map((transaction) {
      return transaction.copyWith(isCorrected: true);
    }).toList();
  }

  /// Deseleziona tutte le transazioni
  void deselectAll() {
    state = state.map((transaction) {
      return transaction.copyWith(isCorrected: false);
    }).toList();
  }

  /// Toggle della selezione di una singola transazione
  void toggleSelection(String transactionId) {
    state = state.map((transaction) {
      if (transaction.id == transactionId) {
        return transaction.copyWith(isCorrected: !transaction.isCorrected);
      }
      return transaction;
    }).toList();
  }

  /// Pulisce la lista delle transazioni importate
  void clear() {
    state = [];
  }

  /// Ottiene le transazioni selezionate
  List<ImportedTransaction> get selectedTransactions {
    return state.where((transaction) => transaction.isCorrected).toList();
  }

  /// Ottiene le transazioni con alta confidenza (>0.85)
  List<ImportedTransaction> get highConfidenceTransactions {
    return state.where((transaction) => transaction.confidence > 0.85).toList();
  }

  /// Ottiene le transazioni con media confidenza (0.7-0.85)
  List<ImportedTransaction> get mediumConfidenceTransactions {
    return state
        .where((transaction) =>
            transaction.confidence >= 0.7 && transaction.confidence <= 0.85)
        .toList();
  }

  /// Ottiene le transazioni con bassa confidenza (<0.7)
  List<ImportedTransaction> get lowConfidenceTransactions {
    return state.where((transaction) => transaction.confidence < 0.7).toList();
  }

  /// Ottiene le transazioni filtrate per confidenza
  List<ImportedTransaction> getFilteredTransactions(Set<String> filters) {
    return state.where((transaction) {
      if (transaction.confidence > 0.85 && filters.contains('high')) {
        return true;
      }
      if (transaction.confidence >= 0.7 &&
          transaction.confidence <= 0.85 &&
          filters.contains('medium')) {
        return true;
      }
      if (transaction.confidence < 0.7 && filters.contains('low')) {
        return true;
      }
      return false;
    }).toList();
  }
}

/// Provider per il processo di importazione completo
final pdfImportProcessProvider =
    FutureProvider.family<void, File>((ref, pdfFile) async {
  final paymentType = ref.read(PdfImportProviders.selectedPaymentTypeProvider);
  final categories = ref.read(categoriesProvider).value ?? [];
  final notifier = ref.read(importedTransactionsProvider.notifier);

  if (paymentType == null) {
    throw Exception('Tipo di pagamento non selezionato');
  }
  await notifier.loadFromPdf(pdfFile, paymentType, categories);
});
