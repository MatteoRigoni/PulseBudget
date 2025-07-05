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
import 'package:intl/intl.dart';
import '../../providers/period_filter_provider.dart';
import '../../providers/recurring_rules_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const kAppGreen = Color(0xFF2ECC71); // verde bilancio
  static const kAppRed = Color(0xFFd32f2f); // rosso acceso

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
  final NumberFormat currencyFormat = NumberFormat('###,##0.00', 'it_IT');
  late final ScrollController _monthScrollController;
  late List<DateTime> _monthsList;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Genera lista mesi ultimi 3 anni
    _monthsList = List.generate(36, (i) {
      final date = DateTime(now.year, now.month - 35 + i, 1);
      return date;
    });
    // Trova l'indice del mese corrente
    final currentIndex = _monthsList
        .indexWhere((d) => d.year == now.year && d.month == now.month);
    if (currentIndex >= 0) {
      _selectedYear = _monthsList[currentIndex].year;
      _selectedMonth = _monthsList[currentIndex].month - 1;
    } else {
      _selectedYear = now.year;
      _selectedMonth = now.month - 1;
    }
    _monthScrollController = ScrollController(
      initialScrollOffset: (currentIndex >= 0 ? currentIndex : 35) * 84.0,
    );
    print(
        '[DEBUG] initState: anno=${_selectedYear}, mese=${_selectedMonth + 1}');
    _balanceAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _balanceScale = _balanceAnimController.drive(Tween(begin: 0.95, end: 1.0));
    _balanceAnimController.value = 1.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Leggi i dati delle regole e transazioni
      final rules = ref.read(recurringRulesProvider);
      final transactions = ref.read(transactionsProvider);
      final now = DateTime.now();
      // Chiama il bootstrap (ricalcolo)
      ref.read(recurringBootstrapProvider);
      // Mostra uno SnackBar con i dati di debug
      final msg = '[DEBUG] Ricalcolo ricorrenti\nnow: '
          '${now.toIso8601String()}\n'
          'rules: ${rules.length}\n'
          'existingTransactions: ${transactions.length}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  @override
  void dispose() {
    _balanceAnimController.dispose();
    _monthScrollController.dispose();
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
    print(
        '[DEBUG] Home build: periodo=$_period, mese=${_selectedMonth + 1}, anno=$_selectedYear, transazioni filtrate=${transactions.length} su ${filtered.length}');
    final entrate = filtered
        .where((t) => t.amount > 0)
        .fold<double>(0, (s, t) => s + t.amount);
    final uscite = filtered
        .where((t) => t.amount < 0)
        .fold<double>(0, (s, t) => s + t.amount);
    final saldo = entrate + uscite;

    Color byBalance(double value) {
      if (value > 0) return HomeScreen.kAppGreen;
      if (value < 0) return HomeScreen.kAppRed;
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
              } else if (value == 'seed') {
                ref.read(transactionsProvider.notifier).seedMockData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dati di esempio caricati!')),
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
              const PopupMenuItem(
                value: 'seed',
                child: Row(
                  children: [
                    Icon(Icons.bolt, size: 20),
                    SizedBox(width: 8),
                    Text('Seed data'),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Mese', label: Text('Mese')),
                  ButtonSegment(value: 'Anno', label: Text('Anno')),
                ],
                selected: <String>{_period},
                onSelectionChanged: (s) {
                  setState(() {
                    _period = s.first;
                    print('[DEBUG] Cambiato periodo: $_period');
                  });
                  // Aggiorna il filtro globale
                  final periodFilter = ref.read(periodFilterProvider.notifier);
                  periodFilter.state = PeriodFilter(
                    period: _period,
                    month: _selectedMonth + 1,
                    year: _selectedYear,
                  );
                  // Se si passa a 'Mese', scrolla la lista mesi sul selezionato
                  if (_period == 'Mese') {
                    final idx = _monthsList.indexWhere((d) =>
                        d.year == _selectedYear &&
                        d.month == _selectedMonth + 1);
                    if (idx >= 0) {
                      _monthScrollController.jumpTo(idx * 84.0);
                    }
                  }
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
              height: 56,
              child: _period == 'Mese'
                  ? ListView.builder(
                      controller: _monthScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemExtent: 84,
                      itemCount: _monthsList.length,
                      itemBuilder: (context, idx) {
                        final date = _monthsList[idx];
                        final isSelected = date.year == _selectedYear &&
                            date.month == _selectedMonth + 1;
                        final months = [
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
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: ChoiceChip(
                            showCheckmark: false,
                            label: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, -7),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: 84,
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 0),
                                          child: Center(
                                            child: Text(
                                              months[date.month - 1],
                                              style:
                                                  const TextStyle(fontSize: 15),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 0),
                                      Text('${date.year}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _selectedYear = date.year;
                                _selectedMonth = date.month - 1;
                                print(
                                    '[DEBUG] Selezionato: anno=$_selectedYear, mese=${_selectedMonth + 1}');
                              });
                              // Aggiorna il filtro globale
                              final periodFilter =
                                  ref.read(periodFilterProvider.notifier);
                              periodFilter.state = PeriodFilter(
                                period: _period,
                                month: _selectedMonth + 1,
                                year: _selectedYear,
                              );
                            },
                          ),
                        );
                      },
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final year = DateTime.now().year - (2 - i);
                        return FilterChip(
                          label: Text(year.toString()),
                          selected: year == _selectedYear,
                          onSelected: (_) {
                            setState(() {
                              _selectedYear = year;
                              print('[DEBUG] Cambiato anno: $_selectedYear');
                            });
                            // Aggiorna il filtro globale
                            final periodFilter =
                                ref.read(periodFilterProvider.notifier);
                            periodFilter.state = PeriodFilter(
                              period: _period,
                              month: _selectedMonth + 1,
                              year: _selectedYear,
                            );
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            // BalanceCard
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GestureDetector(
                onTapDown: (_) => _balanceAnimController.reverse(),
                onTapUp: (_) => _balanceAnimController.forward(),
                onTapCancel: () => _balanceAnimController.forward(),
                child: ScaleTransition(
                  scale: _balanceScale,
                  child: Container(
                    height: 160,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black,
                          Color(0xFF0A174E), // blu scurissimo
                        ],
                        stops: [0.0, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.18),
                          blurRadius: 32,
                          spreadRadius: 2,
                          offset: Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                          color: Colors.white.withOpacity(0.08), width: 1.2),
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
                              margin: const EdgeInsets.only(bottom: 10, top: 0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              clipBehavior: Clip.hardEdge,
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
                                    style: theme.textTheme.labelLarge?.copyWith(
                                        color: Colors.white70, fontSize: 14)),
                                Text(
                                  '€ ${currencyFormat.format(saldo)}',
                                  style:
                                      theme.textTheme.displayMedium?.copyWith(
                                          color: saldo > 0
                                              ? HomeScreen.kAppGreen
                                              : saldo < 0
                                                  ? HomeScreen.kAppRed
                                                  : Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700),
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
                                        color: Colors.white, size: 22),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Entrate',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                                color: Colors.white,
                                                fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text('€ ${currencyFormat.format(entrate)}',
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                                color: Colors.white,
                                                fontSize: 15)),
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
                                        color: Colors.white, size: 22),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Uscite',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                                color: Colors.white,
                                                fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text(
                                        '€ ${currencyFormat.format(uscite.abs())}',
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                                color: Colors.white,
                                                fontSize: 15)),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                child: _MainCategoriesPanel(
                  period: _period,
                  selectedMonth: _selectedMonth,
                  selectedYear: _selectedYear,
                ),
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
              padding: const EdgeInsets.only(left: 16, bottom: 24),
              child: SizedBox(
                width: 54,
                height: 54,
                child: AnimatedScale(
                  scale: 1.0,
                  duration: Duration(milliseconds: 120),
                  child: FloatingActionButton(
                    heroTag: "entrata",
                    backgroundColor:
                        const Color(0xCC7EE787), // verde pastello traslucido
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onPressed: () => _showNewTransactionSheet(true),
                    child: const Icon(Icons.add,
                        size: 28, color: Colors.white, weight: 800),
                  ),
                ),
              ),
            ),
          ),
          // Uscita FAB
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 24),
              child: SizedBox(
                width: 54,
                height: 54,
                child: AnimatedScale(
                  scale: 1.0,
                  duration: Duration(milliseconds: 120),
                  child: FloatingActionButton(
                    heroTag: "uscita",
                    backgroundColor:
                        const Color(0xCCFF8A80), // rosso pastello traslucido
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onPressed: () => _showNewTransactionSheet(false),
                    child: const Icon(Icons.remove,
                        size: 28, color: Colors.white, weight: 800),
                  ),
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
  final NumberFormat currencyFormat = NumberFormat('###,##0.00', 'it_IT');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(showExpenses ? Icons.trending_down : Icons.trending_up,
                color: showExpenses ? Colors.red : Colors.green),
            const SizedBox(width: 8),
            Text(showExpenses ? 'Spese principali' : 'Incassi principali',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          SizedBox(
            height: 265,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_objects,
                      size: 64, color: Colors.amber.shade400),
                  const SizedBox(height: 16),
                  Text('Nessuna transazione significativa!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.grey.shade600)),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 265,
            child: Stack(
              children: [
                ListView.separated(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: sorted.length,
                  separatorBuilder: (context, idx) => Divider(
                      height: 1, thickness: 0.5, color: Colors.grey.shade300),
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
                              currencyFormat.format(entry.value.abs()) +
                              ' €',
                          style: TextStyle(
                            color: entry.value < 0
                                ? HomeScreen.kAppRed
                                : HomeScreen.kAppGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 32,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.surface.withOpacity(0.0),
                            theme.colorScheme.surface.withOpacity(0.85),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
