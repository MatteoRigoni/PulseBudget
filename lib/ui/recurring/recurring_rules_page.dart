import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/recurring_rules_provider.dart';
import '../../model/recurring_rule.dart';
import 'new_recurring_rule_sheet.dart';

class RecurringRulesPage extends ConsumerWidget {
  const RecurringRulesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(recurringRulesProvider);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Ricorrenti'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rules.length,
        separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
        itemBuilder: (context, index) {
          final rule = rules[index];
          return ListTile(
            leading: const Icon(Icons.repeat),
            title: Text(rule.categoryId), // Da sostituire con nome categoria
            subtitle: Text('Frequenza: Mensile'), // Da estrarre da rrule
            trailing: Text(
                '${rule.amount > 0 ? '+' : ''} ${rule.amount.toStringAsFixed(2)}'),
            onLongPress: () => _showDeleteDialog(context, ref, rule),
          );
        },
      ),
      floatingActionButton: FilledButton.icon(
        onPressed: () => _showNewRuleSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuova regola'),
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: Theme.of(context).textTheme.labelLarge,
          elevation: 8,
        ),
      ),
    );
  }

  void _showNewRuleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NewRecurringRuleSheet(),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, RecurringRule rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina regola ricorrente'),
        content: const Text('Sei sicuro di voler eliminare questa regola?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              ref.read(recurringRulesProvider.notifier).removeRule(rule.id);
              Navigator.of(context).pop();
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}
