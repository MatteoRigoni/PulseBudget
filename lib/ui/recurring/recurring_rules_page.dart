import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/recurring_rules_provider.dart';
import '../../model/recurring_rule.dart';
import '../../model/category.dart';
import 'new_recurring_rule_sheet.dart';
import '../../providers/recurring_bootstrap_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/categories_provider.dart';
import '../widgets/app_title_widget.dart';

class RecurringRulesPage extends ConsumerWidget {
  const RecurringRulesPage({Key? key}) : super(key: key);

  String _getFrequencyText(String rrule) {
    if (rrule.startsWith('FREQ=MONTHLY')) {
      return 'Mensile';
    } else if (rrule.startsWith('FREQ=WEEKLY')) {
      return 'Settimanale';
    } else if (rrule.startsWith('FREQ=YEARLY')) {
      return 'Annuale';
    }
    return 'Sconosciuta';
  }

  String _getCategoryName(String categoryId, List<Category> categories) {
    try {
      return categories.firstWhere((c) => c.id == categoryId).name;
    } catch (_) {
      return categoryId;
    }
  }

  IconData _getCategoryIcon(String categoryId, List<Category> categories) {
    try {
      return categories.firstWhere((c) => c.id == categoryId).icon;
    } catch (_) {
      return Icons.category_outlined;
    }
  }

  Color _getCategoryColor(String categoryId, List<Category> categories) {
    try {
      return categories.firstWhere((c) => c.id == categoryId).color;
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(recurringRulesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    // Gestisci stati di loading e error
    if (rulesAsync.isLoading || categoriesAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (rulesAsync.hasError || categoriesAsync.hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Errore nel caricamento'),
            ],
          ),
        ),
      );
    }

    final rules = rulesAsync.value ?? [];
    final categories = categoriesAsync.value ?? [];
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const AppTitleWidget(title: 'Ricorrenti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Ricalcola ricorrenti',
            onPressed: () async {
              final now = DateTime.now();
              // Forza il ricalcolo delle ricorrenze usando il notifier (come nella versione vecchia)
              executeRecurringBootstrapFromWidget(ref);

              // Mostra messaggio di debug
              final msg =
                  'Ricalcolo ricorrenti completato alle: ${now.toIso8601String()}';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
          ),
        ],
      ),
      body: rules.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat, size: 64, color: Colors.amber.shade400),
                  const SizedBox(height: 16),
                  Text('Nessuna regola ricorrente!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.grey.shade600)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rules.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, thickness: 0.5),
              itemBuilder: (context, index) {
                final rule = rules[index];
                return Dismissible(
                  key: Key(rule.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (direction) async {
                    await ref
                        .read(recurringRulesNotifierProvider.notifier)
                        .removeRule(rule.id);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Regola eliminata'),
                        action: SnackBarAction(
                          label: 'Ripristina',
                          onPressed: () async {
                            // TODO: Implementare ripristino con Firestore
                          },
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  child: ListTile(
                    leading: Icon(
                      _getCategoryIcon(rule.categoryId, categories),
                      color: _getCategoryColor(rule.categoryId, categories),
                    ),
                    title: Text(rule.name),
                    subtitle:
                        Text('Frequenza: ${_getFrequencyText(rule.rrule)}'),
                    trailing: Text(
                        '${rule.amount > 0 ? '+' : ''} ${rule.amount.toStringAsFixed(2)}'),
                  ),
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
}
