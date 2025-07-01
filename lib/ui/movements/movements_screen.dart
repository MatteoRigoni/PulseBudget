import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../../providers/transactions_provider.dart';
import '../../model/transaction.dart';
import 'transaction_card.dart';
import '../../providers/period_filter_provider.dart';

class MovementsScreen extends ConsumerStatefulWidget {
  const MovementsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends ConsumerState<MovementsScreen> {
  final _searchController = TextEditingController();
  final _searchSubject = BehaviorSubject<String>.seeded('');
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchSubject.debounceTime(const Duration(milliseconds: 300)).listen((q) {
      setState(() => _query = q);
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
    final transactions = ref.watch(transactionsProvider);
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
    final filtered = filteredByPeriod
        .where(
            (t) => t.description.toLowerCase().contains(_query.toLowerCase()))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimenti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {}, // Placeholder filtro
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
                  fillColor: theme.colorScheme.surfaceVariant,
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
                  child: Text('Nessun movimento trovato',
                      style: theme.textTheme.bodyLarge),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => TransactionCard(
                    transaction: filtered[i],
                    highlight: _query,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
