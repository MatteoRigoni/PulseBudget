import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/recurring_rules_provider.dart';
import '../../model/recurring_rule.dart';
import '../../providers/categories_provider.dart';
import '../../model/category.dart';
import '../../model/payment_type.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class NewRecurringRuleSheet extends ConsumerStatefulWidget {
  const NewRecurringRuleSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<NewRecurringRuleSheet> createState() =>
      _NewRecurringRuleSheetState();
}

class _NewRecurringRuleSheetState extends ConsumerState<NewRecurringRuleSheet> {
  final _formKey = GlobalKey<FormState>();
  double? _amount;
  String? _categoryId;
  PaymentType _paymentType = PaymentType.cash;
  String _rrule = 'FREQ=MONTHLY';
  String _periodicity = 'Mensile';
  String _categoryType = 'expense'; // Default: uscite
  DateTime _startDate = DateTime.now();
  final Map<String, String> _periodicityToRRule = {
    'Mensile': 'FREQ=MONTHLY',
    'Settimanale': 'FREQ=WEEKLY',
    'Annuale': 'FREQ=YEARLY',
  };
  final Map<String, String> _categoryTypeLabels = {
    'expense': 'Uscita',
    'income': 'Entrata',
  };
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider);

    final filteredCategories =
        categories.where((cat) => cat.type == _categoryType).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Nuova regola ricorrente',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              // Data di inizio (ora in cima)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 62)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data di inizio',
                      border: OutlineInputBorder(),
                      fillColor: theme.colorScheme.surface,
                      filled: true,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}'),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              // Periodicità
              DropdownButtonFormField<String>(
                value: _periodicity,
                decoration: const InputDecoration(labelText: 'Periodicità'),
                items: _periodicityToRRule.keys
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _periodicity = v!;
                    _rrule = _periodicityToRRule[v]!;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Filtro tipo categoria
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'expense', label: Text('Uscita')),
                    ButtonSegment(value: 'income', label: Text('Entrata')),
                  ],
                  selected: {_categoryType},
                  onSelectionChanged: (s) {
                    setState(() => _categoryType = s.first);
                    // Reset categoria selezionata se non più valida
                    if (_categoryId != null &&
                        !filteredCategories.any((c) => c.id == _categoryId)) {
                      setState(() => _categoryId = null);
                    }
                  },
                ),
              ),
              // Selettore categoria
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
                            height: MediaQuery.of(context).size.height * 0.95,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24)),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Seleziona categoria',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
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
                                      final selected = _categoryId == cat.id;
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Color(int.parse(cat
                                              .colorHex
                                              .replaceFirst('#', '0xff'))),
                                          radius: 24,
                                          child: Icon(
                                            IconData(cat.iconCodePoint,
                                                fontFamily: 'MaterialIcons'),
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ),
                                        title: Text(cat.name,
                                            style:
                                                const TextStyle(fontSize: 18)),
                                        tileColor: selected
                                            ? Color(int.parse(cat.colorHex
                                                    .replaceFirst('#', '0xff')))
                                                .withOpacity(0.15)
                                            : null,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        onTap: () =>
                                            Navigator.of(context).pop(cat),
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
                    setState(() => _categoryId = selected.id);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surface,
                  ),
                  child: Row(
                    children: [
                      if (_categoryId != null) ...[
                        Builder(
                          builder: (context) {
                            final cat = filteredCategories
                                .firstWhere((c) => c.id == _categoryId);
                            return CircleAvatar(
                              backgroundColor: Color(int.parse(
                                  cat.colorHex.replaceFirst('#', '0xff'))),
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
                              .firstWhere((c) => c.id == _categoryId)
                              .name,
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
              // Importo
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^[0-9,]*')),
                ],
                decoration: InputDecoration(
                  labelText: 'Importo',
                  prefixText: '€ ',
                  border: const OutlineInputBorder(),
                  fillColor: theme.colorScheme.surface,
                  filled: true,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obbligatorio';
                  final amount = double.tryParse(
                      v.replaceAll('.', '').replaceAll(',', '.'));
                  if (amount == null || amount <= 0)
                    return 'Importo non valido';
                  return null;
                },
                onChanged: (value) {
                  String cleaned =
                      value.replaceAll('.', '').replaceAll(',', '.');
                  if (cleaned.isEmpty) {
                    _amountController.value = TextEditingValue(
                      text: '',
                      selection: TextSelection.collapsed(offset: 0),
                    );
                    return;
                  }
                  double? number = double.tryParse(cleaned);
                  if (number == null) return;
                  final formatter = NumberFormat.currency(
                      locale: 'it_IT', symbol: '', decimalDigits: 2);
                  String newText = formatter.format(number).trim();
                  _amountController.value = TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(offset: newText.length),
                  );
                },
                onSaved: (v) => _amount = double.tryParse(
                    v!.replaceAll('.', '').replaceAll(',', '.')),
              ),
              const SizedBox(height: 16),
              // Tipo pagamento
              Text('Tipo di Pagamento', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<PaymentType>(
                segments: const [
                  ButtonSegment(
                      value: PaymentType.cash,
                      label: Text('CASH'),
                      icon: Icon(Icons.money)),
                  ButtonSegment(
                      value: PaymentType.bancomat,
                      label: Text('DEB'),
                      icon: Icon(Icons.credit_card)),
                  ButtonSegment(
                      value: PaymentType.creditCard,
                      label: Text('CRED'),
                      icon: Icon(Icons.credit_card_outlined)),
                  ButtonSegment(
                      value: PaymentType.bankTransfer,
                      label: Text('BANK'),
                      icon: Icon(Icons.swap_horiz)),
                ],
                selected: {_paymentType},
                onSelectionChanged: (Set<PaymentType> selection) {
                  setState(() {
                    _paymentType = selection.first;
                  });
                },
              ),
              const SizedBox(height: 32),
              // Bottoni Annulla e Salva
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
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Color(0xFF40C4FF),
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
    );
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      if (_amount != null && _categoryId != null && _paymentType != null) {
        final rule = RecurringRule(
          id: UniqueKey().toString(),
          amount: _amount!,
          categoryId: _categoryId!,
          paymentType: _paymentType.name,
          rrule: _rrule,
          startDate: _startDate,
        );
        ref.read(recurringRulesProvider.notifier).addRule(rule);
        Navigator.of(context).pop();
      }
    }
  }
}
