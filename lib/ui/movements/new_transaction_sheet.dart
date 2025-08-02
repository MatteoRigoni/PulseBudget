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
import '../../providers/repository_providers.dart';

class NewTransactionSheet extends ConsumerStatefulWidget {
  final bool isIncome;
  final Transaction? transaction;
  final void Function()? onSaved;

  const NewTransactionSheet({
    super.key,
    required this.isIncome,
    this.transaction,
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
  final _focusNode = FocusNode();

  DateTime _selectedDate = DateTime.now();
  PaymentType _selectedPaymentType = PaymentType.cash;
  String? _selectedCategoryId;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _selectedDate = t.date;
      _selectedPaymentType = t.paymentType;
      _selectedCategoryId = t.categoryId;
      _amountController.text =
          t.amount.abs().toStringAsFixed(2).replaceAll('.', ',');
      _descriptionController.text = t.description;
    }
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
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      final finalAmount = widget.isIncome ? amount : -amount;

      // Ottieni la descrizione: se vuota, usa il nome della categoria
      String description = _descriptionController.text.trim();
      if (description.isEmpty && _selectedCategoryId != null) {
        final allCategoriesAsync = ref.read(categoriesProvider);
        final allCategories = allCategoriesAsync.value ?? [];
        final selectedCategory = allCategories.firstWhere(
          (cat) => cat.id == _selectedCategoryId,
          orElse: () => Category(
            id: 'default',
            name: 'Altro',
            icon: Icons.category_outlined,
            colorHex: '#BDBDBD',
            type: 'expense',
          ),
        );
        description = selectedCategory.name;
      }

      if (widget.transaction != null) {
        final updated = widget.transaction!.copyWith(
          amount: finalAmount,
          date: _selectedDate,
          description: description,
          paymentType: _selectedPaymentType,
        );
        await ref.read(transactionsNotifierProvider.notifier).update(updated);
      } else {
        final transaction = Transaction(
          amount: finalAmount,
          date: _selectedDate,
          description: description,
          categoryId: _selectedCategoryId ?? 'default',
          paymentType: _selectedPaymentType,
        );
        // Aggiungi la transazione al provider
        await ref.read(transactionsNotifierProvider.notifier).add(transaction);
      }

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
      locale: const Locale('it', 'IT'),
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
    final allCategoriesAsync = ref.watch(categoriesProvider);
    final allCategories = allCategoriesAsync.value ?? [];
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
                  widget.transaction != null
                      ? Icons.edit
                      : (widget.isIncome ? Icons.add : Icons.remove),
                  color: widget.transaction != null
                      ? theme.colorScheme.primary
                      : (widget.isIncome ? Colors.green : Colors.red),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.transaction != null
                      ? (widget.isIncome
                          ? 'Modifica Entrata'
                          : 'Modifica Uscita')
                      : (widget.isIncome
                          ? 'Nuova Entrata'
                          : 'Nuova Uscita'),
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GestureDetector(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Data',
                            border: OutlineInputBorder(),
                            fillColor: theme.colorScheme.surface,
                            filled: true,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy').format(_selectedDate),
                                style: theme.textTheme.bodyLarge,
                              ),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Campo Categoria (meno alto)
                    widget.transaction != null
                        ? InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Categoria',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              children: [
                                if (_selectedCategoryId != null) ...[
                                  Builder(
                                    builder: (context) {
                                      final cat = filteredCategories
                                          .firstWhereOrNull(
                                              (c) => c.id == _selectedCategoryId);
                                      if (cat == null) {
                                        return const SizedBox.shrink();
                                      }
                                      return CircleAvatar(
                                        backgroundColor: Color(int.parse(
                                            cat.colorHex
                                                .replaceFirst('#', '0xff'))),
                                        radius: 20,
                                        child: Icon(
                                          cat.icon,
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
                                ]
                              ],
                            ),
                          )
                        : FormField<String>(
                            validator: (value) {
                              if (_selectedCategoryId == null) {
                                return 'Seleziona una categoria';
                              }
                              return null;
                            },
                            builder: (state) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    FocusScope.of(context).unfocus();
                                    String search = '';
                                    final selected =
                                        await showModalBottomSheet<Category>(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) {
                                        return StatefulBuilder(
                                          builder: (context, setModalState) {
                                            final filtered = filteredCategories
                                                .where((cat) => cat.name
                                                    .toLowerCase()
                                                    .contains(
                                                        search.toLowerCase()))
                                                .toList();
                                            return Container(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.95,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surface,
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                        top: Radius.circular(
                                                            24)),
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
                                                    decoration:
                                                        const InputDecoration(
                                                      hintText:
                                                          'Cerca categoria...',
                                                      prefixIcon:
                                                          Icon(Icons.search),
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                    onChanged: (v) =>
                                                        setModalState(
                                                            () => search = v),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Expanded(
                                                    child: ListView.separated(
                                                      itemCount: filtered.length,
                                                      separatorBuilder: (_, __) =>
                                                          const Divider(
                                                              height: 1),
                                                      itemBuilder: (context, i) {
                                                        final cat = filtered[i];
                                                        final selected =
                                                            _selectedCategoryId ==
                                                                cat.id;
                                                        return ListTile(
                                                          leading: CircleAvatar(
                                                            backgroundColor:
                                                                Color(int.parse(
                                                                    cat.colorHex
                                                                        .replaceFirst(
                                                                            '#',
                                                                            '0xff'))),
                                                            radius: 24,
                                                            child: Icon(
                                                              cat.icon,
                                                              color: Colors
                                                                  .white,
                                                              size: 32,
                                                            ),
                                                          ),
                                                          title: Text(cat.name,
                                                              style: const TextStyle(
                                                                  fontSize: 18)),
                                                          tileColor: selected
                                                              ? Color(int.parse(cat
                                                                      .colorHex
                                                                      .replaceFirst(
                                                                          '#',
                                                                          '0xff')))
                                                                  .withOpacity(
                                                                      0.15)
                                                              : null,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12)),
                                                          onTap: () {
                                                            FocusScope.of(
                                                                    context)
                                                                .unfocus();
                                                            Navigator.of(
                                                                    context)
                                                                .pop(cat);
                                                          },
                                                          trailing: selected
                                                              ? const Icon(
                                                                  Icons.check,
                                                                  color: Colors
                                                                      .green)
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
                                      setState(
                                          () => _selectedCategoryId = selected.id);
                                      final payment = await ref
                                          .read(databaseServiceProvider)
                                          .getPaymentTypeForCategory(selected.id);
                                      if (payment != null) {
                                        setState(
                                            () => _selectedPaymentType = payment);
                                      }
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        FocusScope.of(context)
                                            .requestFocus(_focusNode);
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Theme.of(context).dividerColor),
                                      borderRadius: BorderRadius.circular(8),
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                    ),
                                    child: Row(
                                      children: [
                                        if (_selectedCategoryId != null) ...[
                                          Builder(
                                            builder: (context) {
                                              final cat = filteredCategories
                                                  .firstWhereOrNull((c) =>
                                                      c.id ==
                                                      _selectedCategoryId);
                                              if (cat == null) {
                                                return const SizedBox.shrink();
                                              }
                                              return CircleAvatar(
                                                backgroundColor: Color(
                                                    int.parse(cat.colorHex
                                                        .replaceFirst(
                                                            '#', '0xff'))),
                                                radius: 20,
                                                child: Icon(
                                                  cat.icon,
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
                                                        (c) =>
                                                            c.id ==
                                                            _selectedCategoryId)
                                                    ?.name ??
                                                '',
                                            style:
                                                const TextStyle(fontSize: 18),
                                          ),
                                        ] else
                                          Text('Seleziona categoria',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .hintColor,
                                                  fontSize: 18)),
                                        const Spacer(),
                                        const Icon(Icons.expand_more),
                                      ],
                                    ),
                                  ),
                                ),
                                if (state.hasError)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(left: 8, top: 4),
                                    child: Text(
                                      state.errorText!,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                          fontSize: 13),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                    const SizedBox(height: 16),
                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      focusNode: _focusNode,
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
