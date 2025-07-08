import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/imported_transaction.dart';
import '../../model/category.dart';
import '../../providers/pdf_import_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/pdf_import_providers.dart';
import '../../services/category_classifier.dart';
import '../../services/database_service.dart';
import '../../model/statement_info.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'category_picker_sheet.dart';
import '../../model/payment_type.dart';
import '../widgets/custom_snackbar.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({super.key});

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  final NumberFormat currencyFormat = NumberFormat('###,##0.00', 'it_IT');
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final importedTransactions = ref.watch(importedTransactionsProvider);
    final categories = ref.watch(categoriesProvider).value ?? [];
    final notifier = ref.read(importedTransactionsProvider.notifier);
    final confidenceFilters = ref.watch(confidenceFilterProvider);
    final filterNotifier = ref.read(confidenceFilterProvider.notifier);

    // Ottieni le transazioni filtrate
    final filteredTransactions = notifier
        .getFilteredTransactions(confidenceFilters)
        // Mostra tutte, ma la selezione sarà disabilitata per quelle senza categoria o con 'transfer-withdrawal'
        .toList();

    final highConfidence = notifier.highConfidenceTransactions.length;
    final mediumConfidence = notifier.mediumConfidenceTransactions.length;
    final lowConfidence = notifier.lowConfidenceTransactions.length;

    // Determina se tutte le transazioni filtrate sono selezionate
    final allSelected = filteredTransactions.isNotEmpty &&
        filteredTransactions
            .where((t) =>
                t.categoryId.isNotEmpty &&
                t.categoryId != 'transfer-withdrawal')
            .isNotEmpty &&
        filteredTransactions
            .where((t) =>
                t.categoryId.isNotEmpty &&
                t.categoryId != 'transfer-withdrawal')
            .every((t) => t.isCorrected);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Anteprima Import'),
            actions: [
              // Pulsante help
              IconButton(
                icon: const Icon(Icons.help_outline),
                tooltip: 'Come funziona questa pagina?',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title:
                          const Text('Come funziona l\'anteprima importazione'),
                      content: const SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('''In questa pagina puoi:

- Vedere le transazioni rilevate dal PDF.
- Ogni transazione viene classificata automaticamente tramite regole (keyword) o tramite un modello AI (Naive Bayes) addestrato sulle tue correzioni manuali.
- Se la categoria è stata assegnata con sicurezza (verde), puoi importare direttamente. Se la categoria è dubbia (gialla) o non classificata (rossa), puoi correggerla manualmente.
- Solo le correzioni manuali vengono usate per addestrare l\'AI e migliorare la classificazione futura.
- Puoi selezionare/deselezionare le transazioni da importare.
- I colori indicano: verde = alta confidenza, giallo = dubbio (pochi dati), rosso = non classificata.

Più correggi, più il sistema impara!'''),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Chiudi'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Pulsante toggle seleziona tutto/deseleziona tutto
              IconButton(
                onPressed: () {
                  if (allSelected) {
                    notifier.deselectAll();
                  } else {
                    _selectAllWithCategory();
                  }
                },
                icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
                tooltip: allSelected ? 'Deseleziona tutto' : 'Seleziona tutto',
              ),
            ],
          ),
          body: Column(
            children: [
              // Statistiche come filtri
              Container(
                padding: const EdgeInsets.all(16),
                color: colorScheme.surface,
                child: Row(
                  children: [
                    _buildFilterCard(
                      'Alta confidenza',
                      highConfidence,
                      Colors.green,
                      'high',
                      confidenceFilters.contains('high'),
                      (isSelected) {
                        final newFilters = Set<String>.from(confidenceFilters);
                        if (isSelected) {
                          newFilters.add('high');
                        } else {
                          newFilters.remove('high');
                        }
                        filterNotifier.state = newFilters;
                      },
                      theme,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterCard(
                      'Media confidenza',
                      mediumConfidence,
                      Colors.orange,
                      'medium',
                      confidenceFilters.contains('medium'),
                      (isSelected) {
                        final newFilters = Set<String>.from(confidenceFilters);
                        if (isSelected) {
                          newFilters.add('medium');
                        } else {
                          newFilters.remove('medium');
                        }
                        filterNotifier.state = newFilters;
                      },
                      theme,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterCard(
                      'Bassa confidenza',
                      lowConfidence,
                      Colors.red,
                      'low',
                      confidenceFilters.contains('low'),
                      (isSelected) {
                        final newFilters = Set<String>.from(confidenceFilters);
                        if (isSelected) {
                          newFilters.add('low');
                        } else {
                          newFilters.remove('low');
                        }
                        filterNotifier.state = newFilters;
                      },
                      theme,
                    ),
                  ],
                ),
              ),

              // Lista transazioni filtrate
              Expanded(
                child: filteredTransactions.isEmpty
                    ? Center(
                        child: Text(
                          'Nessuna transazione trovata',
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = filteredTransactions[index];
                          // Accesso robusto alla categoria
                          Category category;
                          if (categories.isNotEmpty &&
                              transaction.categoryId.isNotEmpty) {
                            category = categories.firstWhere(
                              (cat) => cat.id == transaction.categoryId,
                              orElse: () {
                                print(
                                    '[PREVIEW][WARNING] Categoria id "${transaction.categoryId}" non trovata tra quelle disponibili! Uso fallback.');
                                return Category(
                                  id: '',
                                  name: 'Non classificata',
                                  icon: Icons.help_outline,
                                  colorHex: '#808080',
                                  type: 'expense',
                                );
                              },
                            );
                          } else {
                            print(
                                '[PREVIEW][WARNING] Lista categorie vuota o categoryId vuoto per "${transaction.description}". Uso fallback.');
                            category = Category(
                              id: '',
                              name: 'Non classificata',
                              icon: Icons.help_outline,
                              colorHex: '#808080',
                              type: 'expense',
                            );
                          }

                          print(
                              'DEBUG: TRANSAZIONE PREVIEW -> desc: "${transaction.description}", categoryId: "${transaction.categoryId}", categoryName: "${category.name}", confidence: ${transaction.confidence}, isUnclassified: ${category.id.isEmpty}');

                          final isPrelievo =
                              transaction.categoryId == 'transfer-withdrawal';
                          final isSelectable =
                              transaction.categoryId.isNotEmpty &&
                                  !isPrelievo &&
                                  category.id.isNotEmpty;

                          // Se la categoria non è assegnata, forza confidence bassa
                          final isUnclassified = category.id.isEmpty;
                          final confidenceToShow =
                              isUnclassified ? 0.0 : transaction.confidence;

                          // LOG MIRATO: mostra il flusso di classificazione
                          print(
                              '[PREVIEW][CLASSIFY] "${transaction.description}" -> categoryId: "${transaction.categoryId}" | categoryName: "${category.name}" | confidence: ${transaction.confidence} | unclassified: ${category.id.isEmpty}');

                          return TransactionPreviewCard(
                            transaction: isPrelievo
                                ? transaction.copyWith(isCorrected: false)
                                : transaction,
                            category: category,
                            onCategoryTap: () =>
                                _showCategoryPicker(transaction),
                            onToggleSelection: () {
                              if (isPrelievo) {
                                CustomSnackBar.show(
                                  context,
                                  message:
                                      'I prelievi non sono importabili come movimenti!',
                                  type: SnackBarType.warning,
                                );
                              } else if (!isSelectable) {
                                CustomSnackBar.show(
                                  context,
                                  message:
                                      'Questa transazione non è selezionabile!',
                                  type: SnackBarType.warning,
                                );
                              } else {
                                notifier.toggleSelection(transaction.id);
                              }
                            },
                            checkboxEnabled: isSelectable,
                            confidence: confidenceToShow,
                          );
                        },
                      ),
              ),
            ],
          ),
          // Pulsante Importa fisso in fondo
          floatingActionButton: filteredTransactions.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () => _importTransactions(),
                  icon: const Icon(Icons.download),
                  label: const Text('Importa'),
                )
              : null,
        ),
        if (_isImporting)
          Container(
            color: Colors.black.withOpacity(0.2),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterCard(
    String label,
    int count,
    Color color,
    String filterKey,
    bool isSelected,
    Function(bool) onToggle,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => onToggle(!isSelected),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryPicker(ImportedTransaction transaction) async {
    // Determina se è un'entrata o un'uscita basandosi sull'importo
    final isIncome = transaction.amount > 0;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryPickerSheet(isIncome: isIncome),
    );

    if (result != null) {
      ref.read(importedTransactionsProvider.notifier).updateCategory(
            transaction.id,
            result,
          );
    }
  }

  Future<void> _importTransactions() async {
    setState(() => _isImporting = true);
    try {
      print('DEBUG: Inizio importazione transazioni');

      final notifier = ref.read(importedTransactionsProvider.notifier);
      print('DEBUG: Notifier ottenuto');

      final selectedTransactions = notifier.selectedTransactions;
      print(
          'DEBUG: Transazioni selezionate ottenute: ${selectedTransactions.length}');

      final overwrite = ref.read(PdfImportProviders.overwriteOptionProvider);
      print('DEBUG: Overwrite option: $overwrite');

      final paymentType =
          ref.read(PdfImportProviders.selectedPaymentTypeProvider);
      if (paymentType == null) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            message: 'Seleziona un tipo di pagamento',
            type: SnackBarType.error,
          );
        }
        return;
      }
      print('DEBUG: Payment type: $paymentType');

      if (selectedTransactions.isEmpty) {
        print('DEBUG: Nessuna transazione selezionata');
        CustomSnackBar.show(
          context,
          message: 'Seleziona almeno una transazione',
          type: SnackBarType.warning,
        );
        return;
      }

      // Debug: stampa le transazioni selezionate
      print('DEBUG: Transazioni selezionate: ${selectedTransactions.length}');
      for (int i = 0; i < selectedTransactions.length; i++) {
        final t = selectedTransactions[i];
        print(
            'DEBUG[$i]: ${t.description} - categoryId: "${t.categoryId}" - amount: ${t.amount} - date: ${t.date}');
      }

      // Trova il range di date
      print('DEBUG: Calcolo range date');
      final dates = selectedTransactions.map((t) => t.date).toList();
      final startDate = dates.reduce((a, b) => a.isBefore(b) ? a : b);
      final endDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);
      print('DEBUG: Range date: $startDate - $endDate');

      // Se richiesto, elimina le transazioni esistenti
      if (overwrite) {
        print('DEBUG: Eliminazione transazioni esistenti');
        final repository = ref.read(transactionRepositoryProvider);
        print('DEBUG: Repository ottenuto per eliminazione');
        await repository.deleteByDateAndPaymentType(
            startDate, endDate, paymentType);
        print('DEBUG: Transazioni esistenti eliminate');
      }

      // Converti e salva le transazioni
      print('DEBUG: Inizio conversione transazioni');
      final transactions = selectedTransactions.map((t) {
        // Fallback sicuro per categoryId
        String categoryId = t.categoryId;
        if (categoryId.isEmpty) {
          print(
              'DEBUG: categoryId vuoto per ${t.description}, uso expense-misc');
          categoryId = 'expense-misc';
        }
        // Fallback per paymentType
        final pt = paymentType ?? PaymentType.bancomat;
        print(
            'DEBUG: Converting ${t.description} with categoryId: "$categoryId" paymentType: $pt');
        final tx = t.copyWith(categoryId: categoryId).toTransaction(pt);
        print(
            'DEBUG: Converted transaction: ${tx.id} - ${tx.description} - ${tx.categoryId} - ${tx.paymentType}');
        return tx;
      }).toList();

      print('DEBUG: Transazioni convertite: ${transactions.length}');

      print('DEBUG: Ottenimento repository per salvataggio');
      final repository = ref.read(transactionRepositoryProvider);
      print('DEBUG: Repository ottenuto per salvataggio');

      print('DEBUG: Inizio salvataggio batch');
      await repository.addBatch(transactions);
      print('DEBUG: Salvataggio batch completato');

      // Salva i campioni di training per le correzioni manuali
      print('DEBUG: Inizio salvataggio campioni training');
      for (final transaction in selectedTransactions) {
        print(
            '[TRAINING][CHECK] "${transaction.description}" -> ${transaction.categoryId} | isCorrected: \\${transaction.isCorrected} | isManuallyCorrected: \\${transaction.isManuallyCorrected}');
        if (transaction.isManuallyCorrected) {
          print(
              'DEBUG: Salvataggio campione per: \\${transaction.description}');
          await CategoryClassifier.addTrainingSample(
              transaction.description, transaction.categoryId,
              manual: true);
        }
      }
      print('DEBUG: Campioni training salvati');

      // Salva le informazioni dell'estratto conto
      print('DEBUG: Inizio salvataggio info estratto conto');
      final db = DatabaseService();
      print('DEBUG: DatabaseService creato');
      await db.initialize();
      print('DEBUG: Database inizializzato');

      // Estrai info dal file (per ora usiamo dati di esempio)
      final statementInfo = StatementInfo(
        id: const Uuid().v4(),
        accountHolder: 'MARIO ROSSI', // In futuro estrarre dal PDF
        month: 'GENNAIO 2024', // In futuro estrarre dal PDF
        processedDate: DateTime.now(),
        transactionCount: selectedTransactions.length,
        paymentType: paymentType.name,
      );
      print(
          'DEBUG: Salvataggio StatementInfo: id=${statementInfo.id}, paymentType=${statementInfo.paymentType}, accountHolder=${statementInfo.accountHolder}, month=${statementInfo.month}, transactionCount=${statementInfo.transactionCount}');
      print('DEBUG: StatementInfo creato: ${statementInfo.id}');

      await db.saveStatementInfo(statementInfo);
      print('DEBUG: StatementInfo salvato');

      // Pulisci la lista delle transazioni importate
      print('DEBUG: Pulizia lista transazioni importate');
      notifier.clear();
      print('DEBUG: Lista pulita');

      // Torna alla home
      if (mounted) {
        print('DEBUG: Navigazione alla home');
        Navigator.of(context).popUntil((route) => route.isFirst);

        // Mostra snackbar di conferma
        print('DEBUG: Mostra snackbar conferma');
        CustomSnackBar.show(
          context,
          message: 'Importati ${selectedTransactions.length} movimenti',
          type: SnackBarType.success,
        );
        print('DEBUG: Importazione completata con successo');
      }
    } catch (e, stackTrace) {
      print('DEBUG: ERRORE durante importazione: $e');
      print('DEBUG: Stack trace: $stackTrace');
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Errore durante l\'importazione: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  // Modifica selectAll per selezionare solo quelle con categoria valorizzata e diversa da prelievo
  void _selectAllWithCategory() {
    final notifier = ref.read(importedTransactionsProvider.notifier);
    final filteredTransactions =
        notifier.getFilteredTransactions(ref.read(confidenceFilterProvider));
    final categories = ref.read(categoriesProvider).value ?? [];
    notifier.state = notifier.state.map((transaction) {
      final category = categories.firstWhere(
        (cat) => cat.id == transaction.categoryId,
        orElse: () => Category(
          id: '',
          name: 'Non classificata',
          icon: Icons.help_outline,
          colorHex: '#808080',
          type: 'expense',
        ),
      );
      final isPrelievo = transaction.categoryId == 'transfer-withdrawal';
      final selectable = transaction.categoryId.isNotEmpty &&
          !isPrelievo &&
          category.id.isNotEmpty;
      if (filteredTransactions.any((t) => t.id == transaction.id) &&
          selectable) {
        return transaction.copyWith(isCorrected: true);
      }
      // Prelievo: mai selezionato
      return transaction.copyWith(isCorrected: false);
    }).toList();
  }
}

class TransactionPreviewCard extends StatelessWidget {
  final ImportedTransaction transaction;
  final Category category;
  final VoidCallback onCategoryTap;
  final VoidCallback onToggleSelection;
  final bool checkboxEnabled;
  final double confidence;

  const TransactionPreviewCard({
    super.key,
    required this.transaction,
    required this.category,
    required this.onCategoryTap,
    required this.onToggleSelection,
    required this.checkboxEnabled,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final NumberFormat currencyFormat = NumberFormat('###,##0.00', 'it_IT');
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

    if (category.id.isEmpty) {
      print(
          '[CARD][ERROR] Categoria nulla o non classificata per transazione: ${transaction.description}');
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.help_outline, color: Colors.red, size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          dateFormat.format(transaction.date),
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${currencyFormat.format(transaction.amount.abs())} €',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: transaction.amount > 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onCategoryTap,
                child: Tooltip(
                  message: 'Categoria non riconosciuta – da assegnare',
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Checkbox(
                value: transaction.isCorrected,
                onChanged:
                    checkboxEnabled ? ((_) => onToggleSelection()) : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            // Icona categoria con tooltip al tap (senza aprire lista)
            GestureDetector(
              onTap: () {
                // Mostra tooltip personalizzato sopra l'icona
                _showCategoryTooltip(context, category.name);
              },
              child: CircleAvatar(
                backgroundColor: category.color.withOpacity(0.2),
                radius: 22, // Più grande
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 8), // Meno spazio

            // Descrizione e data con importo (massimo spazio)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12, // Font ancora più piccolo
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2), // Meno spazio
                  Row(
                    children: [
                      Text(
                        dateFormat.format(transaction.date),
                        style: TextStyle(
                          fontSize: 10, // Font più piccolo
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8), // Spazio tra data e importo
                      Text(
                        '${currencyFormat.format(transaction.amount.abs())} €',
                        style: TextStyle(
                          fontSize: 13, // Font più piccolo
                          fontWeight: FontWeight.bold,
                          color: transaction.amount > 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4), // Meno spazio

            // Chip confidenza e checkbox
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chip confidenza
                GestureDetector(
                  onTap: onCategoryTap, // Apre il picker per cambiare categoria
                  child: transaction.categoryId == null ||
                          transaction.categoryId.isEmpty
                      ? Tooltip(
                          message: 'Categoria non riconosciuta – da assegnare',
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.help_outline,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Container(
                          width: 28, // Larghezza fissa per forma tonda
                          height: 28, // Altezza fissa per forma tonda
                          decoration: BoxDecoration(
                            color: _getConfidenceColor(confidence),
                            shape: BoxShape.circle, // Forma tonda
                          ),
                          child: Icon(
                            _getConfidenceIcon(confidence),
                            size: 16, // Icona più grande
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(width: 6), // Spazio tra chip e checkbox

                // Checkbox selezione
                Checkbox(
                  value: transaction.isCorrected,
                  onChanged:
                      checkboxEnabled ? ((_) => onToggleSelection()) : null,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact, // Più compatto
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.85) return Colors.green;
    if (confidence >= 0.7) return Colors.orange;
    return Colors.red;
  }

  IconData _getConfidenceIcon(double confidence) {
    if (confidence > 0.85) return Icons.check;
    if (confidence >= 0.7) return Icons.warning;
    return Icons.help_outline;
  }

  void _showCategoryTooltip(BuildContext context, String categoryName) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Trova la posizione dell'icona
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    // Calcola la posizione del tooltip (a destra dell'icona)
    final tooltipPosition = Offset(
      position.dx +
          36, // A destra dell'icona (radius = 18, quindi +36 per essere a destra)
      position.dy + 9, // Centrato verticalmente sull'icona
    );

    // Crea l'overlay entry
    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: tooltipPosition.dx,
        top: tooltipPosition.dy - 12, // Centra verticalmente il tooltip
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              categoryName,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );

    // Mostra il tooltip
    overlay.insert(overlayEntry);

    // Nascondi il tooltip dopo 0.8 secondi
    Future.delayed(const Duration(milliseconds: 800), () {
      overlayEntry?.remove();
    });
  }
}
