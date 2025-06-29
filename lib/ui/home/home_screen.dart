import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/transactions_provider.dart';
import '../movements/new_transaction_sheet.dart';
import '../../providers/recurring_bootstrap_provider.dart';

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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
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
            SizedBox(height: 32),
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
                            // Chip giallo stile carta di credito, più in alto e più tenue
                            Container(
                              width: 38,
                              height: 32,
                              margin: const EdgeInsets.only(bottom: 20, top: 0),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade200,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.amber.shade400, width: 2),
                              ),
                              child: Align(
                                alignment: Alignment.center,
                                child: Icon(Icons.credit_card,
                                    color: Colors.amber.shade800, size: 20),
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
            const SizedBox(height: 16),
            // UploadButton
            Center(
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Import non ancora implementato')),
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload, size: 20),
                    SizedBox(width: 8),
                    Text('Carica dati da Estratto conto'),
                  ],
                ),
              ),
            ),
            const Spacer(),
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
              padding: const EdgeInsets.only(left: 16, bottom: 80),
              child: SizedBox(
                width: 72,
                height: 72,
                child: FloatingActionButton(
                  heroTag: "entrata",
                  backgroundColor: Color(0xFF40C4FF),
                  foregroundColor: Colors.white,
                  elevation: 12,
                  shape: const CircleBorder(),
                  onPressed: () => _showNewTransactionSheet(true),
                  child: const Icon(Icons.add,
                      size: 44, color: Colors.white, weight: 800),
                ),
              ),
            ),
          ),
          // Uscita FAB
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 80),
              child: SizedBox(
                width: 72,
                height: 72,
                child: FloatingActionButton(
                  heroTag: "uscita",
                  backgroundColor: Color(0xFF424242),
                  foregroundColor: Colors.white,
                  elevation: 12,
                  shape: const CircleBorder(),
                  onPressed: () => _showNewTransactionSheet(false),
                  child: const Icon(Icons.remove,
                      size: 44, color: Colors.white, weight: 800),
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
