import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/transactions_provider.dart';
import '../movements/new_transaction_sheet.dart';
import '../../providers/recurring_bootstrap_provider.dart';
import '../movements/movements_screen.dart';
import '../../model/transaction.dart';
import '../../model/category.dart';
import '../../providers/categories_provider.dart';
import '../report/analysis_sheet.dart';
import '../categories/categories_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _period = 'Mese';
  int _selectedMonth = 0;
  int _selectedYear = DateTime.now().year;

  late AnimationController _balanceAnimController;
  late Animation<double> _balanceScale;

  @override
  void initState() {
    super.initState();
    _balanceAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _balanceScale = _balanceAnimController.drive(Tween(begin: 0.95, end: 1.0));
    _balanceAnimController.value = 1.0;
    Future.microtask(() => ref.read(recurringBootstrapProvider));
  }

  @override
  void dispose() {
    _balanceAnimController.dispose();
    super.dispose();
  }

  void _showNewTransactionSheet(bool isIncome) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NewTransactionSheet(
        isIncome: isIncome,
        onSaved: () {
          _balanceAnimController.forward(from: 0.95);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final transactions = ref.watch(transactionsProvider);
    final filtered = transactions.where((t) {
      if (_period == 'Mese') {
        return t.date.month == _selectedMonth + 1 &&
            t.date.year == _selectedYear;
      } else {
        return t.date.year == _selectedYear;
      }
    }).toList();
    final entrate = filtered
        .where((t) => t.amount > 0)
        .fold<double>(0, (s, t) => s + t.amount);
    final uscite = filtered
        .where((t) => t.amount < 0)
        .fold<double>(0, (s, t) => s + t.amount);
    final saldo = entrate + uscite;

    Color byBalance(double value) {
      if (value > 0) return Colors.greenAccent;
      if (value < 0) return Colors.redAccent;
      return Colors.white;
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('BilancioMe'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) {
              if (value == 'import') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Import non ancora implementato')),
                );
              } else if (value == 'categories') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload, size: 20),
                    SizedBox(width: 8),
                    Text('Carica dati da Estratto conto'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'categories',
                child: Row(
                  children: [
                    Icon(Icons.category, size: 20),
                    SizedBox(width: 8),
                    Text('Categorie'),
                  ],
                ),
              ),
              // Altre voci di menu qui
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PeriodSegmented
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Mese', label: Text('Mese')),
                  ButtonSegment(value: 'Anno', label: Text('Anno')),
                ],
                selected: <String>{_period},
                onSelectionChanged: (s) {
                  setState(() => _period = s.first);
                },
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(MaterialState.selected)) {
                      return theme.colorScheme.surface;
                    }
                    return theme.colorScheme.surfaceVariant;
                  }),
                ),
              ),
            ),
            // MonthChipsRow or YearChipsRow
            SizedBox(
              height: 48,
              child: _period == 'Mese'
                  ? ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: 12,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        const months = [
                          'Gennaio',
                          'Febbraio',
                          'Marzo',
                          'Aprile',
                          'Maggio',
                          'Giugno',
                          'Luglio',
                          'Agosto',
                          'Settembre',
                          'Ottobre',
                          'Novembre',
                          'Dicembre',
                        ];
                        return FilterChip(
                          label: Text(months[i]),
                          selected: i == _selectedMonth,
                          onSelected: (_) {
                            setState(() => _selectedMonth = i);
                          },
                        );
                      },
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final year = now.year - (2 - i);
                        return FilterChip(
                          label: Text(year.toString()),
                          selected: year == _selectedYear,
                          onSelected: (_) {
                            setState(() => _selectedYear = year);
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            // BalanceCard
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Analysis non ancora implementato')),
                  );
                },
                child: ScaleTransition(
                  scale: _balanceScale,
                  child: Container(
                    height: 200,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: saldo > 0
                            ? [Colors.green.shade900, Colors.green.shade400]
                            : saldo < 0
                                ? [Colors.red.shade900, Colors.red.shade400]
                                : [Colors.black, Color(0xFF222222)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Chip con solo immagine assets
                            Container(
                              width: 38,
                              height: 32,
                              margin: const EdgeInsets.only(bottom: 20, top: 0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              clipBehavior: Clip.none,
                              child: Image.asset(
                                'assets/chip.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Saldo',
                                    style: theme.textTheme.labelLarge
                                        ?.copyWith(color: Colors.white70)),
                                Text(
                                  '€ ${saldo.toStringAsFixed(2)}',
                                  style: theme.textTheme.displayMedium
                                      ?.copyWith(color: byBalance(saldo)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Entrate
                            Row(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add,
                                        color: Colors.white, size: 28),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Entrate',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(color: Colors.white)),
                                    const SizedBox(height: 2),
                                    Text('€ ${entrate.toStringAsFixed(2)}',
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(color: Colors.white)),
                                  ],
                                ),
                              ],
                            ),
                            // Uscite
                            Row(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.remove,
                                        color: Colors.white, size: 28),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Uscite',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(color: Colors.white)),
                                    const SizedBox(height: 2),
                                    Text('€ ${uscite.abs().toStringAsFixed(2)}',
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(color: Colors.white)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ExpansionTile per categorie peggiori
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _MainCategoriesPanel(
                period: _period,
                selectedMonth: _selectedMonth,
                selectedYear: _selectedYear,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      // Action FABs
      floatingActionButton: Stack(
        children: [
          // Entrata FAB
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 32),
              child: SizedBox(
                width: 58,
                height: 58,
                child: FloatingActionButton(
                  heroTag: "entrata",
                  backgroundColor: Color(0xFF40C4FF),
                  foregroundColor: Colors.white,
                  elevation: 12,
                  shape: const CircleBorder(),
                  onPressed: () => _showNewTransactionSheet(true),
                  child: const Icon(Icons.add,
                      size: 36, color: Colors.white, weight: 800),
                ),
              ),
            ),
          ),
          // Uscita FAB
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 32),
              child: SizedBox(
                width: 58,
                height: 58,
                child: FloatingActionButton(
                  heroTag: "uscita",
                  backgroundColor: Color(0xFF424242),
                  foregroundColor: Colors.white,
                  elevation: 12,
                  shape: const CircleBorder(),
                  onPressed: () => _showNewTransactionSheet(false),
                  child: const Icon(Icons.remove,
                      size: 36, color: Colors.white, weight: 800),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _MainCategoriesPanel extends ConsumerStatefulWidget {
  final String period;
  final int selectedMonth;
  final int selectedYear;
  const _MainCategoriesPanel(
      {required this.period,
      required this.selectedMonth,
      required this.selectedYear,
      Key? key})
      : super(key: key);

  @override
  ConsumerState<_MainCategoriesPanel> createState() =>
      _MainCategoriesPanelState();
}

class _MainCategoriesPanelState extends ConsumerState<_MainCategoriesPanel> {
  bool showExpenses = true;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final transactions = ref.watch(transactionsProvider);
    List<Transaction> filtered = transactions;
    if (widget.period == 'Mese') {
      filtered = transactions
          .where((t) =>
              t.date.month == widget.selectedMonth + 1 &&
              t.date.year == widget.selectedYear)
          .toList();
    } else {
      filtered = transactions
          .where((t) => t.date.year == widget.selectedYear)
          .toList();
    }
    // Filtra per tipo
    final filteredCategories = categories
        .where((c) => c.type == (showExpenses ? 'expense' : 'income'))
        .toList();
    // Aggrega per categoria
    final Map<String, double> totals = {};
    for (final t in filtered) {
      if ((showExpenses && t.amount < 0) || (!showExpenses && t.amount > 0)) {
        totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
      }
    }
    final List<MapEntry<Category, double>> sorted = [
      for (final c in filteredCategories)
        if (totals.containsKey(c.id)) MapEntry(c, totals[c.id]!)
    ]..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 0, bottom: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(showExpenses ? Icons.trending_down : Icons.trending_up,
                    color: showExpenses ? Colors.red : Colors.green),
                const SizedBox(width: 8),
                Text(showExpenses ? 'Spese principali' : 'Incassi principali',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                IconButton(
                  icon: Icon(
                      showExpenses
                          ? Icons.arrow_circle_up
                          : Icons.arrow_circle_down,
                      color: Theme.of(context).colorScheme.primary),
                  tooltip: showExpenses ? 'Mostra incassi' : 'Mostra spese',
                  onPressed: () => setState(() => showExpenses = !showExpenses),
                ),
              ],
            ),
            if (sorted.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child:
                    Text('Nessun dato significativo nel periodo selezionato.'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sorted.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, thickness: 0.5),
                itemBuilder: (context, idx) {
                  final entry = sorted[idx];
                  return SizedBox(
                    height: 38,
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 0),
                      leading: Icon(entry.key.icon,
                          color: entry.key.color, size: 22),
                      title: Text(entry.key.name,
                          style: const TextStyle(fontSize: 15)),
                      trailing: Text(
                        (entry.value < 0 ? '-' : '+') +
                            entry.value.abs().toStringAsFixed(2) +
                            ' €',
                        style: TextStyle(
                          color: entry.value < 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
