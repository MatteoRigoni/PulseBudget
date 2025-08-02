import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../../providers/transactions_provider.dart';
import '../../model/transaction.dart';
import 'transaction_card.dart';
import 'new_transaction_sheet.dart';
import '../../providers/period_filter_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/snapshot_provider.dart';
import '../../model/payment_type.dart';
import '../widgets/app_title_widget.dart';
import '../widgets/custom_snackbar.dart';

class MovementsScreen extends ConsumerStatefulWidget {
  const MovementsScreen({Key? key, this.initialCategoryId}) : super(key: key);

  final String? initialCategoryId;

  @override
  ConsumerState<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends ConsumerState<MovementsScreen> {
  final _searchController = TextEditingController();
  final _searchSubject = BehaviorSubject<String>.seeded('');
  String _query = '';

  // Filtri avanzati
  String? _selectedCategoryId;
  Set<PaymentType> _selectedPaymentTypes = {};
  double? _minAmount;
  double? _maxAmount;
  String _orderBy = 'date_desc';

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    _searchSubject.debounceTime(const Duration(milliseconds: 300)).listen((q) {
      setState(() => _query = q);
    });
    // Reset filtri avanzati ogni volta che si entra
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _selectedCategoryId = widget.initialCategoryId;
        _selectedPaymentTypes = {};
        _minAmount = null;
        _maxAmount = null;
        _orderBy = 'date_desc';
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periodFilter = ref.watch(periodFilterProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final accounts = ref.watch(entityProvider);

    // Gestisci stati di loading e error
    if (transactionsAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (transactionsAsync.hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Errore nel caricamento: ${transactionsAsync.error}'),
            ],
          ),
        ),
      );
    }

    final transactions = transactionsAsync.value ?? [];
    final categories = categoriesAsync.value ?? [];

    // Applica filtro temporale come nella home
    List<Transaction> filteredByPeriod = transactions;
    if (periodFilter.period == 'Mese') {
      filteredByPeriod = transactions
          .where((t) =>
              t.date.month == periodFilter.month &&
              t.date.year == periodFilter.year)
          .toList();
    } else {
      filteredByPeriod =
          transactions.where((t) => t.date.year == periodFilter.year).toList();
    }
    // Applica filtri avanzati
    var filtered = filteredByPeriod.where((t) {
      if (_selectedCategoryId != null && t.categoryId != _selectedCategoryId)
        return false;
      if (_selectedPaymentTypes.isNotEmpty &&
          !_selectedPaymentTypes.contains(t.paymentType)) return false;
      if (_minAmount != null && t.amount.abs() < _minAmount!) return false;
      if (_maxAmount != null && t.amount.abs() > _maxAmount!) return false;
      return t.description.toLowerCase().contains(_query.toLowerCase());
    }).toList();
    // Ordina
    if (_orderBy == 'date_desc') {
      filtered.sort((a, b) => b.date.compareTo(a.date));
    } else if (_orderBy == 'date_asc') {
      filtered.sort((a, b) => a.date.compareTo(b.date));
    } else if (_orderBy == 'amount_desc') {
      filtered.sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
    } else if (_orderBy == 'amount_asc') {
      filtered.sort((a, b) => a.amount.abs().compareTo(b.amount.abs()));
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(Icons.list,
                size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Movimenti',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) {
                  return _FilterSheet(
                    categories: categories,
                    selectedCategoryId: _selectedCategoryId,
                    selectedPaymentTypes: _selectedPaymentTypes,
                    minAmount: _minAmount,
                    maxAmount: _maxAmount,
                    orderBy: _orderBy,
                    onApply: (catId, payTypes, minA, maxA, order) {
                      setState(() {
                        _selectedCategoryId = catId;
                        _selectedPaymentTypes = payTypes;
                        _minAmount = minA;
                        _maxAmount = maxA;
                        _orderBy = order;
                      });
                      Navigator.of(context).pop();
                    },
                    onReset: () {
                      setState(() {
                        _selectedCategoryId = null;
                        _selectedPaymentTypes = {};
                        _minAmount = null;
                        _maxAmount = null;
                        _orderBy = 'date_desc';
                      });
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _searchSubject.add,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchSubject.add('');
                          },
                        )
                      : null,
                  hintText: 'Cerca movimenti…',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
              ),
            ),
            if (filtered.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long,
                          size: 64, color: Colors.amber.shade400),
                      const SizedBox(height: 16),
                      Text('Nessun movimento trovato!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final transaction = filtered[i];
                    return Dismissible(
                      key: ValueKey(transaction.id),
                      background: Container(
                        color: Theme.of(context).colorScheme.primary,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 24),
                        child: const Row(
                          children: [
                            Icon(Icons.edit, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Modifica',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Elimina',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.delete, color: Colors.white),
                          ],
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => NewTransactionSheet(
                              isIncome: transaction.amount > 0,
                              transaction: transaction,
                            ),
                          );
                          return false;
                        }
                        return true;
                      },
                      onDismissed: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          await ref
                              .read(transactionsNotifierProvider.notifier)
                              .delete(transaction.id);
                          CustomSnackBar.show(context,
                              message: 'Movimento eliminato');
                        }
                      },
                      child: TransactionCard(
                        transaction: transaction,
                        highlight: _query,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final List categories;
  final String? selectedCategoryId;
  final Set<PaymentType> selectedPaymentTypes;
  final double? minAmount;
  final double? maxAmount;
  final String orderBy;
  final void Function(String?, Set<PaymentType>, double?, double?, String)
      onApply;
  final VoidCallback onReset;
  const _FilterSheet({
    required this.categories,
    required this.selectedCategoryId,
    required this.selectedPaymentTypes,
    required this.minAmount,
    required this.maxAmount,
    required this.orderBy,
    required this.onApply,
    required this.onReset,
    Key? key,
  }) : super(key: key);
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _selectedCategoryId = widget.selectedCategoryId;
  late Set<PaymentType> _selectedPaymentTypes =
      Set.from(widget.selectedPaymentTypes);
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  late String _orderBy = widget.orderBy;

  @override
  void initState() {
    super.initState();
    _minAmountController =
        TextEditingController(text: widget.minAmount?.toString() ?? '');
    _maxAmountController =
        TextEditingController(text: widget.maxAmount?.toString() ?? '');
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Filtra movimenti',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            // Categoria
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tutte')),
                ...widget.categories
                    .map<DropdownMenuItem<String>>((cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        )),
              ],
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
            const SizedBox(height: 16),
            // Tipo pagamento
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Tipo di pagamento'),
              child: Wrap(
                spacing: 8,
                children: PaymentType.values
                    .map((pt) => FilterChip(
                          label: Text(_getPaymentTypeLabel(pt)),
                          selected: _selectedPaymentTypes.contains(pt),
                          onSelected: (sel) => setState(() {
                            if (sel) {
                              _selectedPaymentTypes.add(pt);
                            } else {
                              _selectedPaymentTypes.remove(pt);
                            }
                          }),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            // Importo min/max
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minAmountController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Importo minimo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxAmountController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Importo massimo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Ordinamento
            DropdownButtonFormField<String>(
              value: _orderBy,
              decoration: const InputDecoration(labelText: 'Ordina per'),
              items: const [
                DropdownMenuItem(
                    value: 'date_desc',
                    child: Text('Data (più recenti prima)')),
                DropdownMenuItem(
                    value: 'date_asc', child: Text('Data (più vecchi prima)')),
                DropdownMenuItem(
                    value: 'amount_desc', child: Text('Importo (decrescente)')),
                DropdownMenuItem(
                    value: 'amount_asc', child: Text('Importo (crescente)')),
              ],
              onChanged: (v) => setState(() => _orderBy = v ?? 'date_desc'),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onReset();
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Azzera filtri'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      double? minA = double.tryParse(
                          _minAmountController.text.replaceAll(',', '.'));
                      double? maxA = double.tryParse(
                          _maxAmountController.text.replaceAll(',', '.'));
                      widget.onApply(_selectedCategoryId, _selectedPaymentTypes,
                          minA, maxA, _orderBy);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Text('Applica filtri'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPaymentTypeLabel(PaymentType type) {
    switch (type) {
      case PaymentType.cash:
        return 'CASH';
      case PaymentType.bancomat:
        return 'DEB';
      case PaymentType.creditCard:
        return 'CRED';
      case PaymentType.bankTransfer:
        return 'BANK';
      default:
        return type.name;
    }
  }
}
