import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/recurring_rules_provider.dart';
import '../../model/recurring_rule.dart';
import 'dart:math';

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
  String? _paymentType;
  String _rrule = 'FREQ=MONTHLY';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nuova regola ricorrente',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Importo'),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Obbligatorio' : null,
              onSaved: (v) => _amount = double.tryParse(v ?? ''),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Categoria (id)'),
              validator: (v) => v == null || v.isEmpty ? 'Obbligatorio' : null,
              onSaved: (v) => _categoryId = v,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Tipo pagamento'),
              validator: (v) => v == null || v.isEmpty ? 'Obbligatorio' : null,
              onSaved: (v) => _paymentType = v,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Salva'),
            ),
          ],
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
          paymentType: _paymentType!,
          rrule: _rrule,
        );
        ref.read(recurringRulesProvider.notifier).addRule(rule);
        Navigator.of(context).pop();
      }
    }
  }
}
