import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../model/transaction.dart';
import '../../model/payment_type.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/categories_provider.dart';
import '../../model/category.dart';
import 'package:collection/collection.dart';

class NewTransactionSheet extends ConsumerStatefulWidget {
  final bool isIncome;
  final void Function()? onSaved;

  const NewTransactionSheet({
    super.key,
    required this.isIncome,
    this.onSaved,
  });

  @override
  ConsumerState<NewTransactionSheet> createState() =>
      _NewTransactionSheetState();
}

class _NewTransactionSheetState extends ConsumerState<NewTransactionSheet>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  PaymentType _selectedPaymentType = PaymentType.cash;
  String? _selectedCategoryId;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      final finalAmount = widget.isIncome ? amount : -amount;

      final transaction = Transaction(
        amount: finalAmount,
        date: _selectedDate,
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategoryId ?? 'default',
        paymentType: _selectedPaymentType,
      );

      // Aggiungi la transazione al provider
      ref.read(transactionsProvider.notifier).add(transaction);

      // Chiudi la sheet
      Navigator.of(context).pop();

      // Trigger animazione saldo
      _animationController.forward().then((_) {
        _animationController.reverse();
      });

      widget.onSaved?.call();
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'it_IT',
      symbol: '€',
      decimalDigits: 2,
    );

    // Ottieni le categorie dal provider
    final allCategories = ref.watch(categoriesProvider);
    final filteredCategories = allCategories
        .where((cat) =>
            widget.isIncome ? cat.type == 'income' : cat.type == 'expense')
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  widget.isIncome ? Icons.add : Icons.remove,
                  color: widget.isIncome ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isIncome ? 'Nuova Entrata' : 'Nuova Uscita',
                  style: theme.textTheme.headlineSmall,
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Campo Data (spostato sopra)
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10), // meno alto
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Data',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM/yyyy')
                                      .format(_selectedDate),
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Campo Categoria (meno alto)
                    GestureDetector(
                      onTap: () async {
                        String search = '';
                        final selected = await showModalBottomSheet<Category>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, setModalState) {
                                final filtered = filteredCategories
                                    .where((cat) => cat.name
                                        .toLowerCase()
                                        .contains(search.toLowerCase()))
                                    .toList();
                                return Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.95,
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(24)),
                                  ),
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text('Seleziona categoria',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge),
                                      const SizedBox(height: 12),
                                      TextField(
                                        decoration: const InputDecoration(
                                          hintText: 'Cerca categoria...',
                                          prefixIcon: Icon(Icons.search),
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (v) =>
                                            setModalState(() => search = v),
                                      ),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: ListView.separated(
                                          itemCount: filtered.length,
                                          separatorBuilder: (_, __) =>
                                              const Divider(height: 1),
                                          itemBuilder: (context, i) {
                                            final cat = filtered[i];
                                            final selected =
                                                _selectedCategoryId == cat.id;
                                            return ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor: Color(
                                                    int.parse(cat
                                                        .colorHex
                                                        .replaceFirst(
                                                            '#', '0xff'))),
                                                radius: 24,
                                                child: Icon(
                                                  IconData(cat.iconCodePoint,
                                                      fontFamily:
                                                          'MaterialIcons'),
                                                  color: Colors.white,
                                                  size: 32,
                                                ),
                                              ),
                                              title: Text(cat.name,
                                                  style: const TextStyle(
                                                      fontSize: 18)),
                                              tileColor: selected
                                                  ? Color(int.parse(cat.colorHex
                                                          .replaceFirst(
                                                              '#', '0xff')))
                                                      .withOpacity(0.15)
                                                  : null,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              onTap: () => Navigator.of(context)
                                                  .pop(cat),
                                              trailing: selected
                                                  ? const Icon(Icons.check,
                                                      color: Colors.green)
                                                  : null,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                        if (selected != null) {
                          setState(() => _selectedCategoryId = selected.id);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12), // meno alto
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        child: Row(
                          children: [
                            if (_selectedCategoryId != null) ...[
                              Builder(
                                builder: (context) {
                                  final cat =
                                      filteredCategories.firstWhereOrNull(
                                          (c) => c.id == _selectedCategoryId);
                                  if (cat == null)
                                    return const SizedBox.shrink();
                                  return CircleAvatar(
                                    backgroundColor: Color(int.parse(cat
                                        .colorHex
                                        .replaceFirst('#', '0xff'))),
                                    radius: 20,
                                    child: Icon(
                                      IconData(cat.iconCodePoint,
                                          fontFamily: 'MaterialIcons'),
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              Text(
                                filteredCategories
                                        .firstWhereOrNull(
                                            (c) => c.id == _selectedCategoryId)
                                        ?.name ??
                                    '',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ] else
                              Text('Seleziona categoria',
                                  style: TextStyle(
                                      color: Theme.of(context).hintColor,
                                      fontSize: 18)),
                            const Spacer(),
                            const Icon(Icons.expand_more),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^[0-9,]{0,9}(,[0-9]{0,2})?')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Importo',
                        prefixText: '€ ',
                        border: const OutlineInputBorder(),
                        suffixIcon: Icon(
                          widget.isIncome ? Icons.add : Icons.remove,
                          color: widget.isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci un importo';
                        }
                        final amount = double.tryParse(
                            value.replaceAll('.', '').replaceAll(',', '.'));
                        if (amount == null || amount <= 0) {
                          return 'Inserisci un importo valido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrizione',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Payment Type Selector
                    Text(
                      'Tipo di Pagamento',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<PaymentType>(
                      segments: const [
                        ButtonSegment(
                          value: PaymentType.cash,
                          label: Text('CASH'),
                          icon: Icon(Icons.money),
                        ),
                        ButtonSegment(
                          value: PaymentType.bancomat,
                          label: Text('DEB'),
                          icon: Icon(Icons.credit_card),
                        ),
                        ButtonSegment(
                          value: PaymentType.creditCard,
                          label: Text('CRED'),
                          icon: Icon(Icons.credit_card_outlined),
                        ),
                        ButtonSegment(
                          value: PaymentType.bankTransfer,
                          label: Text('BANK'),
                          icon: Icon(Icons.swap_horiz),
                        ),
                      ],
                      selected: {_selectedPaymentType},
                      onSelectionChanged: (Set<PaymentType> selection) {
                        setState(() {
                          _selectedPaymentType = selection.first;
                        });
                      },
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Annulla'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: _saveTransaction,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor:
                                  widget.isIncome ? Colors.green : Colors.red,
                            ),
                            child: const Text('Salva'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
